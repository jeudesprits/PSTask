//
//  CatchTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 2/3/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Tasks {
  
  public final class Catch<Output, Failure: Error, T: ProducerTaskProtocol>: GroupProducerTask<Output, T.Failure>
    where Output == T.Output
  {
    
    public init(
      from: ProducerTask<Output, Failure>,
      transform: @escaping (Failure) -> T
    ) {
      let name = String(describing: Self.self)
      
      super.init(
        name: name,
        qos: from.qualityOfService,
        priority: from.queuePriority,
        underlyingQueue: (from as? TaskQueueContainable)?.innerQueue.underlyingQueue,
        tasks: (from))
      
      let transform =
        BlockConsumerTask<Output, Failure>(
          name: "\(name).Transform",
          qos: from.qualityOfService,
          priority: from.queuePriority,
          producing: from
        ) { [unowned self] (task, consumed, finish) in
            guard !task.isCancelled else {
              finish(.failure(.internalFailure(ProducerTaskError.executionFailure)))
              return
            }
            
            switch consumed {
            case let .success(value):
              self.finish(with: .success(value))
              
            case let .failure(.internalFailure(error)):
              self.finished(with: .failure(.internalFailure(error)))
              
            case let .failure(.providedFailure(error)):
              let new = transform(error).recieve { (produced) in self.finish(with: produced) }
              new.name = "\(name).Produced"
              new.qualityOfService = from.qualityOfService
              new.queuePriority = from.queuePriority
              task.produce(new: new)
            }
            
            finish(.success)
        }
      
      addTask(transform)
    }
  }
}
