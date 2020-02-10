//
//  SilentCondition.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/17/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Conditions {
  
  public struct Silent<Condition: Condition> {
    
    public typealias Failure = Condition.Failure
    
    // MARK: -
    
    public let condition: Condition
    
    // MARK: -
    
    public init(condition: Condition) { self.condition = condition }
  }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Conditions.Silent: Condition {
    
  public func dependency<T: ProducerTaskProtocol>(for task: T) -> Operation? { nil }
  
  public func evaluate<T: ProducerTaskProtocol>(for task: T, completion: @escaping (Result<Void, Failure>) -> Void) {
    condition.evaluate(for: task, completion: completion)
  }
}
