//
//  Observer.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/2/20.
//

import Foundation

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public protocol Observer {
  
  func taskDidStart<T: ProducerTaskProtocol>(_ task: T)
  
  func task<T1: ProducerTaskProtocol, T2: ProducerTaskProtocol>(_ task: T1, didProduce newTask: T2)
  
  func taskDidCancel<T: ProducerTaskProtocol>(_ task: T)
  
  func taskDidFinish<T: ProducerTaskProtocol>(_ task: T)
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension Observer {
  
  public func taskDidStart<T: ProducerTaskProtocol>(_ task: T) {}
  
  public func task<T1: ProducerTaskProtocol, T2: ProducerTaskProtocol>(_ task: T1, didProduce newTask: T2) {}
  
  public func taskDidCancel<T: ProducerTaskProtocol>(_ task: T) {}
  
  public func taskDidFinish<T: ProducerTaskProtocol>(_ task: T) {}
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public enum Observers {}
