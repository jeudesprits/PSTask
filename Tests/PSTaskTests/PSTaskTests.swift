import XCTest
@testable import PSTask

extension String: Error {}
enum ZXC: Error { case oops }

final class PSTaskTests: XCTestCase {
  
  func testMapTask() {
    let taskQueue = TaskQueue()
    
    let expec = XCTestExpectation()
    
    let t =
      BlockProducerTask<Int?, String> { (_, finish) in
        finish(.success(nil))
      }.replaceNil(with: 21).mapError { _ in
        ZXC.oops
      }.recieve {
        print($0)
        expec.fulfill()
    }
    
    taskQueue.addTask(t)
    
    wait(for: [expec], timeout: 10)
  }
  
  static var allTests = [
    ("testMapTask", testMapTask),
  ]
}
