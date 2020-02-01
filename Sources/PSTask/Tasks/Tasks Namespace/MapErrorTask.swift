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
      transform: @escaping (Failure) -> NewFailure,
      underlyingQueue: DispatchQueue? = nil
    ) {
      let name = String(describing: Self.self)
      
      let transform =
        BlockProducerTask<Output, NewFailure>.init { (task, finish) in
          guard !task.isCancelled else {
            finish(.failure(.internalFailure(ProducerTaskError.executionFailure)))
            return
          }
          
          guard let consumed = from.produced else {
            finish(.failure(.internalFailure(ConsumerProducerTaskError.producingFailure)))
            return
          }
          
          if case let .failure(.providedFailure(error)) = consumed {
            finish(.failure(.providedFailure(transform(error))))
          } else if case let .failure(.internalFailure(error)) = consumed {
            finish(.failure(.internalFailure(error)))
          } else if case let .success(value) = consumed {
            finish(.success(value))
          }
      }.addDependency(from)
      
      super.init(
        name: name,
        qos: from.qualityOfService,
        priority: from.queuePriority,
        underlyingQueue: underlyingQueue,
        tasks: (from, transform),
        produced: transform
      )
    }
  }
}
