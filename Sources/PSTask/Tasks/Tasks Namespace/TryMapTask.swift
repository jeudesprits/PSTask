//
//  TryMapTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/29/20.
//

import Foundation

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension Tasks {

  public final class TryMap<Output, NewOutput, Failure: Error>: GroupProducerTask<NewOutput, Error> {
    
    public init(
      from: ProducerTask<Output, Failure>,
      transform: @escaping (Output) throws -> NewOutput
    ) {
      let name = String(describing: Self.self)
      
      let transform =
        BlockProducerTask<NewOutput, Error>(
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
          
          switch consumed {
          case let .success(value):
            do {
              finish(.success(try transform(value)))
            } catch {
              finish(.failure(.providedFailure(error)))
            }
          case let .failure(.internalFailure(error)):
            finish(.failure(.internalFailure(error)))
          case let .failure(.providedFailure(error)):
            finish(.failure(.providedFailure(error)))
          }
      }.addDependency(from)
      
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
