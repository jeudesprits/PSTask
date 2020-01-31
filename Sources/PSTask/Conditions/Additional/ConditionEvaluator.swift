//
//  ConditionEvaluator.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/18/20.
//

import Foundation
import PSLock

internal struct _ConditionEvaluator {
  
  private static let lock = UnfairLock()
  
  // MARK: -
  
  static func evaluate<T: ProducerTaskProtocol>(_ conditions: [AnyTaskCondition], for task: T, completion: @escaping ([Result<Void, Error>]) -> Void) {
    let group = DispatchGroup()

    var results = [Result<Void, Error>]()
    
    for condition in conditions {
      group.enter()
      condition.evaluate(for: task) { (result) in
        lock.sync { results.append(result) }
        group.leave()
      }
    }
    
    group.notify(queue: .global(qos: .userInitiated)) { completion(results) }
  }
}
