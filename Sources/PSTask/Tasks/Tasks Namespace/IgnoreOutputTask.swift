//
//  IgnoreOutputTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 2/2/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Tasks {
  
  public final class IgnoreOutput<Output, Failure: Error>: GroupTask<Failure> {
    
    public init(
       from: ProducerTask<Output, Failure>,
       underlyingQueue: DispatchQueue? = nil
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
          
          if case .success = consumed {
            finish(.success)
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
        tasks: (from, transform)
      )
    }
  }
}
