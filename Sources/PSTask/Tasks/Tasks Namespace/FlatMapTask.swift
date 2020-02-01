//
//  FlatMapTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/31/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Tasks {
  
  public final class FlatMap<Output, Failure, T: ProducerTaskProtocol>: GroupProducerTask<T.Output, T.Failure> where T.Output == Output, T.Failure == Failure {
    
    public init(
      from: ProducerTask<Output, Failure>,
      transform: @escaping (Output) -> T,
      underlyingQueue: DispatchQueue? = nil
    ) {
      let name = String(describing: Self.self)
      
      super.init(
        name: name,
        qos: from.qualityOfService,
        priority: from.queuePriority,
        underlyingQueue: underlyingQueue,
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
            finish(.failure(.internalFailure(ProducerTaskError.executionFailure)))
            return
          }
          
          if case let .success(value) = consumed {
            // TODO: - Продумать передачу `underlyingQueue`, если возвращаемая задача - групповая.
            let newTask = transform(value).recieve { (produced) in self.finish(with: produced) }
            newTask.name = "\(name).Produced"
            newTask.qualityOfService = from.qualityOfService
            newTask.queuePriority = from.queuePriority
  
            task.produce(new: newTask)
          } else {
            self.finish(with: consumed)
          }
          
          finish(.success)
      }
      
      addTask(transform)
    }
  }
}
