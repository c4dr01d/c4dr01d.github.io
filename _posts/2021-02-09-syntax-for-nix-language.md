---
layout: post
title: Nix语言语法
date: 2021-02-09 09:01:53 +0800
categories: 编程
tags: 包管理器
---

# 前言
在讲开发环境之前，先要讲下Nix语言。Nix语言是Nix的核心，它用来描述软件包的打包过程、环境的配置。Nix是纯函数式语言，具有惰性求值等特性。纯（Purity）代表在程序执行过程中没有任何的副作用，例如给变量赋值。因为我们的开发环境需要用Nix写开发环境的配置，所以在这里先讲一下语法。

## 语句结束符
Nix中表示一行语句结束使用分号。在集合中，分号用于分隔集合元素。

## 类型
在Nix中，有十个基本类型：字符串、整型数、浮点数、路径、URI、布尔值、Null、列表、集合、函数。其他类型可以自己扩展。

## 函数
在Nix中，定义一个函数使用这种形式：`fun_name = argument: body`。当没有制定fun_name时，该函数是一个匿名函数。例如定义一个求某个数平方的函数：
``` nix
square = x: x * x
```
当函数的参数是集合时，Nix会自动解构，例如：
``` nix
concat_a_and_b = set: set.a + set.b
concat_a_and_b { a = "hello"; b = "world"; } => "hello world"
```
需要给函数指定默认参数，可以用问号指定，例如：
``` nix
add = { a ? 1, b ? 2 }: a + b
add {} => 3
add { a = 5; } => 7
```
如果需要在函数中使用变长参数的话，有两种方式。第一种是使用`...`，第二种是使用`args @ { argument }`。例如：
``` nix
add = { a, b }: a + b
add { a = 5; b = 2; c = 10; } => unexpected argument 'c'
add = { a, b, ... }: a + b
add { a = 5; b = 2; c = 10; } => 7
add = args @ { a, b, ... }: a + b + args.c
add = { a = 5; b = 2; c = 10; } => 17
```

## 运算符
在Nix中，有20个运算符，除了常用的加减乘除以及逻辑运算符之外，有几个特殊的运算符。

`.`：选择用集合表示的属性路径
`?`：判断属性路径中是否有此属性
`++`：列表的链接
`//`：返回由两个属性所组成的集合
`->`：等价于`!e1 || e2`

## 模块
Nix支持模块，导入一个模块可以使用import语句。例如：
```
# Import module
import <nixpkgs> {};
# Import other nix source file
import ./hello.nix;
```

## with语句
with语句用于简化程序，例如：
```
# Not use with statement
{ lib, ... }: {
  options = {
    networking.hosts = lib.mkOption {
      type = lib.types.attrsOf ( lib.types.listOf lib.types.str );
      default = {};
    };
  };
  ...
}
# Use with statement
{ lib, ... }:
with lib;
{
  options = {
    networking.hosts = mkOption {
      type = with types; attrsOf ( listOf str );
      default = {};
    };
  };
  ...
}
```

## let .. in语句
let .. in语句用于定义一个局部变量然后应用于in后面的程序块，例如：
``` nix
let
  a = 1;
  b = 2;
in a + b
=> 3
```

## inherit语句
inherit语句是从其他语法作用域中复制变量，例如：
``` nix
buildPythonPackage rec {
  pname = "hello";
  version = "1.0";
  src = fetchPypi {
    inherit pname version;
    sha256 = "...";
  };
}
```

## rec语句
rec语句用于将表达式做成集合，例如：
``` nix
rec {
  x = y - 100;
  y = 123;
}.x
=> 23
```

以上是Nix的基本语法，后面会讲述如何使用Nix来创建一个开发环境。
