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
            finish(.failure(.internal(ProducerTaskError.executionFailure)))
            return
          }
          
          guard let consumed = from.produced else {
            finish(.failure(.internal(ConsumerProducerTaskError.producingFailure)))
            return
          }
          
          switch consumed {
          case let .success(value):
            do {
              finish(.success(try transform(value)))
            } catch {
              finish(.failure(.provided(error)))
            }
          case let .failure(.internal(error)):
            finish(.failure(.internal(error)))
          case let .failure(.provided(error)):
            finish(.failure(.provided(error)))
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
