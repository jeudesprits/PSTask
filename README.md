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

This document will try to describe what tasks are, why they are a useful concept, and how to use and create them.

* [General](#general)
  * [Why](#why)
  * [How they work](#how-they-work) 
* [TaskQueue](#taskqueue)
* [ProducerTask](#producertask)
  * [Typealiases](#typealiases)
  * [Finishing](#finishing)
  * [Recieving](#recieving)
  * [Asigning](#asigning)
  * [Recieving queue](#recieving-queue)
  * [Producing new tasks inside task](#producing-new-tasks-inside-task)
  * [Initializing](#initializing)
  * [Dependencies](#dependencies)
* [ConsumerProducerTask](#consumerproducertask)
  * [Typealiases](#typealiases)
  * [Initializing](#initializing)
* [GroupProducerTask](#groupproducertask)
  * [Typealiases](#typealiases)
  * [Initializing](#initializing)
  * [Finishing inner tasks](#finishing-inner-tasks)
* [GroupConsumerProducerTask](#groupconsumerproducertask)
  * [Typealiases](#typealiases)
  * [Initializing](#initializing)
* [Additional tasks](#additional-tasks)
  * [Block tasks](#block-tasks)
  * [Gated task](#gated-task)
  * [Empty task](#empty-task)
* [Operator tasks](#operator-tasks)

## General
### Why

`PSTask` is an improved, fully generic version of `Operation`. `PSTask` provides great opportunities for working with `Operation`'s, dependency management, building chains, grouping them, and much more ...

But you need to remember one thing, throughout the library, instead of the concept of an **operation**, the concepts of a **task** are used. 

### How they work

Well... Seeing is believing:

```swift
enum NetworkingError: Error { case clientError(Error) ... }

let task = // Group Task contains (#1, #2, #3, #4) as chain
  BlockProducerTask<Data?, NetworkingError>( // Task #1
    qos: .userInitiated,
    priority: .veryHigh
  ) { (task, finish) in
    guard !task.isCancelled else {
      finish(.failure(.internalFailure(ProducerTaskError.executionFailure)))
      return
    }
    
    URLSession.shared.dataTask(with: URL(string: "...")!) { (data, response, error) in
      if let error = error {
        finish(.failure(.providedFailure(.clientError(error))))
        return
      }
      
      // Handle other errors...
      
      finish(.success(data))
    }.resume()
  }
  .compactMap { $0 } // Task #2
  .decode(type: [Post].self, decoder: JSONDecoder()) // Task #3
  .catch { ... } // Task #4
  .recieve(on: .main)
  .assign(to: \.posts, on: model)
  
  queue.addTask(task)
```



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

Tasks are added to the queue in the same way as for `OperationQueue`:

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

## ProducerTask

Everything is built on top of this abstract class:

``` swift
class ProducerTask<Output, Failure: Error>: Operation, ProducerTaskProtocol 
```

The main idea is that any task, no matter what work it performs, synchronous or asynchronous, should return a result. If successful, we return some value; in case of an error, we return the error itself. And this idea applies to the perfect of any task in this library. 

`ProducerTask` is abstract and you should not use it directly. This class contains most of the work you don't need to do. In order to create your first task, it is enough to inherit and override just one method:

```swift
enum MyFirstProducerTaskError: Error {

  case clientError(Error)
  case serverError(HTTPURLResponse)
  case mimeTypeError(String)
}

final class MyFirstProducerTask: ProducerTask<Data?, MyFirstProducerTaskError> {

  private var urlTask: URLSessionDataTask!
   
  override func execute() {
    let url = URL(string: "https://www.example.com/")!
    
    urlTask = URLSession.shared.dataTask(with: url) { data, response, error in
      guard !task.isCancelled else {
          finish(.failure(.internalFailure(ProducerTaskError.executionFailure)))
          return
        }
        
      URLSession.shared.dataTask(with: URL(string: "...")!) { (data, response, error) in
        if let error = error {
          finish(.failure(.providedFailure(.clientError(error))))
          return
        }
      
        let httpResponse = response as? HTTPURLResponse
        if let httpResponse = httpResponse,
           (200...299).contains(httpResponse.statusCode)
        {
          finish(.failure(.providedFailure(.serverError(httpResponse))))
          return
        }
      
        if let mimeType = httpResponse!.mimeType, mimeType == "application/json" {
          finish(.failure(.providedFailure(.mimeTypeError(mimeType))))
          return
        }
      
        finish(.success(data))
    }
    
    urlTask.resume()
  }
  
  override func cancel() {
    urlTask?.cancel()
    super.cancel()
  }
}

let t = MyFirstProducerTask()
taskQueue.addTask(t)
```

We created our first task. Inherit from `ProducerTask` and indicates that the return value will be `Date?` and possible errors, indicating a specific type that implements the `Error` protocol. 

It is important to understand that within the task, any work can be performed. No matter what it is, synchronous or asynchronous. All work must be placed in the `execute()` method. To make it clear to the task that you have completed the work, call the `finish(with:)` method. The argument of this method is `Result<Data?, ProducerTaskProtocolError <MyFirstProducerTaskError>>`. You probably ask, why not just `Result<Data?, MyFirstProducerTaskError>`? 

Because the task itself, or rather its internal implementation, may contain its own variants of errors, which are manifested in certain cases. For example, the `ProducerTask` abstract class defines its two errors, which should be, regardless of what errors the user will also transmit to this. To solve this problem, on top of all the errors is this enum:

```swift
enum ProducerTaskProtocolError<Failure: Error>: Error {

  case internalFailure(Error)
  case providedFailure(Failure)
}
```

For example, you can create your abstract task. Your task, in addition to the work that the user transferred, carries out some of its own, as a result of which an error may also occur:

```swift
enum MyTaskError: Error { case oops }

class MyTask<Output, Failure: Error>: ProducerTask<Output, Failure> {
  
  private func someInternalMethod() {
    // error...
    finish(with: .failure(.internalFailure(ErrorMyTaskError.oops)))
  }
}

enum UsersError: Error { case someFailure }

final class UsersTask: MyTask<Int, UsersError> {
  
  override func execute() {
    // error...
    finish(with: .failure(.providedFailure(.someFailure)))
  }
}
```
### Typealiases

In addition to the main `ProducerTask` class, there are three simple aliases:

```swift
typealias Task<Failure: Error> = ProducerTask<Void, Failure>

typealias NonFailTask = ProducerTask<Void, Never>

typealias NonFailProducerTask<Output> = ProducerTask<Output, Never>
```

`Task` is a normal task, with the only difference being that it returns nothing. `NonFailTask` is the same as `Task`, but it can never return an error. `NonFailProducerTask` is the same as `ProducerTask`, but with non-fail error.

Example for `Task`:

```swift
enum MyTaskError: Error { case .oops }

final class MyTask: Task<MyTaskError> {
  
  override func execute() {
    guard ... else {
      finish(with: .failure(.providedFailure(.oops)))
      return
    }
    
    // When work done...
    finish(with: .success)
  }
}
```

Example for `NonFailTask`:

```swift
final class MyNonFailTask: NonFailTask {
  
  override func execute() {
    
    // No errors, just success at the end of your work...
    finish(with: .success)
  }
}

```

Example for `NonFailProducerTask `:

```swift
final class MyNonFailProducerTask: NonFailProducerTask<Int> {
  
  override func execute() {
    
    // No errors, just success at the end of your work...
    finish(with: .success(100))
  }
}

```

### Finishing

In addition to the main `execute()` method, you can override the `finished(with:)` method, which is called, as the name implies, after the task finishes, in which the result of the task is transferred.

```swift
final class MyTask: Task<SomeError> {
  
  override func execute() {
    // ...
  }
  
  override func finished(with produced: Produced) {
    // Work is done with `produced`...
    // Do some work:
    switch produced {
    case .success:
       // ...
    case let .failure(.providedFailure(error)):
      // ...
    }
    
    // Or any other work ...
  }
}
```

### Recieving

`finished(with:)` method is more suitable for people who create their tasks for reuse and in the completion of work they want to perform some kind of internal work.

Generally speaking, for any operation for ordinary purposes, to get the result of the task you should use the following method `recieve(completion:)`:

```swift
let t1 =
  MyProducerTask<Int, SomeError>()
    .recieve(completion: { (produced) in
      switch produced {
      case let .success(value):
        // ...
      case let .failure(.providedFailure(error)):
        // ...
      }
    })

// or just

let t2 =
  MyProducerTask<Int, SomeError>()
    .recieve {
      switch $0 {
      case let .success(value):
        // ...
      case let .failure(.providedFailure(error)):
        // ...
      }
    }
```

### Asigning

`assign(to:on:)` method allows you to directly set the value for the specified key-path of the passed object, so only the task will be completed successfully:

```swift
let t =
  MyProducerTask<Int, SomeError>()
    .assign(to: \.postCount, on: model)

``` 

### Recieving queue

`recieve(on:)` method allows you to specify the `DispatchQueue` where the `recieve(completion:)` and `assign(to:on:)` methods will be executed:

```swift
let t =
  MyProducerTask<Int, SomeError>()
    .recieve(on: .main)
    .assign(to: \.postCount, on: model)
```
### Producing new tasks inside task

It may seem strange to you, but the task itself may give rise to another task with `produce(new:)` method, which will automatically be added to the same queue in which the task itself is located.

For example, you have an task that checks the location. At some point, it may happen that you do not have access to this location and you would like to start another task at that moment, inside this one, which will request permission to use the location.

```swift
final class GetLocationTask: ProducerTask<CLLocation, SomeError>, CLLocationManagerDelegate {
  
  private let accuracy: CLLocationAccuracy
  private var manager: CLLocationManager?
  
  init(accuracy: CLLocationAccuracy) {
    self.accuracy = accuracy
    super.init()
  }
  
  override func execute() {
    DispatchQueue.main.async {
      let manager = CLLocationManager()
      manager.desiredAccuracy = self.accuracy
      manager.delegate = self
      manager.startUpdatingLocation()
      self.manager = manager
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last, location.horizontalAccuracy <= accuracy else { return }
    finish(with: .success(location))
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    let getPermTask = GetPermTask(...)
    produce(new: getPermTask)
    finish(with: .failure(...))
  }
}
```

### Initializing

`ProducerTask` class provided with the following initializer:

```swift
init(
  name: String? = nil,
  qos: QualityOfService = .default,
  priority: Operation.QueuePriority = .normal
)
```

We intentionally did not use any arguments in the examples above, but you need to know that they are and their use is a sign of good manners. Moreover, you should always provide these arguments in your tasks initializers, unless there is a specific reason not to.

```swift
let t =
  MyProducerTask<Int, SomeError>(qos: .userInitiated, priority: .high)
    .recieve {
      switch $0 {
      case let .success(value):
      // ...
      case let .failure(.providedFailure(error)):
        // ...
      }
    }
```

### Dependencies

Like `Operation`, any task can have dependencies. Dependencies mean that the current task will not start its work exactly until all task on which it depends, are either completed or canceled. In order to add a task as a dependency, just use the `addDependency(_:)` method. Like that:

```swift
let t1 = ...
let t2 = ...

let t =
  MyProducerTask<Int, SomeError>(qos: .userInitiated, priority: .high)
    .addDependency(t1)
    .addDependency(t2)
    .recieve {
      switch $0 {
      case let .success(value):
      // ...
      case let .failure(error):
        // ...
      }
    }
```

Similarly, you can remove a task from your dependencies using `removeDependency(_:)` method.

## ConsumerProducerTask

Sometimes, in addition to the fact that the task produces a value, you need to get another value for the input and build your output value from this value. For these purposes, another abstract class, `ConsumerProducerTask`, is introduced, which is inherited from `ProducerTask`. 

```swift
class ConsumerProducerTask<Input, Output, Failure: Error>: 
  ProducerTask<Output, Failure>, ConsumerProducerTaskProtocol
```

Unlike `ProducerTask`, here for work it is necessary to override another `execute(with:)` method to which the result of the previous task is transmitted. The whole work of establishing a dependency, transferring the result from one task to another is undertaken by the class:

```swift
enum SomeError: Error { ... }

final class MyFirstConsumerProducerTask: ConsumerProducerTask<Data, UIImage, SomeError> {

  override func execute(with consumed: Consumed) {
    switch consumed {
    case let .success(data):
     // Convert Data to UIImage...
     finish(with: .success(image))
    case let .failure(...):
     ...
    }
  }
}
```

The only limitation is that the type of `Failure` should be the same for both tasks.

### Typealiases

In addition to this class, as well as for `ProducerTask`, there are 3 aliases:

```swift
typealias ConsumerTask<Input, Failure: Error> = ConsumerProducerTask<Input, Void, Failure>

typealias NonFailConsumerTask<Input> = ConsumerTask<Input, Never>

typealias NonFailConsumerProducerTask<Input, Output> = ConsumerProducerTask<Input, Output, Never>
```

I think their meaning is clear from the name. It is usually used to reduce the number of generic parameters.

### Initializing

There is only one initializer available that is almost identical to the corresponding `ProducerTask` initializer:

```swift
init(
  name: String? = nil,
  qos: QualityOfService = .default,
  priority: Operation.QueuePriority = .normal,
  producing: ProducingTask
)
```

## GroupProducerTask

Group tasks practically do not differ from the tasks presented above, but they have one additional property - they can perform a group of tasks within one task. This is achieved through an internal queue of tasks. This will never have any performance problems, because in most cases, tasks will be performed on the same `DispatchQueue`, on which the group task itself will be performed. (I remind you that under the hood of any `OperationQueue` is a `DispatchQueue`)


`GroupProducerTask` is a continuation of a chain of abstract classes that inherits from `ProducerTask`:

```swift
class GroupProducerTask<Output, Failure: Error>: 
  ProducerTask<Output, Failure>, TaskQueueContainable
```

### Typealiases

By analogy with the previous classes, we also have exactly three aliases:

```swift
typealias GroupTask<Failure: Error> = GroupProducerTask<Void, Failure>

typealias NonFailGroupTask = GroupTask<Never>

typealias NonFailGroupProducerTask<Output> = GroupProducerTask<Output, Never>

```

### Initializing

Unlike ordinary tasks, when inheriting from group tasks, most of the work will be written in the initializer. There are two types of initializers:

```swift
init<T1: ProducerTaskProtocol, T2: ProducerTaskProtocol, ...>(
  name: String? = nil,
  qos: QualityOfService = .default,
  priority: Operation.QueuePriority = .normal,
  underlyingQueue: DispatchQueue? = nil,
  tasks: (T1, T2, ...)
)
```

and

```swift
init<T1: ProducerTaskProtocol, T2: ProducerTaskProtocol, ...>(
  name: String? = nil,
  qos: QualityOfService = .default,
  priority: Operation.QueuePriority = .normal,
  underlyingQueue: DispatchQueue? = nil,
  tasks: (T1, T2, ...),
  produced: ProducerTask<Output, Failure>
)
```

It is important to show an example of inheritance from group tasks:

```swift
final class GetImageTask: GroupProducerTask<UIImage, SomeError> {

  init() {
    let download = DownloadTask<Data, GetImageError>(...)
    let convert = ConvertTask<Data, UIImage, GetImageError>(...)
    let downsample = DownsampleTask<UIImage, UIImage, GetImageError>(...)
    
    super.init(tasks: (download, convert, downsample))
    
    let notify = // Notify, change `Failure` type and return `UIImage`
      NotifyTask<UIImage, NotifyError>(...) 
       .addDependency(downsample)
       .recieve { [unowned self] (produced) in
         switch produced {
         case let .success(image):
           self.finish(image)
         case let .failure(.providedFailure(...))
           // ...
         }
       }
       
     addTask(notify)
  }
}
```

This example shows the use of the first type of initializer, when the task generating the final result is not provided directly and you have to do it yourself by calling the `self.finish(with:)`

This is sometimes necessary, when you need to do some work before completing an tasks, and you need access to `self`. This gives you a complete carte blanche. You complete task exactly when you consider it necessary.

On the other hand, when you do not want to do any work to complete the task, you can specify a specific task whose result will be used as the result of a group task:

```swift
final class GetImageTask: GroupProducerTask<UIImage, SomeError> {

  init() {
    let download = DownloadTask<Data, GetImageError>(...)
    let convert = ConvertTask<Data, UIImage, GetImageError>(...)
    let downsample = DownsampleTask<UIImage, UIImage, GetImageError>(...)
    
    super.init(
      tasks: (download, convert, downsample), 
      produced: downsample
    )
  }
}

```

Group tasks allow you to wrap the list of taks within one. Such tasks are extremely convenient for reuse.

### Finishing inner tasks

If you want to be notified when a task is completed within a group, you can override `taskDidFinish(_:)` method:

```swift
final class MyProducerGroupTask: GroupProducerTask<...> {

  // ...

  override func taskDidFinish<T: ProducerTaskProtocol>(_ task: T) {
    // After completing any task within the group, this method will be called.
  }
} 
```

## GroupConsumerProducerTask

Well, the last abstract class is the `GroupConsumerProducerTask`, which inherits from `ConsumerProducerTask`. All that has been said about group tasks above applies to this class. In contrast to `GroupProducerTask`, the ability to get the result from another task, which is provided by inheritance from `ConsumerProducerTask`, is added.

```swift
class GroupConsumerProducerTask<Input, Output, Failure: Error>:
  ConsumerProducerTask<Input, Output, Failure>, TaskQueueContainable
```

### Typealiases

By tradition, it has three aliases:

```swift
typealias GroupConsumerTask<Input, Failure: Error> = 
  GroupConsumerProducerTask<Input, Void, Failure>

typealias NonFailGroupConsumerTask<Input> = GroupConsumerTask<Input, Never>

typealias NonFailGroupConsumerProducerTask<Input, Output> = 
  GroupConsumerProducerTask<Input, Output, Never>
```

### Initializing

This class also has two initializers, which practically do not differ in meaning from the corresponding `GroupProducerTask` class:

```swift
init<T1: ProducerTaskProtocol, T2: ProducerTaskProtocol, ...>(
  name: String? = nil,
  qos: QualityOfService = .default,
  priority: Operation.QueuePriority = .normal,
  producing: ProducingTask,
  underlyingQueue: DispatchQueue? = nil,
  tasks: (T1, T2, ...)
)
```

and

```swift
init<T1: ProducerTaskProtocol, T2: ProducerTaskProtocol, ...>(
  name: String? = nil,
  qos: QualityOfService = .default,
  priority: Operation.QueuePriority = .normal,
  underlyingQueue: DispatchQueue? = nil,
  producing: ProducingTask,
  tasks: (T1, T2, ...),
  produced: ProducerTask<Output, Failure>
)
```

## Additional tasks

The library provides a couple of ready-made tasks, the number of which will grow over time.

### Block task

Block tasks provide an opportunity without creating subclasses to create an task with specific actions described inside the closure:

```swift
let task =
  BlockProducerTask<Int, String>(
    name: "BlockProducerTask",
    qos: .userInitiated, priority: .veryHigh
  ) { (task, finish) in
    Thread.sleep(forTimeInterval: 1.0)
    finish(.success(21))
  }
  .recieve {
    switch $0 {
    case let .success(value):
      XCTAssertEqual(value, 21)
    case .failure:
      XCTFail()
    }
    
    expec.fulfill()
  }
```

Block operations are provided for each of the classes:

```swift
typealias BlockTask<Failure: Error> = BlockProducerTask<Void, Failure>

typealias NonFailBlockTask = BlockTask<Never>

final class BlockProducerTask<Output, Failure: Error>: ProducerTask<Output, Failure>

typealias NonFailBlockProducerTask<Output>
```

and

```swift
typealias BlockConsumerTask<Input, Failure: Error> = 
  BlockConsumerProducerTask<Input, Void, Failure>

typealias NonFailBlockConsumerTask<Input> = BlockConsumerTask<Input, Never>

final class BlockConsumerProducerTask<Input, Output, Failure: Error>:  
  ConsumerProducerTask<Input, Output, Failure>

typealias NonFailBlockConsumerProducerTask<Input, Output> = 
  BlockConsumerProducerTask<Input, Output, Never>
```

### Gated task

Gated task allows you to wrap up any `Operation`:

```swift
final class MyOperation: Operation { 

  override func main() { Thread.sleep(forTimeInterval: 2) } 
}

let myop = MyOperation()

let task =
  GatedTask(
    qos: .userInitiated,
    priority: .veryHigh,
    operation: myop
  )
  .recieve {
    switch $0 {
    case .success:
      XCTAssertTrue(true)
      expec.fulfill()
    case .failure:
      XCTFail()
    }
 }

queue.addTask(task)
```

### Empty task

🤷‍♂️ 

Usually used only as an indicator. For example, an empty task can be used as a "start" task, on which other tasks will depend, which will not begin their execution exactly until the "start" task is added to the queue and executed.

```swift
let startingTask = EmptyTask()
```

## Operator tasks

`ProducerTask` can provide much more features than what was presented above. These features are *operator* functions, similar to those you might see in **RX** or recently introduced by Apple - **Combine** framework.

Better to see once:

```swift
let t =
  MyProducerTask<Data?, SomeError>(qos: .userInitiated, priority: .high)
    .replaceNil(with: ...) // Convert `Data?` to `Data`...
    .map {
       // Convert `Data` to `UIImage`...
    }
    .mapError {
      // Convert `SomeError` to `NewError`...
    }
    .flatMap {
      // Convert to New Task...
    }
    .recieve {
      switch $0 {
      case let .success(value):
      // ...
      case let .failure(error):
        // ...
      }
    }
```

Each *operator* function is another task that will be performed after completing the task above it. Each *operator* function allows you to somehow transform result in a chain, while doing this asynchronously, because, as I already wrote, they are all ordinary tasks.

The number of such functions will increase with each new version and I want to transfer almost all the operator functions that are present in **RX** and/or **Combine** framework.

*Operator* functions can not only transform the result of the previous task, they can generate new task within themselves. One such *operator* function is `flatMap`.

Since each *operator* function generates a task, just like in the usual case, we can add additional dependencies to it or, say, hang up a completion and get the result of an intermediate *operator* function:

```swift
let t1 = ...
let t2 = ...

let t =
  MyProducerTask<Data?, SomeError>(qos: .userInitiated, priority: .high)
    .replaceNil(with: ...) // Convert `Data?` to `Data`...
    .map {
       // Convert `Data` to `UIImage`...
    }
    .addDependency(t1) // `map` will start working as soon as the task before it 
                       // and the task added as a dependency is completed.
    .mapError {
      // Convert `SomeError` to `NewError`...
    }
    .addDependency(t2) 
    .recieve { // Just get the result of this intermediate `mapError` task.
       print($0)
    }
    .flatMap {
      // Convert to New Task...
    }
    .recieve {
      switch $0 {
      case let .success(value):
      // ...
      case let .failure(error):
        // ...
      }
    }

taskQueue.addTask(t1)
taskQueue.addTask(t2)
taskQueue.addTask(t)
```

# Sooner

There is much more that has not been said. Thank you for reaching the end. 😃
