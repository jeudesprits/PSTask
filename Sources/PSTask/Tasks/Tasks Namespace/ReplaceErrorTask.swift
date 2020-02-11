//
//  ReplaceError.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 2/2/20.
//

import Foundation

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension Tasks {
  
  public final class ReplaceError<Output, Failure: Error>: NonFailGroupProducerTask<Output> {
    
    public init(
      from: ProducerTask<Output, Failure>,
      with output: @escaping (Failure) -> Output
    ) {
      let name = String(describing: Self.self)
      
      let transform =
        NonFailBlockProducerTask<Output>(
          name: "\(name).Transform",
          qos: from.qualityOfService,
          priority: from.queuePriority
        ) { (task, finish) in
          guard !task.isCancelled else {
            finish(.failure(.internal(ProducerTaskError.executionFailure)))
            return
          }
          
          guard let consumed = from.produced else {
            finish(.failure(.internal(ConsumerProducerTaskError.producingFailure)))
            return
          }
          
          switch consumed {
          case let .success(value):
            finish(.success(value))
          case let .failure(.internal(error)):
            finish(.failure(.internal(error)))
          case let .failure(.provided(error)):
            finish(.success(output(error)))
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
