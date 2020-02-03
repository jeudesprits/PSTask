//
//  CompactMapTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 2/2/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
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
            finish(.failure(.internalFailure(ProducerTaskError.executionFailure)))
            return
          }
          
          let newConsumed =
            consumed
              .map(transform)
              .flatMap { (value) -> Result<NewOutput, ProducerTaskProtocolError<Failure>> in
                guard let value = value else { return .failure(.internalFailure(ProducerTaskError.executionFailure)) }
                return .success(value)
              }
          
          finish(newConsumed)
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
