//
//  MapKeyPathTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 2/5/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Tasks {
  
  public final class MapKeyPath<Output, NewOutput, Failure: Error>:
    GroupProducerTask<NewOutput, Failure> {
  
    public init(
      from: ProducerTask<Output, Failure>,
      keyPath: KeyPath<Output, NewOutput>
    ) {
      let name = String(describing: Self.self)
      
      let transform =
        BlockConsumerProducerTask<Output, NewOutput, Failure>(
          name: "\(name).Transform",
          qos: from.qualityOfService,
          priority: from.queuePriority,
          producing: from
        ) { (task, consumed, finish) in
          guard !task.isCancelled else {
            finish(.failure(.internalFailure(ProducerTaskError.executionFailure)))
            return
          }
          
          finish(consumed.map { $0[keyPath: keyPath] })
        }
      
      super.init(
        name: name,
        qos: from.qualityOfService,
        priority: from.queuePriority,
        underlyingQueue: (from as? TaskQueueContainable)?.innerQueue.underlyingQueue,
        tasks: (from, transform),
        produced: transform
      )
    }
  }
  
  public final class MapKeyPath2<Output, NewOutput1, NewOutput2, Failure: Error>:
    GroupProducerTask<(NewOutput1, NewOutput2), Failure> {
  
    public init(
      from: ProducerTask<Output, Failure>,
      keyPath1: KeyPath<Output, NewOutput1>,
      keyPath2: KeyPath<Output, NewOutput2>
    ) {
      let name = String(describing: Self.self)
      
      let transform =
        BlockConsumerProducerTask<Output, (NewOutput1, NewOutput2), Failure>(
          name: "\(name).Transform",
          qos: from.qualityOfService,
          priority: from.queuePriority,
          producing: from
        ) { (task, consumed, finish) in
          guard !task.isCancelled else {
            finish(.failure(.internalFailure(ProducerTaskError.executionFailure)))
            return
          }
          
          finish(consumed.map { ($0[keyPath: keyPath1], $0[keyPath: keyPath2]) })
        }
      
      super.init(
        name: name,
        qos: from.qualityOfService,
        priority: from.queuePriority,
        underlyingQueue: (from as? TaskQueueContainable)?.innerQueue.underlyingQueue,
        tasks: (from, transform),
        produced: transform
      )
    }
  }
  
  public final class MapKeyPath3<Output, NewOutput1, NewOutput2, NewOutput3, Failure: Error>:
    GroupProducerTask<(NewOutput1, NewOutput2, NewOutput3), Failure> {
  
    public init(
      from: ProducerTask<Output, Failure>,
      keyPath1: KeyPath<Output, NewOutput1>,
      keyPath2: KeyPath<Output, NewOutput2>,
      keyPath3: KeyPath<Output, NewOutput3>
    ) {
      let name = String(describing: Self.self)
      
      let transform =
        BlockConsumerProducerTask<Output, (NewOutput1, NewOutput2, NewOutput3), Failure>(
          name: "\(name).Transform",
          qos: from.qualityOfService,
          priority: from.queuePriority,
          producing: from
        ) { (task, consumed, finish) in
          guard !task.isCancelled else {
            finish(.failure(.internalFailure(ProducerTaskError.executionFailure)))
            return
          }
          
          finish(consumed.map { ($0[keyPath: keyPath1], $0[keyPath: keyPath2], $0[keyPath: keyPath3]) })
        }
      
      super.init(
        name: name,
        qos: from.qualityOfService,
        priority: from.queuePriority,
        underlyingQueue: (from as? TaskQueueContainable)?.innerQueue.underlyingQueue,
        tasks: (from, transform),
        produced: transform
      )
    }
  }
}
