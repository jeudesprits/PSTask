//
//  GatedTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 2/2/20.
//

import Foundation

public final class GatedTask: NonFailTask {
  
  private let operation: Operation
  
  // MARK: -
  
  private var isReadyObserver: NSKeyValueObservation!
  private var isFinishObserver: NSKeyValueObservation!
  
  // MARK: -
  
  public override func execute() {
    guard !isCancelled else {
      finish(with: .failure(.internalFailure(ProducerTaskError.executionFailure)))
      return
    }
    
    isReadyObserver = operation.observe(\.isReady, options: .new) { (operation, change) in
      guard let new = change.newValue, new else { return }
      operation.start()
    }
    isFinishObserver = operation.observe(\.isFinished, options: .new) { [unowned self] (operation, change) in
      guard let new = change.newValue, new else { return }
      self.finish(with: .success)
    }
  }
  
  public override func cancel() {
    operation.cancel()
    super.cancel()
  }
  
  // MARK: -
  
  public init(
    name: String? = nil,
    qos: QualityOfService = .default,
    priority: Operation.QueuePriority = .normal,
    operation: Operation
  ) {
    self.operation = operation
    super.init(name: name, qos: qos, priority: priority)
  }
}
