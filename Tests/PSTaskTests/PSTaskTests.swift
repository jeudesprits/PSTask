import XCTest
@testable import PSTask

extension String: Error {}

final class PSTaskTests: XCTestCase {
  
  func testMapTask() {
    let taskQueue: TaskQueue = .init(name: "Test", qos: .userInitiated)
    
    let expec = XCTestExpectation()
    
    let task = BlockProducerOperation<Int, String> { (finishing) in
      finishing(.success(10))
    }.tryMap { (value) -> Int in
      if value == 21 {
        return 12
      } else {
        throw "Fuck... this is not '21'"
      }
    }.map {
      $0 + $0
    }.recieve {
      print($0)
      expec.fulfill()
    }
    
    taskQueue.addTask(task)
    
    wait(for: [expec], timeout: 3)
  }
  
  static var allTests = [
    ("testMapTask", testMapTask),
  ]
}
