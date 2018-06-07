---
layout: post
title: "你好，博客"
date: 2018-05-11 01:22:36 +0800
tag: 折腾
toc: true
---

## 0x0 博客的重建

最近整理印象笔记，发现又积累了一些文章。考虑到闭门造车终究不好，决心把尘封了好几年的水货博客重新给运行起来。

检查了一番曾经留下的 `mysql.tgz` 发现其中大多是复制粘贴或者各种文档的中文翻译，也就懒得把它们重新整理出来建档了。

新的博客准备针对文章内容做一些调整，主要目标是争取让文章内容重复性比较低，或者（自认为）比起网上的同类内容更加亲民；另外就是分享一些自己学习中的思考，也就是作为单纯的笔记，记录一些提纲挈领性质的东西。

目前准备调整为如下几个模块：

- 折腾
- 生活
- 学习

不知道这次重建博客能够坚持多久，但是希望能尽可能长久的更新下去。一方面书写的过程也是思考的过程，而留在数字空间的文字或许会比我的记忆延续的更长久；另一方面，这也是对自己能够维持一个规律生活的锻炼，改正一下本科以来懒散的习气。

## 0x1 博客部署所使用的软件及服务

- 博客由 [Jekyll](https://jekyllrb.com/) 生成的静态页面组成。
- 使用的的样式表和布局大量参考 [Jekyll 的默认主题 Minima](https://github.com/jekyll/minima) ，在该主题的基础上进行了少许调整。
- 使用 [Dropbox](https://www.dropbox.com/install-linux) 同步网站代码、网站相关配置文件并进行网站自动化部署。
- 使用 [Let's Encrypt](https://letsencrypt.org/) 签发的免费 SSL 证书。
- 使用 [CloudFlare](https://www.cloudflare.com/) 提供的免费 CDN 服务。

## 0x2 博客进行的调整及原因

- 停用 [Github](https://github.com/) 进行代码托管，直接从本地提交到网站服务器从而使用 [Git Hooks](https://githooks.com/) 进行自动化部署。
- 停用 [Git Hooks](https://githooks.com/) 来自动化网站的部署，改为使用 [Dropbox](https://www.dropbox.com/)。

### 0x3 博客的未来调整计划

- 利用 [oneindex](https://github.com/donwa/oneindex) 存储本站流量消耗较大的静态资源。
- 申请博客所在域名进入 [HSTS Preload List](https://hstspreload.org/) => 已收录，等待同步。