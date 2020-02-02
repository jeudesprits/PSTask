//
//  TryCompactMapTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 2/2/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Tasks {
  
  public final class TryCompactMap<Output, NewOutput, Failure: Error>: GroupProducerTask<NewOutput, Error> {
    
    public init(
      from: ProducerTask<Output, Failure>,
      transform: @escaping (Output) throws -> NewOutput?,
      underlyingQueue: DispatchQueue? = nil
    ) {
      let name = String(describing: Self.self)
      
      let transform =
        BlockProducerTask<NewOutput, Error>(
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
            do {
              if let newValue = try transform(value) {
                finish(.success(newValue))
              } else {
                finish(.failure(.internalFailure(ProducerTaskError.executionFailure)))
              }
            } catch {
              finish(.failure(.providedFailure(error)))
            }
          } else if case let .failure(.internalFailure(error)) = consumed {
            finish(.failure(.internalFailure(error)))
          } else if case let .failure(.providedFailure(error)) = consumed {
            finish(.failure(.providedFailure(error)))
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
