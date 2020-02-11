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
  private var isCancelObserver: NSKeyValueObservation!
  private var isFinishObserver: NSKeyValueObservation!
  
  // MARK: -
  
  public override func execute() {
    guard !isCancelled else {
      self.finish(with: .failure(.internal(ProducerTaskError.executionFailure)))
      return
    }
    
    self.isReadyObserver =
      self.operation.observe(\.isReady, options: [.initial, .new]) { (operation, change) in
        guard let isReady = change.newValue else { return }
        if isReady { operation.start() }
      }
    self.isCancelObserver =
      self.operation.observe(\.isCancelled, options: [.initial, .new]) { [unowned self] (_, change) in
        guard let isCancelled = change.newValue else { return }
        if isCancelled { self.finish(with: .failure(.internal(ProducerTaskError.executionFailure))) }
      }
    self.isFinishObserver =
      self.operation.observe(\.isFinished, options: [.initial, .new]) { [unowned self] (operation, change) in
        guard let isFinished = change.newValue else { return }
        if isFinished && !operation.isCancelled { self.finish(with: .success) }
      }
  }
  
  public override func cancel() {
    self.operation.cancel()
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
