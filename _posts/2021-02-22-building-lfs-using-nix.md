---
layout: post
title: 使用Nix构建LFS
date: 2021-02-22 21:19:37 +0800
categories: 编程
tags: Linux 包管理器
---

# 前言
前面讲了如何使用Nix创建一个Blog，作为讲如何用Nix打包的过渡。最近这段时间我在用Nix打包Linux From Scratch以及使用Nix仿照NixOS的操作系统模块来编写属于我自己的Linux发行版配置，借着这个契机，在这讲一下如何使用Nix打包。

## FHS，万恶之源
在讲打包之前，需要说明一下FHS。FHS，全称文件系统层次结构标准（Filesystem Hierarchy Standard）。它定义了系统中每个区域的用途、所需要的最小构成的文件和目录，以及例外处理与矛盾处理。该标准有两层规范，第一层规范是系统根目录下面的各个目录应该要放什么文件数据，第二层是针对/usr和/var这两个目录的子目录的定义。

在大多数Linux发行版中都是使用的FHS标准来建立系统，而像NixOS和GNU Guix System这种使用自己编写的配置文件配置的且可重现的系统使用的是链接式（Content-Addressable）来建立系统。这种包管理方式通过在文件系统上建立一个store，包管理器将系统配置以及包定义通过编译器编译和构建之后就会把构建结果存放在store里，并通过软链接的方式链接到执行命令的文件夹下面，方便测试所编写的配置以及包是否能正常打包以及运行。

## stdenv，The sandbox
Linux下面的大多数软件包基本上都是使用GNU Autotools开发和打包的，剩下的基本上是使用一些特殊的环境来开发和打包的，为了统一构建环境，Nix对这些构建环境进行整合，于是就有了标准环境（standard environment），即stdenv。

stdenv是一种类似于沙盒的构建环境，总共有3层，第一层是构建的工具链，第二层是抽象层，这一层主要是将底层的工具链进行包装，而第三层就是定义层，就是我们编写软件包定义的地方。

创建软件包一般需要如下几样东西：
1. 软件名称
2. 软件版本
3. 构建器以及需要传入构建器的参数
4. 软件源码和该软件包的Sha256值
5. 构建该软件包所需的依赖

## Derivation，构建后的软件
在编写好软件包定义之后，通过在default.nix声明软件包定义，执行nix-build命令就可以构建。如果开了flake支持的话，可以用`nix build .#...`命令来构建。构建后的软件包就是Derivation，简称drv。Derivation里面的内容一般如下：
``` json
{
  "/nix/store/8wanfzmd6vk2rqsx33rdmkilnqhm1m8i-foo.drv": {
    "outputs": {
      "out": {
        "path": "/nix/store/j95dfna6sdq7nm44im29ia7n3k3s5643-foo"
      }
    },
    "inputSrcs": [
      "/nix/store/5d1i99yd1fy4wkyx85iz5bvh78j2j96r-builder.sh"
    ],
    "inputDrvs": {
      "/nix/store/2vxpxx79j3chbqspadvh0qny5pnxbq5m-bash-4.4-p23.drv": [
        "out"
      ]
    },
    "platform": "x86_64-darwin",
    "builder": "/nix/store/rq1inyhyr4gddgc5gxdid38iwn7769d7-bash-4.4-p23/bin/bash",
    "args": [
      "/nix/store/5d1i99yd1fy4wkyx85iz5bvh78j2j96r-builder.sh"
    ],
    "env": {
      "builder": "/nix/store/rq1inyhyr4gddgc5gxdid38iwn7769d7-bash-4.4-p23/bin/bash",
      "name": "foo",
      "out": "/nix/store/j95dfna6sdq7nm44im29ia7n3k3s5643-foo",
      "system": "x86_64-darwin"
    }
  }
}
```
通过drv里面的内容，Nix会构建软件包，并放入store中。

## Linux From Scratch，自己动手，丰衣足食
Linux From Scratch，简称LFS，它是一本手册，教你从源码构建属于你自己的Linux发行版。由于有了Nix这种可重现的包管理器，通过它，可以让我们很方便的切换LFS的版本。

LFS的构建过程主要分三个大步骤：构建临时系统，构建基础系统，构建用户空间。构建临时和基础系统是属于LFS的部分，构建用户空间是属于BLFS（Beyound Linux From Scratch）的部分。

目前我用Nix来构建LFS还停留在构建临时系统阶段，毕竟构建LFS也不是一天都能完成的。

## 打包，It's magic！
终于到打包的部分了。在Nix里面打包，简而言之就是编写derivation nix文件然后构建成drv的过程。下面以GNU hello为例，说明如何使用Nix打包。

首先创建一个工作目录，然后在工作目录里面创建三个文件：builder.sh、autotools.nix、default.nix。

autotools.nix的作用是对GNU Autotools进行一层抽象，具体内容如下（macOS下面要将gcc和binutils-unwrapped换成clang和clang.bintools.bintools_bin）：
``` nix
pkgs: attrs:
  with pkgs;
  let defaultAttrs = {
    builder = "${bash}/bin/bash";
    args = [ ./builder.sh ];
    buildInputs = [ gnutar gzip gnumake gcc binutils-unwrapped coreutils gawk gnused gnugrep ];
    system = builtins.currentSystem;
  };
  in
  derivation (defaultAttrs // attrs)
```
然后是builder.sh，这个是用来执行软件包的编译操作，具体内容如下：
``` shell
set -e
unset PATH
for p in $buildInputs; do
    export PATH=$p/bin${PATH:+:}$PATH
done
tar -xf $src
for d in *; do
    if [ -d "$d" ]; then
        cd "$d"
	break
    fi
done
./configure --prefix=$out
make
make install
```
最后是default.nix，定义一个derivation。内容如下：
``` nix
let
  pkgs = import <nixpkgs> {};
  mkDerivation = import ./autotools.nix pkgs;
in mkDerivation {
  name = "hello";
  src = pkgs.fetchurl {
    url = "https://mirror.sjtu.edu.cn/gnu/hello/hello-2.10.tar.gz";
    sha256 = "0ssi1wpaf7plaswqqjwigppsg5fyh99vdlb9kzl7c9lng89ndq1i";
  };
}
```
然后使用nix-build命令构建它，当构建完成之后，就可以使用`./result/bin/hello`运行它了，之后你就可以把它放到你的Nix软件包仓库里。后续可以通过搭建ci服务器来自动构建它并建立镜像服务器，使得其他用户可以快速使用你打包的软件包。

# 结束，The end
用Nix构建一个LFS系统除了要打包软件包之外，还需要编写系统模块。这个等我构建完基础系统之后给大家讲述如何用Nix编写系统模块。下次会讲述用Nix创建自己的软件仓库，另外如果有会Nix的大佬可以加入到LFS的构建中，地址在[这里](https://github.com/c4dr01d/nix-lfs)，欢迎各位大佬加入。
