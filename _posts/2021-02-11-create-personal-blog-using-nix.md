---
layout: post
title: 使用Nix创建个人博客
date: 2021-02-11 13:12:42 +0800
categories: 编程
tags: 包管理器 博客
---

# 前言
在讲打包之前，我先讲下我的博客是如何创建与部署的，做为前面讲创建开发环境的延伸。

## 环境搭建
我的博客使用Jekyll作为引擎来搭建的，Jekyll使用Ruby编写，Nix对Ruby的开发支持也很好，可以做到只要在机器上能安装Nix和Git，就能够在不污染本地全局环境下编写博客。

在搭建博客时，需要创建一个目录来存放我们的博客源码，之后我们可以调用nix-shell来创建初始环境，具体命令为：`nix-shell -p jekyll --run "jekyll new ."`。

建立了初始环境后，需要改动一下Gemfile，这里要把关于JRuby和Win32的gem全删了，另外把jekyll gem换成github-pages gem。然后用bundle生成Gemfile.lock，具体命令为：`nix-shell -p bundler --run "bundler package --no-install --path vendor"`。生成Gemfile.lock后，还需要生成gemset.nix，这里需要使用bundix工具，bundix通过生成的Gemfile.lock将gems转化成nix来使得整个环境下面的Ruby依赖完全用Nix来管理。生成gemset.nix的具体命令为：`$(nix-build '<nixpkgs>' -A bundix)/bin/bundix`。

在生成了Gemfile.lock和gemset.nix之后，需要删除.bundle、vendor和result，这些是在初始化环境的时候所构建出来的，对于整个Blog的写作环境来说无关紧要。之后就可以创建shell.nix来对写作环境做配置，使写作环境Nix化：
``` nix
with import <nixpkgs> {};
let
  jekyllEnv = bundlerEnv rec {
    name = "jekyll";
    gemfile = ./Gemfile;
    lockfile = ./Gemfile.lock;
    gemset = ./gemset.nix;
  };
in
mkShell {
  buildInputs = [ jekyllEnv ];
}
```
这里使用了bundlerEnv，在Nix中定义一个bundle环境。在对博客配置做好更改之后，可以使用命令：`nix-shell --run "jekyll serve --watch"`来启动本地预览。

在创建新文章这块，我使用了rake工具，使得创建文章半自动化，只需要输入博客文章的URL、标题、分类和标签后，就会自动生成一篇白板文章，写完后就可以发布。

我的Rakefile：
``` ruby
task :default => :new
require 'fileutils'
desc "Create new post"
task :new do
  puts "[-] Please input new post URL: "
  @url = STDIN.gets.chomp
  puts "[-] Please input post title: "
  @name = STDIN.gets.chomp
  puts "[-] Please input the categories: "
  @categories = STDIN.gets.chomp
  puts "[-] Please input the tags: "
  @tags = STDIN.gets.chomp
  @slug = "#{@url}"
  @slug = @slug.downcase.strip.gsub(' ', '-')
  @date = Time.now.strftime("%F")
  @post = "_posts/#{@date}-#{@slug}.md"
  if File.exist?(@post)
    abort("[!] Create new post failed, because the #{@post} is exists.")
  end
  FileUtils.touch(@post)
  open(@post, 'a') do |file|
    file.puts "---"
    file.puts "layout: post"
    file.puts "title: #{@name}"
    file.puts "date: #{Time.now}"
    file.puts "categories: #{@categories}"
    file.puts "tags: #{@tags}"
    file.puts "---"
  end
end
```

## 构建、部署与备份
构建上，依靠前面的shell.nix，在写好文章之后可以用`nix-shell --run "jekyll build"`来构建。

部署上面，我在我的GitHub上面开了一个仓库，总共两个分支，master分支是用来存放构建好的页面，也就是用过引擎编译好的网页，source分支用来存放源码。

备份上我选择了跟构建好的页面一起放进一个仓库，存放方式即前面提到的双分支存储。在source分支里面我用了git worktree将master分支转到Jekyll生成页面那个目录，当构建完毕之后，我可以直接进去通过git手动提交更新，后续会转成用rake来自动化这个过程，目前还是半自动部署先凑合。

## 环境维护
关于环境的维护，只需要删除Gemfile.lock和gemset.nix再按照上面的方法重新生成就可以了。
