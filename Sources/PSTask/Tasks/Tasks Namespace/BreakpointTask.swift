//
//  BreakpointTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 2/5/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Tasks {

  public final class BreakpointTask<Output, Failure: Error>: GroupProducerTask<Output, Failure> {
    
    public init(
      from: ProducerTask<Output, Failure>,
      receiveOutput: ((Output) -> Bool)? = nil,
      receiveFailure: ((Failure) -> Bool)? = nil
    ) {
      let name = String(describing: Self.self)
      
      let trap =
        BlockConsumerProducerTask<Output, Output, Failure>(
          name: "\(name).Transform",
          qos: from.qualityOfService,
          priority: from.queuePriority,
          producing: from
        ) { (task, consumed, finish) in
          guard !task.isCancelled else {
            finish(.failure(.internalFailure(ProducerTaskError.executionFailure)))
            return
          }
          
          if receiveOutput == nil, receiveFailure == nil, case .failure = consumed {
            #if DEBUG
            raise(SIGTRAP)
            #endif
          }
          
          switch consumed {
          case let .success(value):
            if let receiveOutput = receiveOutput?(value), receiveOutput {
              #if DEBUG
              raise(SIGTRAP)
              #endif
            }
            finish(.success(value))
          
          case let .failure(.internalFailure(error)):
            finish(.failure(.internalFailure(error)))
          
          case let .failure(.providedFailure(error)):
            if let receiveFailure = receiveFailure?(error), receiveFailure {
              #if DEBUG
              raise(SIGTRAP)
              #endif
            }
            finish(.failure(.providedFailure(error)))
          }
        }
      
      super.init(
        name: name,
        qos: from.qualityOfService,
        priority: from.queuePriority,
        underlyingQueue: (from as? TaskQueueContainable)?.innerQueue.underlyingQueue,
        tasks: (from, trap),
        produced: trap
      )
    }
  }
}
