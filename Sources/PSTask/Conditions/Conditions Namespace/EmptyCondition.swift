//
//  EmptyCondition.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/18/20.
//

import Foundation

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension Conditions {

  public struct Empty: Condition {
    
    public typealias Failure = Never
     
    // MARK: -
    
    public func dependency<T: ProducerTaskProtocol>(for task: T) -> NonFailTask? { nil }
    
    public func evaluate<T: ProducerTaskProtocol>(for task: T, completion: @escaping (Result<Void, Failure>) -> Void) {
      completion(.success(()))
    }
  }
}
