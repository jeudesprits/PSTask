//
//  ReplaceError.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 2/2/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Tasks {
  
  public final class ReplaceError<Output, Failure: Error>: GroupProducerTask<Output, Failure> {
    
    public init(
      from: ProducerTask<Output, Failure>,
      transform: @escaping (Error) -> Output
    ) {
      let name = String(describing: Self.self)
      
      let transform =
        BlockProducerTask<Output, Failure>(
          name: "\(name).Transform",
          qos: from.qualityOfService,
          priority: from.queuePriority
        ) { (task, finish) in
          guard !task.isCancelled else {
            finish(.failure(.internalFailure(ProducerTaskError.executionFailure)))
            return
          }
          
          guard let consumed = from.produced else {
            finish(.failure(.internalFailure(ConsumerProducerTaskError.producingFailure)))
            return
          }
          
          if case let .success(value) = consumed {
            finish(.success(value))
          } else if case let .failure(.internalFailure(error)) = consumed {
            finish(.success(transform(error)))
          } else if case let .failure(.providedFailure(error)) = consumed {
            finish(.success(transform(error)))
          }
        }.addDependency(from)
      
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
