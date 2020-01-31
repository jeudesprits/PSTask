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

`PSTask` is an improved fully generic version of `NSOperation`. `PSTask` provides great opportunities for working with `NSOperation`'s, dependency management, building chains, grouping them, and much more ...

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
See the documentation for a complete list of methods and properties.

## ProducerTask

Everything is built on top of this abstract class:

``` swift
class ProducerTask<Output, Failure: Error>: Operation, ProducerTaskProtocol 
```

The main idea is that any task, no matter what work it performs, synchronous or asynchronous, should return a result. If successful, we return some value; in case of an error, we return the error itself. And this idea applies to the perfect of any task in this library. 

`ProducerTask` is abstract and you should not use it directly. This class contains most of the work you don't need to do. In order to create your first task, it is enough to inherit and override just one method:

```swift
enum MyFirstProducerTaskError: Error {

  case urlError(Error)
  case invalidServerResponse(URLResponse)
  case invalidServerStatusCode(Int)
}

final class MyFirstProducerTask: ProducerTask<Data?, MyFirstProducerTaskError> {
  
  override func execute() {
    let url = URL(string: "https://www.example.com/")!
    
    URLSession.shared.dataTask(with: url) { data, response, error in
      if let error = error {
        self.finish(with: .failure(.providedFailure(.urlError(error))))
        return
      }
      
      guard let httpResponse = response as? HTTPURLResponse else {
        self.finish(with: .failure(.providedFailure(.invalidServerResponse(response!))))
        return
      }
      
      guard (200...299).contains(httpResponse.statusCode) else {
        self.finish(with: .failure(.providedFailure(.invalidServerStatusCode(httpResponse.statusCode))))
        return
      }
      
      if let mimeType = httpResponse.mimeType,
         mimeType == "application/json"
      {
        self.finish(with: .success(data))
      }
    }.resume()
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
enum MyTaskError: Error {

  case oops
}

class MyTask<Output, Failure: Error>: ProducerTask<Output, Failure> {
  
  private func someInternalMethod() {
    // error...
    finish(with: .failure(.internalFailure(ErrorMyTaskError.oops)))
  }
}

enum UsersError: Error {

  case someFailure
}

final class UsersTask: MyTask<Int, UsersError> {
  
  override func execute() {
    // error...
    finish(with: .failure(.providedFailure(.someFailure)))
  }
}
```
### ProducerTask typealiases

In addition to the main `ProducerTask` class, there are two simple classes that are actually just aliases:

```swift
typealias Task<Failure: Error> = ProducerTask<Void, Failure>

typealias NonFailTask = ProducerTask<Void, Never>
```

`Task` is a normal task, with the only difference being that it returns nothing. `NonFailTask` is the same as `Task`, but it can never return an error.

Example for `Task`:

```swift
enum MyTaskError: Error {
  
  case .oops
}

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

### ProducerTask finished(with:) method

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
    case let .failure(error):
      // ...
    }
    
    // Or any other work ...
  }
}
```

### ProducerTask recieve(completion:) method

But this method is more suitable for people who create their tasks for reuse and in the completion of work they want to perform some kind of internal work.

Generally speaking, for any operation for ordinary purposes, to get the result of the task you should use the following method:

```swift
let t1 =
  MyProducerTask<Int, SomeError>()
    .recieve(completion: { (produced) in
      switch produced {
      case let .success(value):
      // ...
      case let .failure(error):
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
      case let .failure(error):
        // ...
      }
    }
```

### ProducerTask produce(new:) method

It may seem strange to you, but the task itself may give rise to another task, which will automatically be added to the same queue in which the task itself is located.

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

### ProducerTask init

`ProducerTask` abstract class is provided with the following initializer:

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
      case let .failure(error):
        // ...
      }
    }
```

