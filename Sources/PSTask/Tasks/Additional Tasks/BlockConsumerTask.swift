//
//  BlockConsumerTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/12/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public typealias BlockConsumerTask<Input, Failure: Error> = BlockConsumerProducerTask<Input, Void, Failure>

// MARK: -

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public typealias NonFailBlockConsumerTask<Input> = BlockConsumerTask<Input, Never>

// MARK: -

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class BlockConsumerProducerTask<Input, Output, Failure: Error>: ConsumerProducerTask<Input, Output, Failure> {
  
  public typealias Block = (BlockConsumerProducerTask, Consumed, @escaping (Produced) -> Void) -> Void
  
  private let block: Block
  
  // MARK: -
  
  public override func execute(with consumed: Consumed) {
    block(self, consumed) { (produced) in self.finish(with: produced) }
  }
  
  // MARK: -
  
  public init(
    name: String? = nil,
    qos: QualityOfService = .default,
    priority: Operation.QueuePriority = .normal,
    producing: ProducingTask,
    block: @escaping Block
  ) {
    self.block = block
    super.init(name: name, qos: qos, priority: priority, producing: producing)
  }
}
