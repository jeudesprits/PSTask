//
//  ConsumerTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/4/20.
//

import Foundation

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public typealias ConsumerTask<Input, Failure: Error> = ConsumerProducerTask<Input, Void, Failure>

// MARK: -

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public typealias NonFailConsumerTask<Input> = ConsumerTask<Input, Never>

// MARK: -

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public enum ConsumerProducerTaskError: Error { case producingFailure }

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
open class ConsumerProducerTask<Input, Output, Failure: Error>: ProducerTask<Output, Failure>, ConsumerProducerTaskProtocol {
  
  public typealias Input = Input
  
  // MARK: -
  
  public let producing: ProducingTask
  
  // MARK: -
  
  open var consumed: Consumed? { self.producing.produced }
  
  // MARK: -
  
  open override func execute() {
    guard let consumed = self.consumed else {
      self.finish(with: .failure(.internal(ConsumerProducerTaskError.producingFailure)))
      return
    }
    
    self.execute(with: consumed)
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
    self.addDependency(producing)
  }
}

// MARK: -

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public typealias NonFailConsumerProducerTask<Input, Output> = ConsumerProducerTask<Input, Output, Never>
