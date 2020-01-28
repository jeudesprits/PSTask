//
//  ConditionEvaluator.swift
//  PSOperation
//
//  Created by Ruslan Lutfullin on 1/18/20.
//

import Foundation
import PSLock

internal struct _ConditionEvaluator {
  
  private static let lock = PSUnfairLock()
  
  
  static func evaluate<O: ProducerOperationProtocol>(_ conditions: [AnyTaskCondition], for operation: O, completion: @escaping ([Result<Void, Error>]) -> Void) {
    let group = DispatchGroup()

    var results = [Result<Void, Error>]()
    
    for condition in conditions {
      group.enter()
      condition.evaluate(for: operation) { (result) in
        lock.sync { results.append(result) }
        group.leave()
      }
    }
    
    group.notify(queue: .global(qos: .userInitiated)) { completion(results) }
  }
}
