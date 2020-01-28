//
//  NegatedCondition.swift
//  PSOperation
//
//  Created by Ruslan Lutfullin on 1/17/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Conditions {
  
  public struct Negated<Condition: TaskCondition> {
    
    public typealias Failure = Error
    
    
    private let condition: Condition
    
    
    public init(condition: Condition) { self.condition = condition }
  }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Conditions.Negated {
  
  public enum Error: Swift.Error { case reverseFailure }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Conditions.Negated: TaskCondition {
  
  public func dependency<O: ProducerOperationProtocol>(for operation: O) -> Operation? {
    condition.dependency(for: operation)
  }
  
  public func evaluate<O: ProducerOperationProtocol>(for operation: O, completion: @escaping (Result<Void, Failure>) -> Void)  {
    condition.evaluate(for: operation) { (result) in
      if case .success = result {
        completion(.failure(.reverseFailure))
      } else {
        completion(.success(()))
      }
    }
  }
}
