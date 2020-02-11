//
//  BlockProducerTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/12/20.
//

import Foundation

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public typealias BlockTask<Failure: Error> = BlockProducerTask<Void, Failure>

// MARK: -

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public typealias NonFailBlockTask = BlockTask<Never>

// MARK: -

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public final class BlockProducerTask<Output, Failure: Error>: ProducerTask<Output, Failure> {
  
  public typealias Block = (BlockProducerTask, @escaping (Produced) -> Void) -> Void
  
  private let block: Block
  
  // MARK: -
  
  public override func execute() {
    self.block(self) { (produced) in self.finish(with: produced) } }
  
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

// MARK: -

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public typealias NonFailBlockProducerTask<Output> = BlockProducerTask<Output, Never>
