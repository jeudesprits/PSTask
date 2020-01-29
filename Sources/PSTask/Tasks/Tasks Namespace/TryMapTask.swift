//
//  TryMapTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/29/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Tasks {

  public final class TryMap<Input, Output, Failure: Error>: ConsumerProducerTask<Input, Output, Failure> {
    
    private let transform: (Input) throws -> Output
    
    // MARK: -
        
    public override func execute(with consumed: Consumed) {
      guard !isCancelled else {
        finish(with: .failure(.internalFailure(ProducerTaskError.executionFailure)))
        return
      }
      
      if case let .success(value) = consumed {
        do {
          let newValue = try transform(value)
          finish(with: .success(newValue))
        } catch {
          finish(with: .failure(.internalFailure(error)))
        }
      } else if case let .failure(error) = consumed {
        finish(with: .failure(error))
      }
    }
    
    // MARK: -
    
    public init(
      name: String? = nil,
      qos: QualityOfService = .default,
      priority: Operation.QueuePriority = .normal,
      producing: ProducingTask,
      transform: @escaping (Input) throws -> Output
    ) {
      self.transform = transform
      super.init(name: name, qos: qos, priority: priority, producing: producing)
    }
  }
}
