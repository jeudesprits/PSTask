//
//  BlockProducerTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/12/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
open class BlockProducerTask<Output, Failure: Error>: ProducerTask<Output, Failure> {
  
  public typealias Block = (@escaping (Produced) -> Void) -> Void
  
  private let block: Block
  
  // MARK: -
  
  open override func execute() { block { (produced) in self.finish(with: produced) } }
  
  // MARK: -
  
  public init(
    name: String? = nil,
    qos: QualityOfService = .default,
    priority: Operation.QueuePriority = .normal,
    block: @escaping Block
  ) {
    self.block = block
    super.init(name: name, qos: qos, priority: priority)
  }
}
