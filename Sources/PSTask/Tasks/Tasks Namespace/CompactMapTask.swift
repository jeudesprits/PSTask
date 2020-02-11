//
//  CompactMapTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 2/2/20.
//

import Foundation

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension Tasks {
 
  public final class CompactMap<Output, NewOutput, Failure: Error>: GroupProducerTask<NewOutput, Failure> {
    
    public init(
      from: ProducerTask<Output, Failure>,
      transform: @escaping (Output) -> NewOutput?
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
            finish(.failure(.internal(ProducerTaskError.executionFailure)))
            return
          }
          
          switch consumed {
          case let .success(value):
            if let newValue = transform(value) {
              finish(.success(newValue))
            } else {
              finish(.failure(.internal(ProducerTaskError.executionFailure)))
            }
          case let .failure(.internal(error)):
            finish(.failure(.internal(error)))
          case let .failure(.provided(error)):
            finish(.failure(.provided(error)))
          }
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
