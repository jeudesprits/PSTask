//
//  ConsumerTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/4/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public enum ConsumerProducerTaskError: Error { case producingFailure }

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
open class ConsumerProducerTask<Input, Output, Failure: Error>: ProducerTask<Output, Failure>, ConsumerProducerTaskProtocol {
  
  public typealias Input = Input
  
  // MARK: -
  
  public let producing: ProducingTask
  
  // MARK: -
  
  open var consumed: Consumed? { producing.produced }
  
  // MARK: -
  
  open override func execute() {
    guard let consumed = consumed else {
      finish(with: .failure(.internalFailure(ConsumerProducerTaskError.producingFailure)))
      return
    }
    
    execute(with: consumed)
  }
  
  open func execute(with consumed: Consumed) { _abstract() }
  
  // MARK: -
  
  public init(
    name: String? = nil,
    qos: QualityOfService = .default,
    priority: Operation.QueuePriority = .normal,
    producing: ProducingTask
  ) {
    self.producing = producing
    super.init(name: name, qos: qos, priority: priority)
    addDependency(producing)
  }
}
