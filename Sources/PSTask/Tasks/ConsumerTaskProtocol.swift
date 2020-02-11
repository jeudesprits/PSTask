//
//  ConsumerTaskProtocol.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/26/20.
//

import Foundation

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public protocol ConsumerProducerTaskProtocol: ProducerTaskProtocol {
  
  associatedtype Input
  
  // MARK: -
  
  typealias ProducingTask = ProducerTask<Input, Failure>
  
  var producing: ProducingTask { get }
  
  // MARK: -
  
  typealias Consumed = ProducingTask.Produced
  
  var consumed: Consumed? { get }
  
  // MARK: -
  
  func execute(with consumed: Consumed)
}
