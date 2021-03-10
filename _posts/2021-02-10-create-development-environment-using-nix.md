---
layout: post
title: 使用Nix创建开发环境
date: 2021-02-10 12:34:29 +0800
categories: 编程
tags: 包管理器
---

# 前言
前面讲了Nix语言的语法之后，现在来看一下如何创建一个开发环境

## nix-shell
用Nix创建一个开发环境，就需要用到nix-shell这个工具。nix-shell会通过传入的软件包或者开发环境配置来创建一个开发环境，如果指定`--pure`参数，那么nix-shell会创建一个容器环境，你在这个容器环境下面的改动不会影响到真实环境。

## Ad-hoc环境
ad-hoc环境主要是用来包装一些脚本，例如：
``` python
#!/usr/bin/env nix-shell
#!nix-shell --pure -i python -p "python38.withPackages (ps: [ ps.django ])"
import django
print(django)
```
ad-hoc环境的好处是可以快速创建一个shell环境来做一些小测试，用完之后不污染真实环境。

## 可重现的环境
创建一个可重现的环境，需要在你的工程目录下面创建一个名为shell.nix的Nix脚本。默认在执行nix-shell时会优先检测shell.nix，如果没有就会检测default.nix。

例如要创建一个C/C++的开发环境，需要在shell.nix里面加入如下内容：
``` nix
with import <nixpkgs> {};
mkShell {
  buildInputs = [
    binutils
    gcc
    gnumake
    gdb
  ];
}
```
然后在这个文件夹下面执行nix-shell，Nix会自动下载依赖，然后看到提示符为`[nix-shell:WORKDIR]$ `时，你已经进入了开发环境中了。退出开发环境，只需要`exit`即可。

如果需要环境可重现，那么需要对shell.nix进行一些改动：
``` nix
{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/COMMIT_HASH.tar.gz") {} }:
with pkgs;
...
```
指定COMMIT_HASH之后，在执行nix-shell时，Nix会从GitHub下载对应版本的nixpkgs，下载完之后，会用这里面的包定义根据shell.nix里面的组件来创建开发环境。

一般nix-shell创建完开发环境后，默认行为就是进入开发环境的shell，如果在下载完开发环境的组件之后需要对开发环境进行后续配置，可以指定shellHook变量。该变量是一个类型为lines的变量，可以在该变量中存储多行内容。我们可以在这个变量里面写入命令，在下载完开发环境组件之后，Nix会执行该变量里面所写的命令，来对开发环境做后续配置。例如：
``` nix
{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/COMMIT_HASH.tar.gz") {} }:
with pkgs;
mkShell {
  buildInputs = [ ... ];
  shellHook = ''
    echo hello
  '';
}
```
如果需要在环境中指定环境变量，只需要在shell.nix的mkShell里面对环境变量赋值即可。例如：
``` nix
with import <nixpkgs> {};
mkShell {
  buildInputs = [ ... ];
  FOO = "foo";
  BAR = "bar";
}
```
在创建环境的时候，Nix会自动创建环境变量并对其赋值。

在创建工程时，一般在工程的根目录下面存放两个文件，一个就是shell.nix，另一个是default.nix。default.nix一般用来将工程打包成应用，而shell.nix是开发环境的配置。在使用nix-build执行default.nix之后，会在工程目录下面生成一个result链接，链接里面存放的是已经打包好的应用。

可能有的人说，如果要创建一个可重现的开发环境，我还得到GitHub去翻commit hash。为了解决这个问题，Nix提供了niv这个工具。下面通过一个工程实例，来讲述niv工具的使用。

## 工程实例
创建一个工程目录，然后在该目录下面执行`niv init`。执行完之后，工程的目录结构如下：
```
.
└── nix
    ├── sources.json
    └── sources.nix
```
sources.json和sources.nix是niv添加了诸如nixpkgs软件源后所生成的，我们可以通过这个来创建开发环境和生产环境。

在初始化完工程根文件夹之后，就可以创建shell.nix和default.nix了，这里先给出shell.nix的内容：
``` nix
{ sources ? import ./nix/sources.nix }:
let
  pkgs = import sources.nixpkgs { };
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    binutils
    gcc
    gnumake
    gdb
  ];
}
```
配置完之后使用nix-shell创建开发环境。

在开发环境中完成对工程的编写后，就需要开始对工程进行构建了。在编写default.nix之前，先要编写一个builder。在本例中使用的是shell脚本来编写builder，builder中的内容如下：
``` shell
set -e
unset PATH
for p in $buildInputs; do
    export PATH=$p/bin${PATH:+:}$PATH
done
gcc -o $out/$name $src
```

在default.nix中添加如下内容：
``` nix
{ sources ? import ./nix/sources.nix }:
let
  pkgs = import sources.nixpkgs { };
in
pkgs.stdenv.mkDerivation {
  name = "hello";
  builder = "${pkgs.bash}/bin/bash";
  args = [ ./builder.sh ];
  buildInputs = with pkgs; [ binutils gcc ];
  src = ./hello.c;
  system = builtins.currentSystem;
}
```
之后运行nix-build命令构建，构建完毕之后会在工程根目录下面生成一个result的链接，里面就是构建好的可执行程序，使用`./result/hello`就可以执行。

基本上所有的开发环境都是用这种工作流来创建的，另外还有一个工作流是使用的nix flakes，这个后面再讲述。后面会通过一个实际的项目来跟大家讲述如何用Nix打包，毕竟Nix本身就是一个包管理器嘛，如何用Nix打包和定制一个包才是至关重要的。
