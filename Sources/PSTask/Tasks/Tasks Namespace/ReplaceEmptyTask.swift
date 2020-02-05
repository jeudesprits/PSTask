//
//  ReplaceEmptyTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 2/5/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Tasks {

  public final class ReplaceEmpty<Output, Failure: Error>: GroupProducerTask<Output, Failure> {
    
    public init(
      from: Task<Failure>,
      with output: @escaping () -> Output
    ) {
      let name = String(describing: Self.self)
      
      let transform =
        BlockConsumerProducerTask<Void, Output, Failure>(
          name: "\(name).Transform",
          qos: from.qualityOfService,
          priority: from.queuePriority,
          producing: from
        ) { (task, consumed, finish) in
          guard !task.isCancelled else {
            finish(.failure(.internalFailure(ProducerTaskError.executionFailure)))
            return
          }
          
          switch consumed {
          case .success:
            finish(.success(output()))
          case let .failure(.internalFailure(error)):
            finish(.failure(.internalFailure(error)))
          case let .failure(.providedFailure(error)):
            finish(.failure(.providedFailure(error)))
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
