---
layout: post
title: "Telegram Bot 开发手记：理论篇"
date: 2018-06-06 15:00:00 +0800
tag: 折腾
toc: true
---

## 1. 前言

本文记录了一次 Telegram Bot 的开发过程，包含基础的开发流程和 Telegram Bot API 的介绍，更多内容可以查询 [Telegram Bot API 官方文档](https://core.telegram.org/bots/api#authorizing-your-bot)。

为了不让读者做无用功，在这里本文先介绍一下 Bot API 的限制，主要包括：

- 为了防止骚扰，Bot 不能主动对一个用户发起会话。Bot 只有在某个用户以 `/start` 命令发起会话后才能向该用户发送消息。
- Bot 的历史消息存储有时间和空间限制，如果你需要保存他们，需要用程序保存在本地。
- 出于隐私考虑，Bot 被拉入群组后默认无法查看所有消息，这个限制可以被修改，相关信息可以查阅 [官方文档](https://core.telegram.org/bots#privacy-mode)。

## 2. 申请 Bot

根据 [官方文档](https://core.telegram.org/bots#3-how-do-i-create-a-bot) 申请创建一个 Telegram Bot 只需要在 Telegram 上联系 [BotFather](https://telegram.me/botfather) (一个 Telegram 官方提供的，用于管理 Bot 的 Bot)，然后根据提示即可创建 Bot 并设置 Bot 的头像、昵称以及一些高级功能，限于篇幅本文对此不做额外赘述。

进行 Telegram Bot 开发最核心的是获取 Bot 的 API Token，对于不熟悉利用 API 开发的朋友，可以简单地将 API Token 理解为 Bot 的密码，开发的程序必须获取 API Token 才能拥有控制 Bot 的权限。常见的 API Token 形如 `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11` , 包含以英文分号隔开的一串数字，和字母数字混合编码。

## 3. API 的使用方法

Telegram Bot API 的使用与其他网络服务的 API 类似，只需要通过对构造好的 url 进行特定的网络请求，并对请求的结果，即一组 json 格式的数据，进行处理即可。  

如果你不擅长 http 相关的编程，可以使用 [社区提供的 SDK](https://core.telegram.org/bots/samples) 来辅助开发。

### 3.1. 构造 url

根据 [官方文档](https://core.telegram.org/bots/api#making-requests) ，一个 API 方法(Method)对应的 url 应该是如下格式：

`https://api.telegram.org/bot<API_TOKEN>/<METHOD_NAME>`
`https://api.telegram.org/bot123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11/getMe`

其中 `<API_TOKEN>` 是上文中提到的，从 BotFather 申请获得的，而 `<METHOD_NAME>` 则是方法名，是 Telegram 官方事先规定好的，与 Bot 的功能一一对应。本文只会介绍一些常见的方法，更多方法和对应的功能可以在 [官方文档](https://core.telegram.org/bots/api) 中查询。

注：`<METHOD_NAME>` 是 **大小写不敏感** 的，`getMe` 方法和 `gEtmE` 方法是等价的。

### 3.2. 进行网络请求

构造好特定的 url 后，要做的就是对 url 进行特定的网络请求。

Telegram Bot API 支持两种方法，即 GET 与 POST，的网络请求，而网络请求的格式可以是：  

- URL query string (常用于 GET 方法，把参数构造进 url 中)
- pplication/x-www-form-urlencoded (常用与 POST 方法，通过提交表单的方式提交参数)
- application/json (上传一个包含参数和对应值的 json 文件)
- multipart/form-data (主要用于上传文件)

一个最简单的 Bot API 的调用可以通过如下的 bash 命令完成

**注意：由于中国大陆等国家的网络审查，下列命令可能无法直接在您的机器上正常工作。**

`curl -x GET https://api.telegram.org/bot123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11/sendMessage?chat_id=123321&text=hello`

### 3.3. 处理请求结果

进行网络请求之后，Telegram 的服务器会返回给一个 **UTF-8 编码的 json 对象** 作为请求的结果，只需要解析这个 json 对象即可获得对应的信息。

## 4. 基本要素及相关 API

### 4.1. 接收用户输入

作为一个 Bot，一个重要的功能就是获取用户的输入，尽管可以通过修改配置文件的方式来告知 Bot 接下来要做的工作，但是对于经常变化的任务或者突发性的任务来说，通过交互的方式通知 Bot 显然更加方便与友好。　

API 中提供了两种接收用户输入的方法：

- [getUpdates](https://core.telegram.org/bots/api#getupdates)
- [setWebhook](https://core.telegram.org/bots/api#setwebhook)

这两种方法都会获得一个包含用于信息相关参数及对应值的 json 对象，该对象被称为 [Update](https://core.telegram.org/bots/api#update)，可以通过点击超链接查看对象的格式。

#### 4.1.1 getUpdates 

`getUpdates` 方法是一种 [长轮询](https://en.wikipedia.org/wiki/Push_technology#Long_polling) 的信息获取方式，如果 Bot **上次标记完成后** 没有收到信息，或消息已保存超过24小时，该方法会保持等待直到超时，在等待期间收到信息将会立刻返回结果；反之，该方法会返回一组包含了24小时内所有未标记信息的 Updates。

注1：该方法的 `offset` 参数可以将一部分消息标记为已处理，参数的取值为接收到的消息的 `message_id` 最大值加一，比如参数取值为 3000 时，服务器仅会返回从 3000 开始的消息，并将小于 3000 的消息标记为已处理；如果不提交 `offset` 参数，方法会返回24小时内所有未标记信息。

注2：超时值通过 `timeout` 参数指定，默认超时值为0，即没有消息时直接返回一个空结果，此时工作方式不属于长轮询。

#### 4.1.2 `setWebhook` 

`setWebhook` 方法严格来说并不是或获取信息，而是告知服务器一个 url 地址。服务器将会在收到新消息时，通过 POST 方法将 json 格式的 Update 对象发送到指定的 url 地址。

下面列出部分使用 `setWebhook` 时的注意事项，更多请参阅 [官方文档](https://core.telegram.org/bots/webhooks)

注1：如果 Telegram 服务器连接 url 失败，将会进行合理次数的多次请求。

注2：告知服务器的 url 地址必须是一个 https url，该 url 的证书可以是正规证书机构签发的，也可以是用户自签的（需要在使用该方法时，通过文件上传的方式上传证书）。

注3：Webhook 服务只能运行在 IPv4 地址的 `443, 80, 88, 8443` 端口中（即使运行在 80 端口也必须是 https 加密的服务）

注4：推荐将 url 设计的较为复杂以避免攻击者伪装成 Telegram 服务器向你的 url 发送请求，譬如包含一段攻击者难以猜测的字符串，或者通过防火墙禁止 [Telegram 服务器 IP](https://core.telegram.org/bots/webhooks#the-short-version) 以外的请求。

### 4.2 向用户发送信息

这段内容较为简单，只需要查阅 [官方文档中以 send 开头的方法](https://core.telegram.org/bots/api) 即可了解大多数发送消息的 API 的使用方式，故本文只简单介绍一些 API 使用时需要注意的问题。

开发者开发的 Telegram Bot 的程序可以通过调用一组以 send 开头的方法，来对特定的用户、群组、频道发送信息。

这些方法根据发送的信息不同，往往有着不同参数，每一个方法都需要的参数只有 `chat_id`

该参数可以是两种类型——整数或者字符串，对于不同的目标，参数的类型和取值均有所变化：

- 用户(user)：正整数，如 `123456432`
- 群组(group)：负整数，如 `-123456432`
- 频道(channel)：可以是负整数，也可以是@开头的字符串，例如 `-100106123456` 或者 `@an_example_channel`
- 超级群组(supergroup)：与频道完全相同

## 5. 实战开发

见 [Telegram Bot 开发手记：实战篇](/2018/06/07/telegram-bot-note-2.html)。

## 参考资料

- [官方文档](https://core.telegram.org/bots/api)


- [從零開始的 Telegram Bot](https://blog.sean.taipei/2017/05/telegram-bot)


- [Telegram Bot 开发手记：实战篇](/2018/06/07/telegram-bot-note-2.html)