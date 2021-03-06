//
//  CatchTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 2/3/20.
//

import Foundation

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension Tasks {
  
  public final class Catch<Output, Failure: Error, T: ProducerTaskProtocol>: GroupProducerTask<Output, T.Failure>
    where Output == T.Output
  {
    
    public init(
      from: ProducerTask<Output, Failure>,
      handler: @escaping (Failure) -> T
    ) {
      let name = String(describing: Self.self)
      
      super.init(
        name: name,
        qos: from.qualityOfService,
        priority: from.queuePriority,
        underlyingQueue: (from as? TaskQueueContainable)?.innerQueue.underlyingQueue,
        tasks: (from)
      )
      
      let transform =
        BlockConsumerTask<Output, Failure>(
          name: "\(name).Transform",
          qos: from.qualityOfService,
          priority: from.queuePriority,
          producing: from
        ) { [unowned self] (task, consumed, finish) in
            guard !task.isCancelled else {
              finish(.failure(.internal(ProducerTaskError.executionFailure)))
              return
            }
            
            switch consumed {
            case let .success(value):
              self.finish(with: .success(value))
              
            case let .failure(.internal(error)):
              self.finished(with: .failure(.internal(error)))
              
            case let .failure(.provided(error)):
              let newTask = handler(error).recieve { (produced) in self.finish(with: produced) }
              newTask.name = "\(name).Produced"
              newTask.qualityOfService = from.qualityOfService
              newTask.queuePriority = from.queuePriority
              if let newTask = newTask as? TaskQueueContainable, let from = from as? TaskQueueContainable {
                newTask.innerQueue.underlyingQueue = from.innerQueue.underlyingQueue
              }
              task.produce(new: newTask)
            }
            
          finish(.success)
        }
      
      self.addTask(transform)
    }
  }
}
