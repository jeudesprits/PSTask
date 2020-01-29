//
//  TaskQueue.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/3/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public protocol TaskQueueDelegate: AnyObject {
  
  func taskQueue<T: ProducerTaskProtocol>(_ taskQueue: TaskQueue, willAdd task: T)
  
  func taskQueue<T: ProducerTaskProtocol>(_ taskQueue: TaskQueue, didFinish task: T)
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension TaskQueueDelegate {
  
  public func taskQueue<T: ProducerTaskProtocol>(_ taskQueue: TaskQueue, willAdd task: T) {}
  
  public func taskQueue<T: ProducerTaskProtocol>(_ taskQueue: TaskQueue, didFinish task: T) {}
}

internal struct _TaskQueueDelegateObserver {
  
  private unowned let taskQueue: TaskQueue
  
  // MARK: -
  
  internal init(taskQueue: TaskQueue) { self.taskQueue = taskQueue }
}

extension _TaskQueueDelegateObserver: Observer {
  
  internal func task<T1: ProducerTaskProtocol, T2: ProducerTaskProtocol>(_ task: T1, didProduce newTask: T2) {
    taskQueue.addTask(newTask)
  }
  
  internal func taskDidFinish<T: ProducerTaskProtocol>(_ task: T) {
    taskQueue.delegate?.taskQueue(taskQueue, didFinish: task)
  }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
open class TaskQueue: OperationQueue {
  
  open weak var delegate: TaskQueueDelegate?
  
  // MARK: -
  
  @available(*, unavailable)
  open override var maxConcurrentOperationCount: Int { didSet {} }
  
  open var maxConcurrentTaskCount: Int {
    get { super.maxConcurrentOperationCount }
    set { super.maxConcurrentOperationCount = newValue }
  }
  
  // MARK: -
  
  @available(*, unavailable)
  open override func addOperation(_ operation: Operation) {}
  
  @available(*, unavailable)
  open override func addOperations(_ operations: [Operation], waitUntilFinished wait: Bool) {}
  
  @available(*, unavailable)
  open override func addOperation(_ block: @escaping () -> Void) {}
  
  @available(*, unavailable)
  open override func addBarrierBlock(_ barrier: @escaping () -> Void) {}
  
  open func addTask<T: ProducerTaskProtocol>(_ task: T) {
    // Set up a observer to invoke the `OperationQueueDelegate` methods.
    task.addObserver(_TaskQueueDelegateObserver(taskQueue: self))
    
    // Extract any dependencies needed by this operation.
    task
      .conditions
      .lazy
      .compactMap { $0.dependency(for: task) }
      .forEach {
        task.addDependency($0)
        super.addOperation($0)
      }
    
    // Indicate to the operation that we've finished our extra work on it
    // and it's now it a state where it can proceed with evaluating conditions, if appropriate.
    task.willEnqueue()
    
    delegate?.taskQueue(self, willAdd: task)
    
    super.addOperation(task)
  }
    
  open func addTask<T: ConsumerProducerTaskProtocol>(_ task: T) {
    func _addTask<T: ProducerTaskProtocol>(_ task: T) { addTask(task) }
    
    _addTask(task.producing)
    _addTask(task)
  }
  
  open func addTaskAfter<T: ProducerTaskProtocol>(_ task: T, deadline: DispatchTime) {
    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: deadline) { self.addTask(task) }
  }

  open func addBlockTask(_ block: @escaping () -> Void) { super.addOperation(block) }
  
  open func addBarrierBlockTask(_ block: @escaping () -> Void) { super.addBarrierBlock(block) }
  
  // MARK: -
  
  @available(*, unavailable)
  public final override func waitUntilAllOperationsAreFinished() {}
  
  public final func waitUntilAllTasksAreFinished() {
    #if !DEBUG
    fatalError(
      "Waiting on tasks is an anti-pattern. Remove this ONLY if you're absolutely sure there is No Other Way™."
    )
    #else
    super.waitUntilAllOperationsAreFinished()
    #endif
  }
  
  // MARK: -
  
  @available(*, unavailable)
  open override func cancelAllOperations() {}
  
  open func cancelAllTasks() { super.cancelAllOperations() }
  
  // MARK: -
  
  @available(*, unavailable)
  public override init() {}
  
  public init(
    name: String? = nil,
    qos: QualityOfService = .default,
    maxConcurrentTasks: Int = OperationQueue.defaultMaxConcurrentOperationCount,
    underlyingQueue: DispatchQueue? = nil,
    startSuspended: Bool = false
  ) {
    super.init()
    self.name = name
    qualityOfService = qos
    maxConcurrentTaskCount = maxConcurrentTasks
    self.underlyingQueue = underlyingQueue
    isSuspended = startSuspended
  }
}
