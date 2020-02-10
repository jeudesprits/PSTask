//
//  EncodeTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 2/5/20.
//

import Foundation

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension Tasks {

  public final class Encode<Output: Encodable, Failure: Error>: GroupProducerTask<Data, Error> {
    
    public init(
      from: ProducerTask<Output, Failure>,
      encoder: JSONEncoder
    ) {
      let name = String(describing: Self.self)
      
      let decode =
        BlockProducerTask<Data, Error>(
          name: "\(name).Decode",
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
              finish(.success(try encoder.encode(value)))
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
        tasks: (from, decode),
        produced: decode
      )
    }
  }
}
