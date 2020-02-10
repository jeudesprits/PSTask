//
//  SilentCondition.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/17/20.
//

import Foundation

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension Conditions {
  
  public struct Silent<Base: Condition> {
    
    public typealias Failure = Base.Failure
    
    // MARK: -
    
    public let condition: Base
    
    // MARK: -
    
    public init(condition: Base) { self.condition = condition }
  }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension Conditions.Silent: Condition {
    
  public func dependency<T: ProducerTaskProtocol>(for task: T) -> NonFailTask? { nil }
  
  public func evaluate<T: ProducerTaskProtocol>(for task: T, completion: @escaping (Result<Void, Failure>) -> Void) {
    self.condition.evaluate(for: task, completion: completion)
  }
}
