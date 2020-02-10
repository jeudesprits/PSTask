//
//  NoCancelledDependenciesCondition.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/17/20.
//

import Foundation

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension Conditions {
  
  public struct NoCancelledDependencies: Condition {
    
    public typealias Failure = Error
    
    // MARK: -
    
    public func dependency<T: ProducerTaskProtocol>(for task: T) -> NonFailTask? { nil }
    
    public func evaluate<T: ProducerTaskProtocol>(for task: T, completion: @escaping (Result<Void, Failure>) -> Void) {
      task.dependencies.allSatisfy { !$0.isCancelled }
        ? completion(.success)
        : completion(.failure(.haveCancelledFailure))
    }
  }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension Conditions.NoCancelledDependencies {
  
  public enum Error: Swift.Error { case haveCancelledFailure }
}
