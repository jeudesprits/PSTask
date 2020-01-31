//
//  PSAbstractOperation.swift
//  PSOperation
//
//  Created by Ruslan Lutfullin on 1/5/20.
//

@inline(never)
@usableFromInline
internal func _abstract(file: StaticString = #file, line: UInt = #line) -> Never {
  fatalError("Method must be overridden.", file: file, line: line)
}

//@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
//open class PSAbstractOperation: Operation {
//
//  private let stateLock = PSUnfairLock()
//  private var _state = State.initialized
//  internal var state: State {
//    get {
//      stateLock.lock()
//      defer { stateLock.unlock() }
//      return _state
//    }
//    set(newState) {
//      // It's important to note that the KVO notifications are NOT called from inside
//      // the lock. If they were, the app would deadlock, because in the middle of
//      // calling the `didChangeValueForKey()` method, the observers try to access
//      // properties like `isReady` or `isFinished`. Since those methods also
//      // acquire the lock, then we'd be stuck waiting on our own lock. It's the
//      // classic definition of deadlock.
//      willChangeValue(forKey: "state")
//      stateLock.lock()
//      guard _state != .finished else { return }
//      precondition(_state.canTransition(to: newState), "Performing invalid state transition.")
//      _state = newState
//      stateLock.unlock()
//      didChangeValue(forKey: "state")
//    }
//  }
//
//
//  open override var isReady: Bool {
//    switch state {
//    case .initialized:
//      if isCancelled { state = .pending }
//      return false
//    case .pending:
//      evaluateConditions()
//      // Until conditions have been evaluated, `isReady` returns false
//      return false
//    case .ready:
//      return super.isReady || isCancelled
//    default:
//      return false
//    }
//  }
//
//  open override var isExecuting: Bool { state == .executing }
//
//  open override var isFinished: Bool { state == .finished }
//
//
//  open var isUserInitiated: Bool {
//    get { qualityOfService == .userInitiated }
//    set {
//      precondition(state < .executing, "Cannot modify `isUserInitiated` after execution has begun.")
//      qualityOfService = newValue ? .userInitiated : .default
//    }
//  }
//
//  open var isVeryHighPriority: Bool {
//    get { queuePriority == .veryHigh }
//    set {
//      precondition(state < .executing, "Cannot modify `isVeryHighPriority` after execution has begun.")
//      queuePriority = newValue ? .veryHigh : .normal
//    }
//  }
//
//
//  open private(set) var conditions = [PSOperationCondition]()
//  open private(set) var observers = [PSOperationObserver]()
//
//  open func evaluateConditions() { _abstract() }
//
//  open func addCondition(_ condition: PSOperationCondition) {
//    precondition(state < .evaluatingConditions, "Cannot modify `conditions` after evaluation conditions has begun.")
//    conditions.append(condition)
//  }
//
//  open func addObserver(_ observer: PSOperationObserver) {
//    precondition(state < .executing, "Cannot modify `observers` after execution has begun.")
//    observers.append(observer)
//  }
//
//
//  open func willEnqueue() {
//    precondition(state != .ready, "You should not call the `cancel()` method before adding to the queue.")
//    state = .pending
//  }
//
//
//  open func execute() { _abstract() }
//
//  open override func cancel() {
//    super.cancel()
//    for observer in observers { observer.operationDidCancel(self) }
//  }
//
//
//  open func produce(_ operation: Operation) {
//    for observer in observers { observer.operation(self, didProduceOperation: operation) }
//  }
//
//  open override func waitUntilFinished() {
//     // Waiting on operations is almost NEVER the right thing to do. It is
//     // usually superior to use proper locking constructs, such as `dispatch_semaphore_t`
//     // or `dispatch_group_notify`, or even `NSLocking` objects. Many developers
//     // use waiting when they should instead be chaining discrete operations
//     // together using dependencies.
//     //
//     // To reinforce this idea, invoking `waitUntilFinished()` method will crash your
//     // app, as incentive for you to find a more appropriate way to express
//     // the behavior you're wishing to create.
//     fatalError(
//       """
//       Waiting on operations is an anti-pattern. Remove this ONLY if you're absolutely \
//       sure there is No Other Way™.
//       """
//     )
//   }
//
//
//  internal override init() {
//    super.init()
//  }
//}
//
//public extension PSAbstractOperation {
//
//  enum Error: Swift.Error {
//
//    case conditionsFailed(withErrors: [Swift.Error])
//    case executionFailed
//  }
//}
//
//internal extension PSAbstractOperation {
//
//  enum State: Int {
//
//    case initialized
//    case pending
//    case evaluatingConditions
//    case ready
//    case executing
//    case finishing
//    case finished
//  }
//}
//
//internal extension PSAbstractOperation.State {
//
//  func canTransition(to newState: Self) -> Bool {
//    switch (self, newState) {
//    case (.initialized, .pending),
//         (.pending, .evaluatingConditions),
//         (.evaluatingConditions, .ready),
//         (.ready, .executing),
//         (.ready, .finishing),
//         (.executing, .finishing),
//         (.finishing, .finished):
//      return true
//    default:
//      return false
//    }
//  }
//}
//
//extension PSAbstractOperation.State: Comparable {
//
//  public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
//
//  public static func == (lhs: Self, rhs: Self) -> Bool { lhs.rawValue == rhs.rawValue }
//}

//internal extension PSAbstractOperation {
//
//  static var keyPathsForValuesAffectings: Set<String> { ["state"] }
//
//  @objc static func keyPathsForValuesAffectingIsReady() -> Set<String> { keyPathsForValuesAffectings }
//
//  @objc static func keyPathsForValuesAffectingIsExecuting() -> Set<String> { keyPathsForValuesAffectings }
//
//  @objc static func keyPathsForValuesAffectingIsFinished() -> Set<String> { keyPathsForValuesAffectings }
//}
//
//public extension Operation {
//
//  func addDependencies(_ dependencies: [Operation]) { for dependency in dependencies { addDependency(dependency) } }
//}
//
//public extension Operation {
//
//  func addCompletionBlock(_ block: @escaping () -> Void) {
//    if let existing = completionBlock {
//      // If we already have a `completionBlock`, we construct a new one by chaining them together.
//      completionBlock = {
//        existing()
//        block()
//      }
//    } else {
//      completionBlock = block
//    }
//  }
//}
//
//public extension PSOperationProtocol {
//
//  func addProducedCompletionBlock(_ block: @escaping ProducedCompletionBlock) {
//    if let existing = producedCompletionBlock {
//      // If we already have a `completionBlock`, we construct a new one by chaining them together.
//      producedCompletionBlock = { (produced) in
//        existing(produced)
//        block(produced)
//      }
//    } else {
//      producedCompletionBlock = block
//    }
//  }
//}
