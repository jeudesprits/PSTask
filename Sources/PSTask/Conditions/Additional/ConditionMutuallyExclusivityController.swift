//
//  ConditionMutuallyExclusivityController.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 2/11/20.
//

import Foundation

internal final class _ConditionMutuallyExclusivityController {
  
  internal static let shared = _ConditionMutuallyExclusivityController()
  
  // MARK: -
  
  private let manageQueue =
    DispatchQueue(label: "com.pstask.condition-mutually-exclusivity-controller.manage", qos: .userInitiated)
  
  // MARK: -
  
  private var operations = [String: [Operation]]()
  
  // MARK: -
  
  private init() {}
}

extension _ConditionMutuallyExclusivityController {
  
  internal func add(_ operation: Operation, forCategories categories: [String]) {
    func addingManage(with operation: Operation, forCategory category: String) {
      var operationsWithThisCategory = self.operations[category] ?? []
      if let last = operationsWithThisCategory.last {
        operation.addDependency(last)
        
      }
      operationsWithThisCategory.append(operation)
      self.operations[category] = operationsWithThisCategory
    }
    
    self.manageQueue.sync { categories.forEach { addingManage(with: operation, forCategory: $0) } }
  }
  
  internal func remove(_ operation: Operation, forCategories categories: [String]) {
    func removeManage(with operation: Operation, forCategory category: String) {
      let matchingOperations = self.operations[category]
      if var operationsWithThisCategory = matchingOperations,
         let index = operationsWithThisCategory.firstIndex(of: operation)
      {
        operationsWithThisCategory.remove(at: index)
        self.operations[category] = operationsWithThisCategory
      }
    }
    
    self.manageQueue.async { categories.forEach { removeManage(with: operation, forCategory: $0) } }
  }
}

// MARK: -

internal struct _ConditionMutuallyExclusivityObserver {
  
  private let categories: [String]
  
  // MARK: -
  
  internal init(categories: [String]) { self.categories = categories }
}

extension _ConditionMutuallyExclusivityObserver: Observer {
  
  internal func taskDidFinish<T: ProducerTaskProtocol>(_ task: T) {
    _ConditionMutuallyExclusivityController.shared.remove(task, forCategories: self.categories)
  }
}
