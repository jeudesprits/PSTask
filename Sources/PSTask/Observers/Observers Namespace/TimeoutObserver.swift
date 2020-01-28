//
//  TimeoutObserver.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/19/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Observers {
  
  public struct Timeout {
    
    public let timeout: TimeInterval
    
    // MARK: -
    
    public init(timeout: TimeInterval) { self.timeout = timeout }
  }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Observers.Timeout: Observer {
  
  public func taskDidStart<T: ProducerTaskProtocol>(_ task: T) {
    // When the operation starts, queue up a block to cause it to time out.
    DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
      // Cancel the operation if it hasn't finished and hasn't already been cancelled.
      if !task.isFinished && !task.isCancelled { task.cancel() }
    }
  }
}
