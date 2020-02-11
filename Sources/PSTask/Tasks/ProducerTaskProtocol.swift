//
//  ProducerTaskProtocol.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/19/20.
//

import Foundation

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public enum ProducerTaskSeparateError<Failure: Error>: Error {
  
  case `internal`(Error)
  case provided(Failure)
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public protocol ProducerTaskProtocol: Operation {
  
  associatedtype Output
  associatedtype Failure: Error
  
  // MARK: -
  
  typealias Produced = Result<Output, ProducerTaskSeparateError<Failure>>

  var produced: Produced? { get }
  
  // MARK: -
  
  var mutuallyExclusiveConditions: [String: AnyCondition] { get }
  
  var conditions: [AnyCondition] { get }
  
  @discardableResult
  func addCondition<C: Condition>(_ condition: C) -> Self
  
  // MARK: -
  
  var observers: [Observer] { get }
   
  @discardableResult
  func addObserver<O: Observer>(_ observer: O) -> Self
  
  // MARK: -
  
  @discardableResult
  func addDependency<T: ProducerTaskProtocol>(_ task: T) -> Self
  
  @discardableResult
  func removeDependency<T: ProducerTaskProtocol>(_ task: T) -> Self
  
  // MARK: -
  
  func willEnqueue()
  
  // MARK: -
  
  func execute()
  
  // MARK: -
  
  func finish(with produced: Produced)
  
  func finished(with produced: Produced)
  
  // MARK: -
  
  func produce<T: ProducerTaskProtocol>(new task: T)
  
  // MARK: -
  
  @discardableResult
  func recieve(on queue: DispatchQueue) -> Self
  
  @discardableResult
  func recieve(completion: @escaping (Produced) -> Void) -> Self
  
  // MARK: -
  
  @discardableResult
  func assign<Root>(to keyPath: ReferenceWritableKeyPath<Root, Output>, on object: Root) -> Self
}

// MARK: -

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public enum Tasks {}
