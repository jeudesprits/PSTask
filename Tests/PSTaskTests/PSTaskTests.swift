import XCTest
@testable import PSTask

extension String: Error {}

final class PSTaskTests: XCTestCase {
  
  func testMapTask() {
    let taskQueue: TaskQueue = .init(name: "Test", qos: .userInitiated)
    
    let expec = XCTestExpectation()
    
    let t1 = BlockProducerTask<Int, Never>.init { (finishing) in
      finishing(.success(21))
    }
    let t2 = BlockConsumerProducerTask<Int, Int, Never>.init(producing: t1) { (consumed, finishing) in
      finishing(.success(21))
    }
    
    let g = GroupProducerTask<Int, Never>(tasks: (t1, t2))
    
   // wait(for: [expec], timeout: 3)
  }
  
  static var allTests = [
    ("testMapTask", testMapTask),
  ]
}
