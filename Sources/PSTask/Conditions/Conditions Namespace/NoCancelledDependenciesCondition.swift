//
//  NoCancelledDependenciesCondition.swift
//  PSOperation
//
//  Created by Ruslan Lutfullin on 1/17/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Conditions {
  
  public struct NoCancelledDependencies: TaskCondition {
    
    public typealias Failure = Error
    
    
    public func dependency<O: ProducerOperationProtocol>(for operation: O) -> Operation? { nil }
    
    public func evaluate<O: ProducerOperationProtocol>(for operation: O, completion: @escaping (Result<Void, Failure>) -> Void) {
      operation.dependencies.allSatisfy { !$0.isCancelled }
        ? completion(.success(()))
        : completion(.failure(.haveCancelledFailure))
    }
  }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Conditions.NoCancelledDependencies {
  
  public enum Error: Swift.Error { case haveCancelledFailure }
}
