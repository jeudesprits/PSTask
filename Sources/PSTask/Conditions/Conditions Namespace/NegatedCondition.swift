//
//  NegatedCondition.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/17/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Conditions {
  
  public struct Negated<Condition: Condition> {
    
    public typealias Failure = Error
    
    // MARK: -
    
    public let condition: Condition
    
    // MARK: -
    
    public init(condition: Condition) { self.condition = condition }
  }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Conditions.Negated {
  
  public enum Error: Swift.Error { case reverseFailure }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Conditions.Negated: Condition {
  
  public func dependency<T: ProducerTaskProtocol>(for task: T) -> Operation? { condition.dependency(for: task) }
  
  public func evaluate<T: ProducerTaskProtocol>(for task: T, completion: @escaping (Result<Void, Failure>) -> Void)  {
    condition.evaluate(for: task) { (result) in
      if case .success = result {
        completion(.failure(.reverseFailure))
      } else {
        completion(.success)
      }
    }
  }
}
