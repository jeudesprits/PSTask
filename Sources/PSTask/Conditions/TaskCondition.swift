//
//  OperationCondition.swift
//  PSOperation
//
//  Created by Ruslan Lutfullin on 1/2/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public protocol TaskCondition {
  
  associatedtype Failure: Error
  
  
  func dependency<T: ProducerTaskProtocol>(for task: T) -> Operation?
  
  func evaluate<T: ProducerTaskProtocol>(for task: T, completion: @escaping (Result<Void, Failure>) -> Void)
}

@usableFromInline
internal class _AnyTaskConditionBaseBox<Failure: Error>: TaskCondition {

  @inlinable
  internal func dependency<T: ProducerTaskProtocol>(for task: T) -> Operation? {
    _abstract()
  }

  @inlinable
  internal func evaluate<T: ProducerTaskProtocol>(for task: T, completion: @escaping (Result<Void, Failure>) -> Void) {
    _abstract()
  }


  @inlinable
  internal init() {}

  @inlinable
  deinit {}
}

@usableFromInline
internal final class _AnyTaskConditionBox<Base: TaskCondition>: _AnyTaskConditionBaseBox<Error> {

  @usableFromInline
  internal typealias Failure = Error
  
  
  @inlinable
  internal override func dependency<T: ProducerTaskProtocol>(for task: T) -> Operation? {
    base.dependency(for: task)
  }

  @inlinable
  internal override func evaluate<T: ProducerTaskProtocol>(for task: T, completion: @escaping (Result<Void, Failure>) -> Void) {
    let newCompletion: (Result<Void, Base.Failure>) -> Void = { completion($0.mapError { $0 as Failure }) }
    base.evaluate(for: task, completion: newCompletion)
  }


  @usableFromInline
  internal let base: Base


  @inlinable
  internal init(_ base: Base) { self.base = base }

  @inlinable
  deinit {}
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct AnyTaskCondition: TaskCondition {

  public typealias Failure = Error


  @inlinable
  public func dependency<T: ProducerTaskProtocol>(for task: T) -> Operation? {
    box.dependency(for: task)
  }

  @inlinable
  public func evaluate<T: ProducerTaskProtocol>(for task: T, completion: @escaping (Result<Void, Failure>) -> Void) {
    box.evaluate(for: task, completion: completion)
  }


  @usableFromInline
  internal let box: _AnyTaskConditionBaseBox<Failure>


  @inlinable
  public init<C: TaskCondition>(_ base: C) { box = _AnyTaskConditionBox(base) }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public enum Conditions {}
