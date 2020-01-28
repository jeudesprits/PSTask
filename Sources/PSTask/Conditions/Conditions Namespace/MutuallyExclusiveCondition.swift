//
//  MutuallyExclusiveCondition.swift
//  PSOperation
//
//  Created by Ruslan Lutfullin on 1/17/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Conditions {
  
  public struct MutuallyExclusive<T>: TaskCondition {
    
    public typealias Failure = Never
    
    
    public func dependency<O: ProducerOperationProtocol>(for operation: O) -> Operation? {
      nil
    }
    
    public func evaluate<O: ProducerOperationProtocol>(for operation: O, completion: @escaping (Result<Void, Failure>) -> Void) {
      completion(.success(()))
    }
  }
}
