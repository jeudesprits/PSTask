//
//  TryMapTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/29/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Tasks {

  public final class TryMap<Output, NewOutput, Failure: Error>: GroupProducerTask<NewOutput, Error> {
    
    public init(
      from: ProducerTask<Output, Failure>,
      transform: @escaping (Output) throws -> NewOutput
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
              let newValue = try transform(value)
              finish(.success(newValue))
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
        underlyingQueue: (from as? TaskQueueContainable)?.innerQueue.underlyingQueue,
        tasks: (from, transform),
        produced: transform
      )
    }
  }
}
