//
//  EmptyCondition.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/18/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Conditions {

  public struct Empty: TaskCondition {
    
    public typealias Failure = Never
     
    // MARK: -
    
    public func dependency<T: ProducerTaskProtocol>(for task: T) -> Operation? { nil }
    
    public func evaluate<T: ProducerTaskProtocol>(for task: T, completion: @escaping (Result<Void, Failure>) -> Void) {
      completion(.success(()))
    }
  }
}
