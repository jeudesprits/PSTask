<img src="https://i.imgur.com/STd8Yq7.png" alt="PSLock"/>

<p align="center">
    <a href="https://swift.org">
        <img src="https://img.shields.io/badge/swift-5.1-brightgreen.svg" alt="Swift 5.1">
    </a>
    <a href="https://twitter.com/jeudesprits">
        <img src="https://img.shields.io/badge/twitter-jeudesprits-5AA9E7.svg" alt="Twitter">
    </a>
    <a href="https://t.me/jeudesprits">
        <img src="https://img.shields.io/badge/telegram-jeudesprits-5AA9E7.svg" alt="Telegram">
    </a>
</p>

<br>

# PSTask

`PSTask` is an improved version of `NSOperation`. `PSTask` provides great opportunities for working with `NSOperation`'s, dependency management, building chains, grouping them, and much more ...

First you need to remember one thing, throughout the library, instead of the concept of an operation, the concepts of a task are used. 

Next, I will try to explain the basic work with the library.

## TaskQueue

`TaskQueue` is a queue to which all tasks are added. A queue can be created with the following initializer:

```swift
 init(
    name: String? = nil,
    qos: QualityOfService = .default,
    maxConcurrentTasks: Int = OperationQueue.defaultMaxConcurrentOperationCount,
    underlyingQueue: DispatchQueue? = nil,
    startSuspended: Bool = false
 )
```


In the code, it might look something like this:

```swift
    let taskQueue =
      TaskQueue(
        name: "com.example.network-background",
        qos: .background,
      )
```
