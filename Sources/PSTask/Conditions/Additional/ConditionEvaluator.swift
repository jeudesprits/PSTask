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
  
  internal static func evaluate<T: ProducerTaskProtocol>(
    _ conditions: [AnyCondition],
    for task: T,
    completion: @escaping ([Result<Void, Error>]) -> Void
  ) {
    let group = DispatchGroup()

    var results = [Result<Void, Error>]()
    results.reserveCapacity(conditions.count)
    
    conditions
      .forEach {
        group.enter()
        $0.evaluate(for: task) { (result) in
          Self.lock.sync { results.append(result) }
          group.leave()
        }
      }
    
    group.notify(queue: .global(qos: .userInitiated)) { completion(results) }
  }
}
