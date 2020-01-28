//
//  GroupProducerTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/5/20.
//

import Foundation
import PSLock

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
open class GroupProducerTask<Output, Failure: Error>: ProducerTask<Output, Failure> {
  
  private let innerQueue: TaskQueue
  
  // MARK: -
  
  private let lock = PSUnfairLock()
  
  // MARK: -

  private let startingTask = ProducerTask<Void, Never>()
  private let finishingTask = ProducerTask<Void, Never>()
  
  // MARK: -
  
  open override func execute() {
    innerQueue.isSuspended = false
    innerQueue.addTask(finishingTask)
  }

  open override func cancel() {
    innerQueue.cancelAllTasks()
    super.cancel()
  }
  
  // MARK: -
  
  open func taskDidFinish<T: ProducerTaskProtocol>(_ task: T) {}
  
  // MARK: -
  
  open func addTask<T: ProducerTaskProtocol>(_ task: T) { innerQueue.addTask(task) }
  
  open func addTasks<T: ProducerTaskProtocol>(_ tasks: [T]) { tasks.forEach { addTask($0) } }
  
  // MARK: -
  
  public init<T: ProducerTaskProtocol>(
    name: String? = nil,
    qos: QualityOfService = .default,
    priority: Operation.QueuePriority = .normal,
    underlyingQueue: DispatchQueue? = nil,
    tasks: [T]
  ) {
    innerQueue = .init(
      name: "com.PSTask.\(String(describing: Self.self))-inner",
      underlyingQueue: underlyingQueue,
      startSuspended: true
    )
    super.init(name: name, qos: qos, priority: priority)
    innerQueue.delegate = self
    innerQueue.addTask(startingTask)
    tasks.forEach { innerQueue.addTask($0) }
  }
  
  public init<T: ProducerTaskProtocol>(
    name: String? = nil,
    qos: QualityOfService = .default,
    priority: Operation.QueuePriority = .normal,
    underlyingQueue: DispatchQueue? = nil,
    tasks: [T],
    produced: ProducerTask<Output, Failure>
  ) {
    precondition(tasks.contains { $0 === produced })
    innerQueue = .init(
      name: "com.PSTask.\(String(describing: Self.self))-inner",
      qos: qos,
      underlyingQueue: underlyingQueue,
      startSuspended: true
    )
    super.init(name: name, qos: qos, priority: priority)
    produced.recieve { [unowned self] (produced) in self.finish(with: produced) }
    innerQueue.delegate = self
    innerQueue.addTask(startingTask)
    tasks.forEach { innerQueue.addTask($0) }
  }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension GroupProducerTask: TaskQueueDelegate {
  
  public func taskQueue<T: ProducerTaskProtocol>(_ taskQueue: TaskQueue, willAdd task: T) {
    precondition(
      !finishingTask.isFinished && !finishingTask.isExecuting,
      "Сannot add new tasks to a group after the group has completed."
    )
    
    // Some task in this group has produced a new task to execute.
    // We want to allow that task to execute before the group completes,
    // so we'll make the finishing task dependent on this newly-produced task.
    if task !== finishingTask { finishingTask.addDependency(task) }
    
    // All tasks should be dependent on the `startingTask`.
    // This way, we can guarantee that the conditions for other tasks
    // will not evaluate until just before the task is about to run.
    // Otherwise, the conditions could be evaluated at any time, even
    // before the internal operation queue is unsuspended.
    if task !== startingTask { task.addDependency(startingTask) }
  }
  
  public func taskQueue<T: ProducerTaskProtocol>(_ taskQueue: TaskQueue, didFinish task: T) {
    lock.sync {
      if task === finishingTask {
        innerQueue.isSuspended = true
      } else if task !== startingTask {
        taskDidFinish(task)
      }
    }
  }
}
