//
//  SilentCondition.swift
//  PSOperation
//
//  Created by Ruslan Lutfullin on 1/17/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Conditions {
  
  public struct Silent<Condition: TaskCondition> {
    
    public typealias Failure = Condition.Failure
    
    
    private let condition: Condition
    
    
    public init(condition: Condition) { self.condition = condition }
  }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Conditions.Silent: TaskCondition {
    
  public func dependency<O: ProducerOperationProtocol>(for operation: O) -> Operation? { nil }
  
  public func evaluate<O: ProducerOperationProtocol>(for operation: O, completion: @escaping (Result<Void, Failure>) -> Void) {
    condition.evaluate(for: operation, completion: completion)
  }
}
