//
//  AssertNoFailure.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 2/3/20.
//

import Foundation

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension Tasks {
  
  public final class AssertNoFailure<Output, Failure: Error>: NonFailGroupProducerTask<Output> {
    
    public init(
      _ prefix: String = "",
      file: StaticString = #file,
      line: UInt = #line,
      from: ProducerTask<Output, Failure>
    ) {
      let name = String(describing: Self.self)
      
      let assert =
        NonFailBlockProducerTask<Output>(
          name: "\(name).Assert",
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
            finish(.success(value))
          case let .failure(error):
            fatalError("\(prefix)\(error)", file: file, line: line)
          }
        }.addDependency(from)
      
      super.init(
        name: name,
        qos: from.qualityOfService,
        priority: from.queuePriority,
        underlyingQueue: (from as? TaskQueueContainable)?.innerQueue.underlyingQueue,
        tasks: (from, assert),
        produced: assert
      )
    }
  }
}
