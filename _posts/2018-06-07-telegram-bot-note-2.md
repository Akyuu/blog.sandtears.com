---
layout: post
title: "Telegram Bot 开发手记：实战篇"
date: 2018-06-07 15:00:00 +0800
tag: 折腾
toc: true
---

## 1. 前言

上文 [Telegram Bot 开发手记：理论篇](/2018/06/06/telegram-bot-note-1.html) 简单介绍了 Telegram Bot 开发的基本思路和相关 API。

本文主要内容包括两大部分：

- 根据上文提到的相关知识，提出几个 Telegram Bot 项目的架构思路，并对思路进行简单的介绍。
- 记录博主实际开发一个 Telegram Bot 过程中的思考和实现。

## 2. 架构

### 2.1 单线程模型

单线程模型可以说是最简单的模型了，优点在于开发简单，缺点也很明显——在Bot处理大量信息，进行IO请求等时会陷入「假死」状态，无法有效利用计算机资源。因此，单线程模型的适用场景主要是输入频率低、对用户的输入进行的数据处理耗时较短等情景。

单线程模型的思路也很简单，无限重复「长轮询获取输入=>处理数据=>输出信息」三个过程即可，用伪代码可以表示为：

```python
loop {
    # 获取用户输入
    getUpdates();  

    # 在当前线程处理输入信息
    # 这一步骤执行期间，程序不会再读取用户输入
    processMessage();  

    # 将处理结果输出给用户
    sendMessage();  
}
```

这里提供一个单线程模型的，通过 bash 编写的 telegram bot 程序，功能很简单，只有读取用户输入并且输出相同内容的功能，俗称复读机。

可以在 [这里](/assets/misc/telegram_bot.sh) 下载到该程序。

```bash
#!/bin/bash

# 之前在 BotFather 处申请得到的 API_TOKEN
token="123456:AAGTHISISANEXAMPLEAPITOKEN"

# 一次轮询的最大时间
timeout=60

offset=0

# 输入、处理、输出，三个模块循环执行
while true
do
    # 获取用户输入
    result=`curl -s "https://api.telegram.org/bot${token}/getUpdates?offset=${offset}&timeout=${timeout}"`

    # 获取消息中 update_id 的最大值，然后增大 1 作为 offset 的值
    offset=$[`echo $result | grep -o \"update_id\":\[0-9\]\* | grep -o "[0-9]\+" | tail -1`+1]

    # 消息的数量
    size=`echo $result | grep -o \"update_id\":\[0-9\]\* |  wc -l`

    for ((i=1; i<=$size; i++))
    do
        # 获取第 $i 条消息的发送人
        from=`echo $result | grep -o \"from\"\:\{\"id\":\[0-9\]\* | grep -o "[0-9]\+" | sed -n "${i}p"`

        # 获取第 $i 条消息的内容
        msg=`echo $result | grep -o text\":\".\*\"\} | sed -n "${i}p" | cut -b 8- | cut -d \" -f 1`

        # 将之前获得的消息，发给发送者
        curl -H "Content-Type: application/json" --data "{\"chat_id\":$from,\"text\":\"$msg\"}" "https://api.telegram.org/bot${token}/sendMessage"
    done
done
```

注1：代码可以在大多数安装了 curl 的 Linux 发行版中正常运行。

注2：由于 Linux 下的 GNU grep 的用法与 macOS 下的 grep 用法存在差异，代码在 macOS 平台可能需要对 grep 命令稍作修改方能正常运行。

注3：如前文所说，由于 Telegram Bot API 服务器在中国大陆遭到网络封锁，代码可能无法在大陆网络环境下正常运行。

### 2.2 单线程轮询、多线程处理信息

该模型的思路仍然是创建一个主线程轮询获取用户信息，但是在获取后并不在主线程对用户信息进行处理，而是在一个新的子线程来处理用户输入并向用户输出处理结果。其中子线程可以是不断创建的，也可以线程池的模式。

该模型的优势在于比起单线程模型可以更加有效地利用系统资源，在某个子线程进行耗时的 IO 操作的同时，其他子线程可以利用 CPU 等资源。

该模型用伪代码可以表示如下。

```python
# 主线程

loop {
    # 获取用户输入
    getUpdate();

    # 将消息分发到子线程或线程池
    # 异步方法，将立刻完成，不会阻塞 IO
    # 子线程将完成处理及输出给用户的工作
    deliverToSubthread();
}
```

```python
# 子线程

# 处理用户输入的数据
# 可以耗时较长，IO阻塞时不会影响其他线程工作
processMessage();

# 将处理结果输出给用户
sendMessage();
```

### 2.3 Webhook

Webhook 方式也是一种多线程的模型，基本思路是运行一个 Web 服务器，然后通过 `setWebhook` 方法将服务器的 url 指定为 bot 的处理地址。  

这样在 Bot 收到消息时， Telegram API 服务器将会对指定的处理地址发送一个包含消息信息的 POST 请求，然后由 Web 服务器创建一个新的线程或进程运行开发者编写的程序，处理输入的内容并输出。  

在某种程度上，Webhook的方式和上一个模型类似，但是多线程处理的部分交由 Web 服务器或者 Web 框架进行处理，简化了开发难度。

同时，根据该模型开发的程序，通常可以方便地部署在虚拟主机 (Web Hosting) 而非 VPS 上。

注：事实上，前两种模型开发的程序也可以运行在许多虚拟主机或 SaaS 平台上，只需用利用 Cron 定时运行即可。但是由于虚拟主机的 CPU 占用时间限制，很难做到不间断运行，因此往往不会采用这两种模式。

对于 Webhook 方式来说，开发思路与多线程模型中子线程的工作类似，只需要简单的进行一次「获取输入=>处理数据=>输出信息」的步骤即可，伪代码可以表示为：

```python
# 从 POST 请求中获取数据
getMessageFromPostRequest();

# 处理用户输入的数据
# 可以耗时较长，IO阻塞时不会影响其他线程工作
processMessage();

# 将处理结果输出给用户
sendMessage();
```

可以看到，整个流程与之前的多线程模型中子线程的操作流程如出一辙，这是因为 Web 服务器完成了分发消息给子线程的工作，开发者只需要简单的编写一个单线程的程序即可。

## 3. 一次开发记录

未完待续。