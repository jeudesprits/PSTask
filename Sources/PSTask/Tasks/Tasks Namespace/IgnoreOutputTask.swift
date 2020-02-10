//
//  IgnoreOutputTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 2/2/20.
//

import Foundation

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension Tasks {
  
  public final class IgnoreOutput<Output, Failure: Error>: GroupTask<Failure> {
    
    public init(
       from: ProducerTask<Output, Failure>
     ) {
      let name = String(describing: Self.self)
      
      let transform =
        BlockTask<Failure>(
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
          case .success:
            finish(.success)
          case let .failure(.internalFailure(error)):
            finish(.failure(.internalFailure(error)))
          case let .failure(.providedFailure(error)):
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
