import XCTest
@testable import PSTask

extension String: Error {}
enum ZXC: Error { case oops }

final class PSTaskTests: XCTestCase {
  
  func testMapTask() {
    let taskQueue: TaskQueue = .init(name: "Test.TaskQueue")
    
    let expec = XCTestExpectation()

    let t =
      BlockProducerTask<Int, String> { (_, finish) in
        finish(.success(1))
      }.map {
        $0 + $0
      }.map {
        $0 * $0
      }.tryMap { (val) -> String in
        guard val == 4 else { throw ZXC.oops }
        return "\(val)"
      }.flatMap { (val) -> BlockProducerTask<String, Error> in
        BlockProducerTask { (_, finish) in
          finish(.success(val + val))
        }
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
