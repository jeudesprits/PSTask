//
//  TryMapTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/29/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Tasks {

  public final class TryMap<Input, Output, Failure: Error>: GroupProducerTask<Output, Error> {
    
    public init(
      from: ProducerTask<Input, Failure>,
      transform: @escaping (Input) throws -> Output
    ) {
      let transform =
        BlockProducerTask<Output, Error> { (task, finish) in
          guard !task.isCancelled else {
            finish(.failure(.internalFailure(ProducerTaskError.executionFailure)))
            return
          }

          guard let consumed = from.produced else {
            finish(.failure(.internalFailure(ConsumerProducerTaskError.producingFailure)))
            return
          }
          
          if case let .success(value) = consumed {
            do {
              let newValue = try transform(value)
              finish(.success(newValue))
            } catch {
              finish(.failure(.providedFailure(error)))
            }
          } else if case let .failure(error) = consumed {
            finish(.failure(.providedFailure(error)))
          }
      }.addDependency(from)
      
      
      super.init(tasks: (from, transform), produced: transform)
    }
  }
}
