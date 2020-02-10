//
//  NegatedCondition.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/17/20.
//

import Foundation

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension Conditions {
  
  public struct Negated<Base: Condition> {
    
    public typealias Failure = Error
    
    // MARK: -
    
    public let condition: Base
    
    // MARK: -
    
    public init(_ condition: Base) { self.condition = condition }
  }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension Conditions.Negated {
  
  public enum Error: Swift.Error { case reverseFailure }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension Conditions.Negated: Condition {
  
  public func dependency<T: ProducerTaskProtocol>(for task: T) -> NonFailTask? {
    self.condition.dependency(for: task)
  }
  
  public func evaluate<T: ProducerTaskProtocol>(for task: T, completion: @escaping (Result<Void, Failure>) -> Void)  {
    self.condition.evaluate(for: task) { (result) in
      if case .success = result {
        completion(.failure(.reverseFailure))
      } else {
        completion(.success)
      }
    }
  }
}
