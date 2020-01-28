//
//  PSExclusivityController.swift
//  PSOperation
//
//  Created by Ruslan Lutfullin on 1/4/20.
//

import Foundation

// TODO: - Мб. можно обойтись лишь `OperationQueue.addBarrierBlock(_:)` ?
public final class PSExclusivityController {
  
  public static let shared = PSExclusivityController()
  
  private let serialInternalQueue =
    DispatchQueue(label: "PSOperation.PSExclusivityController.Internal", target: .global(qos: .userInitiated))
  
  private var operations = [String: [Operation]]()
  
  private init() { }
}

public extension PSExclusivityController {
  
  func add(_ operation: Operation, categories: [String]) {
    // This needs to be a synchronous operation.
    // If this were async, then we might not get around to adding dependencies
    // until after the operation had already begun, which would be incorrect.
    serialInternalQueue.sync { for category in categories { self.noqueueAdd(operation, category: category) } }
  }
  
  func remove(_ operation: Operation, categories: [String]) {
    serialInternalQueue.async { for category in categories { self.noqueueRemove(operation, category: category) } }
  }
}

private extension PSExclusivityController {
  
  func noqueueAdd(_ operation: Operation, category: String) {
    var operationsWithThisCategory = operations[category] ?? []
    if let last = operationsWithThisCategory.last { operation.addDependency(last) }
    operationsWithThisCategory.append(operation)
    operations[category] = operationsWithThisCategory
  }
  
  func noqueueRemove(_ operation: Operation, category: String) {
    if var operationsWithThisCategory = operations[category],
       let index = operationsWithThisCategory.firstIndex(of: operation)
    {
      operationsWithThisCategory.remove(at: index)
      operations[category] = operationsWithThisCategory
    }
  }
}
