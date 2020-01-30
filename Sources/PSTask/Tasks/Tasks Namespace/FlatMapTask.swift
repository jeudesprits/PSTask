//
//  FlatMapTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/31/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Tasks {
  
  public final class FlatMap<Input, T: ProducerTaskProtocol, Failure>:
    GroupProducerTask<T.Output, T.Failure> where T.Output == Input, T.Failure == Failure {
    
    public init(
      from: ProducerTask<Input, Failure>,
      transform: @escaping (Input) -> T
    ) {
      super.init(tasks: (from))
      
      let transform =
        BlockConsumerProducerTask<Input, Void, Failure>(producing: from) {  [unowned self] (task, consumed, finish) in
          guard !task.isCancelled else {
            finish(.failure(.internalFailure(ProducerTaskError.executionFailure)))
            return
          }
          
          if case let .success(value) = consumed {
            task.produce(new: transform(value).recieve { (produced) in self.finish(with: produced) })
          } else {
            self.finish(with: consumed)
          }
          
          finish(.success(()))
      }
      
      addTask(transform)
    }
  }
}
