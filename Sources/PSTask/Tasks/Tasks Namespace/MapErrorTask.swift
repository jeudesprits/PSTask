//
//  MapErrorTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/31/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Tasks {
  
  public final class MapError<Output, Failure: Error, NewFailure: Error>: GroupProducerTask<Output, NewFailure> {
    
    public init(
      from: ProducerTask<Output, Failure>,
      transform: @escaping (Failure) -> NewFailure
    ) {
      let name = String(describing: Self.self)
      
      let transform =
        BlockProducerTask<Output, NewFailure>(
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
          
          switch consumed {
          case let .failure(.providedFailure(error)):
            finish(.failure(.providedFailure(transform(error))))
          case let .failure(.internalFailure(error)):
            finish(.failure(.internalFailure(error)))
          case let .success(value):
            finish(.success(value))
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
