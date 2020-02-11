//
//  FlatMapTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/31/20.
//

import Foundation

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension Tasks {
  
  public final class FlatMap<Output, Failure, T: ProducerTaskProtocol>: GroupProducerTask<T.Output, Failure>
    where T.Output == Output, T.Failure == Failure
  {
    
    public init(
      from: ProducerTask<Output, Failure>,
      transform: @escaping (Output) -> T
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
        ) {  [unowned self] (task, consumed, finish) in
          guard !task.isCancelled else {
            finish(.failure(.internal(ProducerTaskError.executionFailure)))
            return
          }
          
          switch consumed {
          case let .success(value):
            let newTask = transform(value).recieve { self.finish(with: $0) }
            newTask.name = "\(name).Produced"
            newTask.qualityOfService = from.qualityOfService
            newTask.queuePriority = from.queuePriority
            if let newTask = newTask as? TaskQueueContainable, let from = from as? TaskQueueContainable {
              newTask.innerQueue.underlyingQueue = from.innerQueue.underlyingQueue
            }
            task.produce(new: newTask)
            
          default:
            self.finish(with: consumed)
          }
          
          finish(.success)
      }
      
      self.addTask(transform)
    }
  }
}
