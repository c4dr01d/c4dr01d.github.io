---
layout: post
title: 函数式包管理器：Nix
date: 2021-02-08 12:50:09 +0800
categories: 编程
tags: 包管理器
---

# 前言
平时在写代码的时候，可能需要配置一系列的开发环境，有时还会遇到诸如开发环境所使用的软件版本与生产环境所使用的软件版本不同的情况，以至于还要将生产环境的软件版本倒回到开发环境所使用的软件版本，甚至可能还会出现安全问题。针对这个问题，有人专门发布了一篇论文，阐述了一种新的开发环境与软件包的管理方式，既能解决在同一个系统上的软件版本问题，也能兼顾安全问题。这就是Nix，一个使用函数式编程范式来描述软件包的打包、管理，甚至开发环境配置，容器配置，操作系统配置的软件包管理器。关于Nix能做些什么，它的[官网](https://nixos.org)有具体的描述。那么话不多说，来看如何安装（入坑）Nix吧。

## 安装
在Linux下面，你可以使用官网的[脚本](https://nixos.org/nix/install)来安装Nix到你的Linux发行版上面。如果你想使用Nix来管理你的系统的话，你可以在[这里](https://nixos.org/download.html)下载NixOS的镜像，然后安装到你的电脑里面。在macOS下面安装Nix跟Linux是一样的，只不过需要一些配置，在Nix的[文档](https://nixos.org/manual/nix/stable/#ch-installing-binary)中较为详细的介绍了安装步骤，这里讲一下在文档中没有说到的地方，这里假设都是使用多用户安装模式安装Nix。

第一个是macOS下面的/nix挂载点问题，Nix将所有的包，还有环境配置都存放在/nix这里，而由于macOS的安全策略，使得用户不能在/下面做改动，于是需要手动创建挂载点。在macOS中，管理挂在点需要在`/etc/synthetic.conf`添加挂载项，然后创建一个子卷，修改`/etc/fstab`使得/nix开机自动挂载，之后应用设置。具体操作过程如下：
``` shell
sudo vim /etc/synthetic.conf # 添加`nix`到该文件中
diskutil list # 查看卷标
/System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -B # macOS Catalina以及老版本macOS运行此命令应用配置
/System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t # macOS Big Sur以及新版本macOS运行此命令应用配置
sudo diskutil apfs addVolume diskX APFS 'NixStore' -mountpoint /nix # 创建挂载点，diskX为从`diskutil list`命令中看到的卷标
sudo vifs # 添加`LABEL=NixStore /nix apfs rw,nobrowse`，使得/nix开机自动挂载
./install-nix.sh --darwin-use-unencryped-nix-store-volume --daemon # 执行安装
```

第二个是镜像源的配置，修改镜像源需要修改`/etc/nix/nix.conf`文件，如果是用的NixOS或者nix-darwin，可以修改系统配置中的`nix.binaryCaches`来更改：
1. 使用`/etc/nix/nix.conf`修改：
``` shell
substituters = MIRROR1 MIRROR2 MIRROR3
```
修改完之后，需要重启nix-daemon使得改动生效

2. 在系统配置里修改：
``` nix
{ config, lib, pkgs, ... }: {
  ...
  nix.binaryCaches = lib.mkForce [
    "MIRROR1"
    "MIRROR2"
    "MIRROR3"
  ];
  ...
}
```
修改完系统配置后，需要用`nixos-rebuild switch`或者`darwin-rebuild switch`使得改动生效

第三个是nix-daemon，Linux的nix-daemon使用systemd管理，重启只需要`systemctl restart nix-daemon`就可以了。macOS的nix-daemon使用launchctl管理，需要先卸载nix-daemon的配置项，然后再加载，配置项位于`/Library/LaunchDaemons/org.nixos.nix-daemon.plist`，都需要在root权限下执行。

安装完毕之后，退出终端再重新打开一个终端，可以使用`nix-shell -p nix-info --run "nix-info -m"`命令查看系统基本信息，同时也可以检查Nix的运行有没有问题。

到这基本上就完成了Nix的安装，关于Nix的使用，后续会专门发文章来讲述，诸如开发环境配置，系统配置等等。敬请期待。
