import XCTest
@testable import PSTask

extension String: Error {}

final class PSTaskTests: XCTestCase {
  
  func testMapTask() {
    let taskQueue: TaskQueue = .init(name: "Test.TaskQueue", qos: .userInitiated)
    
    let expec = XCTestExpectation()
    
    let t = BlockProducerTask<Int, String> { (finishing) in
      finishing(.failure(.providedFailure("...")))
    }.map {
      $0 + $0
    }.map {
      $0 * $0
    }.recieve {
      print($0) // 4
      expec.fulfill()
    }
    
    taskQueue.addTask(t)
    
    wait(for: [expec], timeout: 10)
  }
  
  static var allTests = [
    ("testMapTask", testMapTask),
  ]
}
