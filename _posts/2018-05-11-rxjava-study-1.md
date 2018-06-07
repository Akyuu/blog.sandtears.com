---
layout: post
title: "RxJava2.0 学习笔记（一）"
date: 2018-05-11 00:01:36 +0800
tag: 学习
toc: true
---

本文是对于 [这个链接](http://www.jianshu.com/u/c50b715ccaeb) 的学习笔记，如果需要上下文可以去那里找。

## 一、事件

`OnNext(Object)` 发送一个事件，`OnComplete()` 之后不再接受，但仍然发送，`OnError(Throwable)` 也是一样。

`subscribe(Observer)` 中 `Observer` 的 `OnSubscribe（Disposable d)` 传入一个 `Disposable` 参数，可以用来停止接受事件，调用 `disposable.dispose()` 即可;

同时，其他重载 `subscript(Consumer)` 的返回值是一个 `Disposable` 对象。

## 二、调度

`Observable` 和 `Observer` 默认在创建线程中执行自己的操作

可以利用 `subscribeOn(Scheduler)` 来修改上游的执行线程，但只能修改一次，只有第一次有效。

可以通过 `observeOn(Scheduler)` 来修改下游的执行线程，可以修改多次，每次修改，当前修改只对之后的下游有效。

## 三、map 操作符

`map(Function<ObjectA, ObjectB>)` 可以把 `Observable<ObjectA>` 转换成 `Observable<ObjectB>`。

`flatMap(Function<ObjectA, ObservableSource<ObjectB>)` ，`Funtion` 类中的 `apply` 函数负责将 `ObjectA` 拆分（需要自己定义），返回多个 `Observable<ObjectB>`，然后 `flatMap` 会将他们组合起来；注意，`flatMap` 的组合是无序的。

`concatMap` 与 `flatMap` 类似，但是会严格按照顺序来组合。

## 四、zip 操作符

`zip(Observable<ObjectA>, 
Observable<ObjectB>, 
new BiFunction<ObjectA, ObjectB, ObjectC>)`

`Funtion` 类中的 `apply` 函数会把 `ObjectA` 和 `ObjectA` 组合成 `ObjectC`

此处应该有一个例子

>不对呀! 可能细心点的朋友又看出端倪了, 第一根水管明明发送了四个数据+一个Complete, 之前明明还有的, 为啥到这里没了呢?

>这是因为我们之前说了, zip发送的事件数量跟上游中发送事件最少的那一根水管的事件数量是有关的, 在这个例子里我们第二根水管只发送了三个事件然后就发送了Complete, 这个时候尽管第一根水管还有事件4 和事件Complete 没有发送, 但是它们发不发送还有什么意义呢? 所以本着节约是美德的思想, 就干脆打断它的狗腿, 不让它发了.


## 五、流量控制

>为什么不加线程和加上线程区别这么大呢, 这就涉及了同步和异步的知识了.

>当上下游工作在同一个线程中时, 这时候是一个同步的订阅关系, 也就是说上游每发送一个事件必须等到下游接收处理完了以后才能接着发送下一个事件.

>当上下游工作在不同的线程中时, 这时候是一个异步的订阅关系, 这个时候上游发送数据不需要等待下游接收, 为什么呢, 因为两个线程并不能直接进行通信, 因此上游发送的事件并不能直接到下游里去, 这个时候就需要一个田螺姑娘来帮助它们俩, 这个田螺姑娘就是我们刚才说的水缸 ! 上游把事件发送到水缸里去, 下游从水缸里取出事件来处理, 因此, 当上游发事件的速度太快, 下游取事件的速度太慢, 水缸就会迅速装满, 然后溢出来, 最后就OOM了.

解决方案是用 `Flowable` 代替 `Observable` ，用法类似，但是需要传入第二个参数 `BackpressureStrategy`

策略                      |效果
--------------------------|----
BackpressureStrategy.ERROR|超出时触发 `MissingBackpressureException` 异常
BackpressureStrategy.BUFFER|取消容量限制，超出时占用更多内存
BackpressureStrategy.DROP|超出后的事件被丢弃，直到内部事件被使用为止
BackpressureStrategy.LATEST|超出后丢弃最老的事件，保证所有事件最新

上游使用 `Flowable` 时，下游对应的应该使用 `Subscriber`，与 `Observer` 不同的是，`Subscriber` 的 `onSubscribe(Subscription s)` 函数接受 `Subscription` 的参数，可以通过 `s.request(100)` 来指定自己的接受能力，多次调用 `s.request(int)` 会使接受能力叠加。

同时，上游的 `Flowable.create(new FlowableOnSubscribe<Object>)` 中的 `FlowableOnSubscribe` 的唯一函数将会变成 `subscribe(FlowableEmitter<String> emitter)`。可以通过 `emitter.requested()` 获得下游的接受能力，大于0说明还有处理能力，等于0说明无法处理，此时仍然发送事件，会触发 `BackpressureStrategy` 定义的策略。

**注：上游的 `emitter.requested()` 的返回值并不一定等于下游调用 `s.request()` 的总值，默认的缓存为 128，即使下游请求 1000 个事件，获得的也会是 128。**

**但是当下游消耗了固定数量的事件，通常是 96 个时，上游的 `emitter.requested()` 会被重新填补 96 个，当然这个过程并不是阻塞的，可能会在上游发送到第 120 个事件时才正式进行填补，从 (128-120)=8 填补到 (8+96)=104，甚至是从 0 填补到 96。另外当触发策略 `BackpressureStrategy.BUFFER` 时，会在保持 `emitter.requested() = 0` 的情况下继续发送事件，直到下游再次请求了足够的事件后再发送。**
