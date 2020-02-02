//
//  SetFailureTypeTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 2/2/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Tasks {
  
  public final class SetFailureType<Output, NewFailure: Error>: GroupProducerTask<Output, NewFailure> {
    
    public init(
      from: ProducerTask<Output, Never>,
      underlyingQueue: DispatchQueue? = nil
    ) {
      let name = String(describing: Self.self)
      
      let transform =
        BlockProducerTask<Output, NewFailure>(
          name: "\(name).Transform",
          qos: from.qualityOfService,
          priority: from.queuePriority
        ) { (task, finish) in
          guard let consumed = from.produced else {
            finish(.failure(.internalFailure(ConsumerProducerTaskError.producingFailure)))
            return
          }
          
          if case let .success(value) = consumed {
            finish(.success(value))
          } else if case let .failure(.internalFailure(error)) = consumed {
            finish(.failure(.internalFailure(error)))
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
