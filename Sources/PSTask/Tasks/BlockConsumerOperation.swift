//
//  BlockConsumerTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/12/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
open class BlockConsumerProducerTask<Input, Output, Failure: Error>: ConsumerProducerTask<Input, Output, Failure> {
  
  public typealias Block = (Consumed, @escaping (Produced) -> Void) -> Void
  
  private let block: Block
  
  // MARK: -
  
  open override func execute(with consumed: Consumed) {
    block(consumed) { (produced) in self.finish(with: produced) }
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
