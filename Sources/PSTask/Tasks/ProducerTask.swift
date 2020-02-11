//
//  ProducerTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/4/20.
//

import Foundation
import PSLock

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public typealias Task<Failure: Error> = ProducerTask<Void, Failure>

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension Result where Success == Void {
  
  public static var success: Self { .success(()) }
}

// MARK: -

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public typealias NonFailTask = ProducerTask<Void, Never>

// TODO: - Добавить поддержку `Identifiable`.
@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
open class ProducerTask<Output, Failure: Error>: Operation, ProducerTaskProtocol {
  
  public typealias Output = Output
  public typealias Failure = Failure
  
  // MARK: -
  
  private static var keyPathsForValuesAffectings: Set<String> { ["state"] }
  
  @objc
  private static func keyPathsForValuesAffectingIsReady() -> Set<String> { Self.keyPathsForValuesAffectings }
  
  @objc
  private static func keyPathsForValuesAffectingIsExecuting() -> Set<String> { Self.keyPathsForValuesAffectings }
  
  @objc
  private static func keyPathsForValuesAffectingIsFinished() -> Set<String> { Self.keyPathsForValuesAffectings }
  
  // MARK: -
  
  private let stateLock = UnfairLock()
  private var _state = _State.initialized
  internal private(set) var state: _State {
    get { self.stateLock.sync { _state } }
    set(newState) {
      // It's important to note that the KVO notifications are NOT called from inside
      // the lock. If they were, the app would deadlock, because in the middle of
      // calling the `didChangeValueForKey()` method, the observers try to access
      // properties like `isReady` or `isFinished`. Since those methods also
      // acquire the lock, then we'd be stuck waiting on our own lock. It's the
      // classic definition of deadlock.
      willChangeValue(forKey: "state")
      self.stateLock.sync {
        guard self._state != .finished else { return }
        precondition(self._state.canTransition(to: newState), "Performing invalid state transition.")
        self._state = newState
      }
      didChangeValue(forKey: "state")
    }
  }
  
  // MARK: -
  
  open private(set) var produced: Produced?
  
  // MARK: -
  
  open private(set) var mutuallyExclusiveConditions = [String : AnyCondition]()
  
  open private(set) var conditions = [AnyCondition]()
  
  @discardableResult
  open func addCondition<C: Condition>(_ condition: C) -> Self {
    precondition(self.state < .pending, "Cannot modify conditions after execution has begun.")
    self.conditions.append(.init(condition))
    return self
  }
  
  @discardableResult
  open func addCondition<T>(_ condition: Conditions.MutuallyExclusive<T>) -> Self {
    precondition(self.state < .pending, "Cannot modify conditions after execution has begun.")
    self.mutuallyExclusiveConditions[String(describing: T.self)] = .init(condition)
    self.conditions.append(.init(condition))
    return self
  }
  
  private func evaluateConditions() {
    precondition(self.state == .pending, "\(#function) was called out-of-order.")

    self.state = .evaluatingConditions

    _ConditionEvaluator.shared.evaluate(conditions, for: self) { (results) in
      let errors = results
        .compactMap { (result) -> Swift.Error? in
          if case let .failure(error) = result {
            return error
          } else {
            return nil
          }
        }

      if !errors.isEmpty { self.produced = .failure(.internal(Error.conditionsFailure)) }

      self.state = .ready
    }
  }
  
  // MARK: -
  
  open private(set) var observers = [Observer]()
  
  @discardableResult
  open func addObserver<O: Observer>(_ observer: O) -> Self {
    precondition(self.state < .executing, "Cannot modify observers after execution has begun.")
    self.observers.append(observer)
    return self
  }
  
  // MARK: -
  
  open override var isReady: Bool {
    switch self.state {
    case .initialized:
      if self.isCancelled { self.state = .pending }
      return false
    case .pending:
      self.evaluateConditions()
      // Until conditions have been evaluated, `isReady` returns false
      return false
    case .ready:
      return super.isReady || self.isCancelled
    default:
      return false
    }
  }
  
  open override var isExecuting: Bool { self.state == .executing }
  
  open override var isFinished: Bool { self.state == .finished }
  
  // MARK: -
  
  open func willEnqueue() {
    precondition(self.state != .ready, "You should not call the `cancel()` method before adding to the queue.")
    self.state = .pending
  }
  
  open override func start() {
    // `Operation.start()` method contains important logic that shouldn't be bypassed.
    super.start()
    // If the operation has been cancelled, we still need to enter the `.finished` state.
    if self.isCancelled { self.finish(with: self.produced ?? .failure(.internal(Error.executionFailure))) }
  }
  
  open override func cancel() {
    super.cancel()
    self.observers.forEach { $0.taskDidCancel(self) }
  }
  
  open override func main() {
    precondition(self.state == .ready, "This task must be performed on an task queue.")
    
    if self.produced == nil && !self.isCancelled {
      self.state = .executing
      self.observers.forEach { $0.taskDidStart(self) }
      self.execute()
    } else {
      self.finish(with: self.produced ?? .failure(.internal(Error.conditionsFailure)))
    }
  }
  
  // MARK: -

  open func execute() { _abstract() }
  
  // MARK: -
  
  open func produce<T: ProducerTaskProtocol>(new task: T) { self.observers.forEach { $0.task(self, didProduce: task) } }
  
  // MARK: -
  
  private var hasFinishedAlready = false
  
  open func finish(with produced: Produced) {
    if !self.hasFinishedAlready {
      self.produced = produced
      self.hasFinishedAlready = true
      self.state = .finishing
      let block = {
        self.producedCompletionBlock?(produced)
        if case let .success(value) = produced { self.assignBlock?(value) }
      }
      if let recieveQueue = self.recieveQueue {
        recieveQueue.async { block() }
      } else {
        block()
      }
      self.finished(with: produced)
      self.observers.forEach { $0.taskDidFinish(self) }
      self.state = .finished
    }
  }
  
  open func finished(with produced: Produced) {}
  
  public final override func waitUntilFinished() { super.waitUntilFinished() }
  
  // MARK: -
  
  @available(*, unavailable)
  open override func addDependency(_ operation: Operation) { super.addDependency(operation) }
  
  @available(*, unavailable)
  open override func removeDependency(_ operation: Operation) { super.removeDependency(operation) }
  
  @discardableResult
  open func addDependency<T: ProducerTaskProtocol>(_ task: T) -> Self {
    precondition(self.state < .executing, "Dependencies cannot be modified after execution has begun.")
    super.addDependency(task)
    return self
  }
  
  @discardableResult
  open func removeDependency<T: ProducerTaskProtocol>(_ task: T) -> Self {
    precondition(self.state < .executing, "Dependencies cannot be modified after execution has begun.")
    super.removeDependency(task)
    return self
  }
  
  // MARK: -
  
  private unowned(unsafe) var recieveQueue: DispatchQueue?
  
  @discardableResult
  open func recieve(on queue: DispatchQueue) -> Self {
    self.recieveQueue = queue
    return self
  }
  
  // MARK: -
  
  @available(*, unavailable)
  open override var completionBlock: (() -> Void)? { didSet {} }
  
  private var producedCompletionBlock: ((Produced) -> Void)?

  private var assignBlock: ((Output) -> Void)?
  
  // MARK: -
  
  @discardableResult
  open func recieve(completion: @escaping (Produced) -> Void) -> Self {
    if let existing = self.producedCompletionBlock {
      self.producedCompletionBlock = {
        existing($0)
        completion($0)
      }
    } else {
      self.producedCompletionBlock = completion
    }
    return self
  }
  
  @discardableResult
  open func assign<Root>(to keyPath: ReferenceWritableKeyPath<Root, Output>, on object: Root) -> Self {
    let block: (Output) -> Void = { object[keyPath: keyPath] = $0 }
    if let existing = self.assignBlock {
      self.assignBlock = {
        existing($0)
        block($0)
      }
    } else {
      self.assignBlock = block
    }
    return self
  }
  
  // MARK: -
  
  @available(*, unavailable)
  public override init() { super.init() }
  
  public init(
    name: String? = nil,
    qos: QualityOfService = .default,
    priority: Operation.QueuePriority = .normal
  ) {
    super.init()
    self.name = name ?? String(describing: Self.self)
    self.qualityOfService = qos
    self.queuePriority = priority
  }
}

extension ProducerTask {
  
  internal enum _State: Int {
    
    case initialized
    case pending
    case evaluatingConditions
    case ready
    case executing
    case finishing
    case finished
  }
}

extension ProducerTask._State {
  
  internal func canTransition(to newState: Self) -> Bool {
    switch (self, newState) {
    case (.initialized, .pending),
         (.pending, .evaluatingConditions),
         (.evaluatingConditions, .ready),
         (.ready, .executing),
         (.ready, .finishing),
         (.executing, .finishing),
         (.finishing, .finished):
      return true
    default:
      return false
    }
  }
}

extension ProducerTask._State: Comparable {
  
  internal static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
  
  internal static func == (lhs: Self, rhs: Self) -> Bool { lhs.rawValue == rhs.rawValue }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension ProducerTask {
  
  public enum ProducerTaskError: Swift.Error { case conditionsFailure, executionFailure }
  
  public typealias Error = ProducerTaskError
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension ProducerTask {
  
  @inlinable
  public func map<NewOutput>(
    _ transform: @escaping (Output) -> NewOutput
  ) -> Tasks.Map<Output, NewOutput, Failure> {
    .init(from: self, transform: transform)
  }
  
  @inlinable
  public func tryMap<NewOutput>(
    _ transform: @escaping (Output) throws -> NewOutput
  ) -> Tasks.TryMap<Output, NewOutput, Failure> {
    .init(from: self, transform: transform)
  }
  
  @inlinable
  public func flatMap<T: ProducerTaskProtocol>(
    _ transform: @escaping (Output) -> T
  ) -> Tasks.FlatMap<Output, Failure, T> where T.Output == Output, T.Failure == Failure {
    .init(from: self, transform: transform)
  }
  
  @inlinable
  public func mapError<NewFailure: Swift.Error>(
    _ transform: @escaping (Failure) -> NewFailure
  ) -> Tasks.MapError<Output, Failure, NewFailure> {
    .init(from: self, transform: transform)
  }
  
  @inlinable
  public func replaceNil<NonNilOutput>(
    with output: @escaping () -> NonNilOutput
  ) -> Tasks.Map<Output, NonNilOutput, Failure> where Output == NonNilOutput? {
    .init(from: self, transform: { _ in output() })
  }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension ProducerTask where Failure == Never {
  
  @inlinable
  public func setFailureType<NewFailure: Swift.Error>(
    to failureType: NewFailure.Type
  ) -> Tasks.SetFailureType<Output, NewFailure> {
    .init(from: self)
  }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension ProducerTask {
  
  @inlinable
  public func compactMap<NewOutput>(
    _ transform: @escaping (Output) -> NewOutput?
  ) -> Tasks.CompactMap<Output, NewOutput, Failure> {
    .init(from: self, transform: transform)
  }
  
  @inlinable
  public func tryCompactMap<NewOutput>(
    _ transform: @escaping (Output) throws -> NewOutput?
  ) -> Tasks.TryCompactMap<Output, NewOutput, Failure> {
    .init(from: self, transform: transform)
  }
  
  @inlinable
  public func replaceError(
    with output: @escaping (Failure) -> Output
  ) -> Tasks.ReplaceError<Output, Failure> {
    .init(from: self, with: output)
  }
  
  @inlinable
  public func ignoreOutput() -> Tasks.IgnoreOutput<Output, Failure> {
    .init(from: self)
  }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension ProducerTask where Output == Void {
  
  @inlinable
  public func replaceEmpty<NewOutput>(
    with output: @escaping () -> NewOutput
  ) -> Tasks.ReplaceEmpty<NewOutput, Failure> {
    .init(from: self, with: output)
  }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension ProducerTask {

  @inlinable
  public func zip<T: ProducerTaskProtocol>(
    _ t: T
  ) -> Tasks.Zip<ProducerTask, T>
    where Failure == T.Failure {
    .init(tasks: (self, t))
  }
  
  @inlinable
  public func zip<T1: ProducerTaskProtocol,
                  T2: ProducerTaskProtocol>(
    _ t1: T1,
    _ t2: T2
  ) -> Tasks.Zip3<ProducerTask, T1, T2>
    where Failure == T1.Failure,
          T1.Failure == T2.Failure {
      .init(tasks: (self, t1, t2))
  }
  
  @inlinable
  public func zip<T1: ProducerTaskProtocol,
                  T2: ProducerTaskProtocol,
                  T3: ProducerTaskProtocol>(
    _ t1: T1,
    _ t2: T2,
    _ t3: T3
  ) -> Tasks.Zip4<ProducerTask, T1, T2, T3>
    where Failure == T1.Failure,
          T1.Failure == T2.Failure,
          T2.Failure == T3.Failure {
      .init(tasks: (self, t1, t2, t3))
  }
  
  @inlinable
  public func zip<T1: ProducerTaskProtocol,
                  T2: ProducerTaskProtocol,
                  T3: ProducerTaskProtocol,
                  T4: ProducerTaskProtocol>(
    _ t1: T1,
    _ t2: T2,
    _ t3: T3,
    _ t4: T4
  ) -> Tasks.Zip5<ProducerTask, T1, T2, T3, T4>
    where Failure == T1.Failure,
          T1.Failure == T2.Failure,
          T2.Failure == T3.Failure,
          T3.Failure == T4.Failure {
      .init(tasks: (self, t1, t2, t3, t4))
  }
  
   @inlinable
   public func zip<T1: ProducerTaskProtocol,
                   T2: ProducerTaskProtocol,
                   T3: ProducerTaskProtocol,
                   T4: ProducerTaskProtocol,
                   T5: ProducerTaskProtocol>(
     _ t1: T1,
     _ t2: T2,
     _ t3: T3,
     _ t4: T4,
     _ t5: T5
   ) -> Tasks.Zip6<ProducerTask, T1, T2, T3, T4, T5>
     where Failure == T1.Failure,
           T1.Failure == T2.Failure,
           T2.Failure == T3.Failure,
           T3.Failure == T4.Failure,
           T4.Failure == T5.Failure {
       .init(tasks: (self, t1, t2, t3, t4, t5))
   }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension ProducerTask {
  
  @inlinable
  public func assertNoFailure(
    _ prefix: String = "",
    file: StaticString = #file,
    line: UInt = #line
  ) -> Tasks.AssertNoFailure<Output, Failure> {
    .init(prefix, file: file, line: line, from: self)
  }
  
  @inlinable
  public func `catch`<T: ProducerTaskProtocol>(
    _ handler: @escaping (Failure) -> T
  ) -> Tasks.Catch<Output, Failure, T> where T.Output == Output {
    .init(from: self, handler: handler)
  }
  
  @inlinable
  public func tryCatch<T: ProducerTaskProtocol>(
    _ handler: @escaping (Failure) throws -> T
  ) -> Tasks.TryCatch<Output, Failure, T> where T.Output == Output {
    .init(from: self, handler: handler)
  }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension ProducerTask where Output == Data {
  
  @inlinable
  public func decode<Item: Decodable>(
    type: Item.Type,
    decoder: JSONDecoder
  ) -> Tasks.Decode<Failure, Item> {
    .init(from: self, type: type, decoder: decoder)
  }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension ProducerTask where Output: Encodable {
  
  @inlinable
  public func encode(
    encoder: JSONEncoder
  ) -> Tasks.Encode<Output, Failure> {
    .init(from: self, encoder: encoder)
  }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension ProducerTask {
  
  @inlinable
  public func map<NewOutput>(
    _ keyPath: KeyPath<Output, NewOutput>
  ) -> Tasks.MapKeyPath<Output, NewOutput, Failure> {
    .init(from: self, keyPath: keyPath)
  }
  
  @inlinable
  public func map<NewOutput1, NewOutput2>(
    _ keyPath1: KeyPath<Output, NewOutput1>,
    _ keyPath2: KeyPath<Output, NewOutput2>
  ) -> Tasks.MapKeyPath2<Output, NewOutput1, NewOutput2, Failure> {
    .init(from: self, keyPath1: keyPath1, keyPath2: keyPath2)
  }
  
  @inlinable
  public func map<NewOutput1, NewOutput2, NewOutput3>(
    _ keyPath1: KeyPath<Output, NewOutput1>,
    _ keyPath2: KeyPath<Output, NewOutput2>,
    _ keyPath3: KeyPath<Output, NewOutput3>
  ) -> Tasks.MapKeyPath3<Output, NewOutput1, NewOutput2, NewOutput3, Failure> {
    .init(from: self, keyPath1: keyPath1, keyPath2: keyPath2, keyPath3: keyPath3)
  }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension ProducerTask where Output == Void  {
 
  @inlinable
  public func breakpointOnOutput(
    receiveOutput: @escaping (Output) -> Bool
  ) -> Tasks.BreakpointTask<Output, Failure> {
    fatalError("Can't call when Output == Void")
  }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension ProducerTask where Failure == Never  {
   
  @inlinable
  public func breakpointOnFailure(
    receiveFailure: @escaping (Failure) -> Bool
  ) -> Tasks.BreakpointTask<Output, Failure> {
    fatalError("Can't call when Failure == Never")
  }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension ProducerTask {
 
  @inlinable
  public func breakpointOnOutput(
    receiveOutput: @escaping (Output) -> Bool
  ) -> Tasks.BreakpointTask<Output, Failure> {
    .init(from: self, receiveOutput: receiveOutput, receiveFailure: nil)
  }
  
  @inlinable
  public func breakpointOnFailure(
    receiveFailure: @escaping (Failure) -> Bool
  ) -> Tasks.BreakpointTask<Output, Failure> {
    .init(from: self, receiveOutput: nil, receiveFailure: receiveFailure)
  }

  @inlinable
  public func breakpointOnError() -> Tasks.BreakpointTask<Output, Failure> {
    .init(from: self, receiveOutput: nil, receiveFailure: nil)
  }
}

// MARK: -

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public typealias NonFailProducerTask<Output> = ProducerTask<Output, Never>
