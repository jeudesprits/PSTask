//
//  ProducerTaskProtocol.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/19/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public enum ProducerTaskProtocolError<Failure: Error>: Error {
  
  case internalFailure(Error)
  case providedFailure(Failure)
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public protocol ProducerTaskProtocol: Operation {
  
  associatedtype Output
  associatedtype Failure: Error
  
  // MARK: -
  
  typealias Produced = Result<Output, ProducerTaskProtocolError<Failure>>

  var produced: Produced? { get }
  
  // MARK: -
  
  var conditions: [AnyTaskCondition] { get }
  
  @discardableResult
  func addCondition<C: TaskCondition>(_ condition: C) -> Self
  
  // MARK: -
  
  var observers: [Observer] { get }
   
  @discardableResult
  func addObserver<O: Observer>(_ observer: O) -> Self
  
  // MARK: -
  
  @discardableResult
  func addDependency<T: ProducerTaskProtocol>(_ task: T) -> Self
  
  @discardableResult
  func addDependencies<T: ProducerTaskProtocol>(_ tasks: [T]) -> Self

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
  func recieve(completion: @escaping (Produced) -> Void) -> Self
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public enum Tasks {}
