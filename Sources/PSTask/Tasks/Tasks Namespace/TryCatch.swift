//
//  TryCatch.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 2/3/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Tasks {

  public final class TryCatch<Output, Failure: Error, T: ProducerTaskProtocol>: GroupProducerTask<Output, Error>
    where T.Output == Output
  {
    
    public init(
      from: ProducerTask<Output, Failure>,
      handler: @escaping (Failure) throws -> T
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
              finish(.failure(.internalFailure(ProducerTaskError.executionFailure)))
              return
            }
            
            switch consumed {
            case let .success(value):
              self.finish(with: .success(value))
              
            case let .failure(.internalFailure(error)):
              self.finished(with: .failure(.internalFailure(error)))
              
            case let .failure(.providedFailure(error)):
              do {
                let newTask = try handler(error)
                  .recieve { (produced) in
                    switch produced {
                    case let .success(value):
                      self.finish(with: .success(value))
                    case let .failure(.internalFailure(error)):
                      self.finish(with: .failure(.internalFailure(error)))
                    case let .failure(.providedFailure(error)):
                      self.finish(with: .failure(.providedFailure(error)))
                    }
                  }
                newTask.name = "\(name).Produced"
                newTask.qualityOfService = from.qualityOfService
                newTask.queuePriority = from.queuePriority
                if let newTask = newTask as? TaskQueueContainable, let from = from as? TaskQueueContainable {
                  newTask.innerQueue.underlyingQueue = from.innerQueue.underlyingQueue
                }
                task.produce(new: newTask)
              } catch {
                self.finish(with: .failure(.providedFailure(error)))
              }
            }
            
            finish(.success)
        }
      
      addTask(transform)
    }
  }
}
