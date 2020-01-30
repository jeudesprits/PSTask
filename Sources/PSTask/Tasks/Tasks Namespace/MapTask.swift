//
//  Map.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/28/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Tasks {
  
  public final class Map<Input, Output, Failure: Error>: GroupProducerTask<Output, Failure> {
  
    public init(
      from: ProducerTask<Input, Failure>,
      transform: @escaping (Input) -> Output
    ) {
      let transform =
        BlockConsumerProducerTask<Input, Output, Failure>(
          name: "\(String(describing: Self.self)).Transform",
          qos: from.qualityOfService,
          priority: from.queuePriority,
          producing: from
        ) { (task, consumed, finish) in
          guard !task.isCancelled else {
            finish(.failure(.internalFailure(ProducerTaskError.executionFailure)))
            return
          }
          
          finish(consumed.map(transform))
        }
      
      super.init(tasks: (from, transform), produced: transform)
    }
  }
}
