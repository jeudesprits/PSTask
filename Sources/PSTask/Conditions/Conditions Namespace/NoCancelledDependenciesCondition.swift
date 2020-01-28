//
//  NoCancelledDependenciesCondition.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/17/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Conditions {
  
  public struct NoCancelledDependencies: TaskCondition {
    
    public typealias Failure = Error
    
    // MARK: -
    
    public func dependency<T: ProducerTaskProtocol>(for task: T) -> Operation? { nil }
    
    public func evaluate<T: ProducerTaskProtocol>(for task: T, completion: @escaping (Result<Void, Failure>) -> Void) {
      task.dependencies.allSatisfy { !$0.isCancelled }
        ? completion(.success(()))
        : completion(.failure(.haveCancelledFailure))
    }
  }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Conditions.NoCancelledDependencies {
  
  public enum Error: Swift.Error { case haveCancelledFailure }
}
