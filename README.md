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

Tasks are added to the queue in the same way as for `NSOperationQueue`:

```swift
let t1 = ...
let t2 = ...

taskQueue.addTask(t1)
taskQueue.addTask(t2)
```

It is possible to add a task postponed:

```swift
taskQueue.addTaskAfter(t1, deadline: .now() + 3) // Will be added to queue in 3 seconds.
```

It is possible to add a **synchronous** block-task to the queue without creating a separate task:

```swift
taskQueue.addBlockTask { /* Some synchronous work... */ }
```

Moreover, you can add a **synchronous** block-task, that method executes the block when the `TaskQueue` has finished all enqueued tasks and prevents any subsequent tasks to be executed until the barrier has been completed. This acts similarly to the `dispatch_barrier_async` function.

```swift
taskQueue.addBarrierBlock { /* Some synchronous work... */ }
```
