//
//  TasksNamespaceTests.swift
//  PSTaskTests
//
//  Created by Ruslan Lutfullin on 2/4/20.
//

import XCTest
@testable import PSTask

extension String: Error {}

final class TasksNamespaceTests: XCTestCase {

  private let queue = TaskQueue(name: "com.pstask.tasks-namespace-tests", qos: .userInitiated)
  
  // MARK: -
  
  func testMapTask() {
    let expec1 = XCTestExpectation()
    
    let task1 =
      NonFailBlockProducerTask<Int>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (task, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.success(21))
      }.map {
        "\($0)"
      }.recieve {
        switch $0 {
        case let .success(value):
          XCTAssertEqual(value, "21")
          expec1.fulfill()
        case .failure:
          XCTFail()
        }
      }
    
    let expec2 = XCTestExpectation()
    
    let task2 =
       BlockProducerTask<Int, String>(
         qos: .userInitiated,
         priority: .veryHigh
       ) { (task, finish) in
         Thread.sleep(forTimeInterval: 2)
         finish(.failure(.provided("Ooops")))
       }.map {
         "\($0)"
       }.recieve {
         switch $0 {
         case .success:
           XCTFail()
         case .failure:
           XCTAssertTrue(true)
           expec2.fulfill()
         }
       }
    
    self.queue.addTask(task1)
    self.queue.addTask(task2)
    
    self.wait(for: [expec1, expec2], timeout: 3)
  }
  
  func testTryMapTask() {
    let expec1 = XCTestExpectation()
    
    let task1 =
      NonFailBlockProducerTask<Int>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (task, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.success(21))
      }.tryMap {_ in
        throw "Ooops"
      }.recieve {
        switch $0 {
        case let .failure(.provided(error as String)):
          XCTAssertEqual(error, "Ooops")
          expec1.fulfill()
        default:
          XCTFail()
        }
      }
    
    let expec2 = XCTestExpectation()
    
    let task2 =
      NonFailBlockProducerTask<Int>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (task, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.success(21))
      }.tryMap {
        "\($0)"
      }.recieve {
        switch $0 {
        case let .success(value):
          XCTAssertEqual(value, "21")
          expec2.fulfill()
        default:
          XCTFail()
        }
    }
    
    self.queue.addTask(task1)
    self.queue.addTask(task2)
    
    self.wait(for: [expec1, expec2], timeout: 3)
  }
  
  func testFlatMapTask() {
    let expec1 = XCTestExpectation()
    
    let task1 =
      NonFailBlockProducerTask<Int>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (task, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.success(21))
      }.flatMap { (value) in
        NonFailBlockProducerTask<Int> { (_, finish) in
          Thread.sleep(forTimeInterval: 2)
          finish(.success(value + value))
        }
      }.recieve {
        switch $0 {
        case let .success(value):
          XCTAssertEqual(value, 42)
          expec1.fulfill()
        default:
          XCTFail()
        }
      }
    
    let expec2 = XCTestExpectation()
    
    let task2 =
      BlockProducerTask<Int, String>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (task, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.failure(.provided("Ooops")))
      }.flatMap { (value) in
        BlockProducerTask<Int, String> { (_, finish) in
          Thread.sleep(forTimeInterval: 2)
          finish(.success(value + value))
        }
      }.recieve {
        switch $0 {
        case let .failure(.provided(error)):
          XCTAssertEqual(error, "Ooops")
          expec2.fulfill()
        default:
          XCTFail()
        }
      }
    
    self.queue.addTask(task1)
    self.queue.addTask(task2)
    
    self.wait(for: [expec1, expec2], timeout: 5)
  }
  
  func testMapErrorTask() {
    enum OoopsError:Error { case ooops(String) }
    
    let expec1 = XCTestExpectation()
    
    let task1 =
      BlockProducerTask<Int, String>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (_, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.failure(.provided("Oopps")))
      }.mapError {
        OoopsError.ooops($0)
      }.recieve {
        switch $0 {
        case let .failure(.provided(.ooops(value))):
          XCTAssertEqual(value, "Oopps")
          expec1.fulfill()
        default:
          XCTFail()
        }
      }
    
    let expec2 = XCTestExpectation()
    
    let task2 =
      BlockProducerTask<Int, String>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (_, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.success(21))
      }.mapError {
        OoopsError.ooops($0)
      }.recieve {
        switch $0 {
        case let .success(value):
          XCTAssertEqual(value, 21)
          expec2.fulfill()
        default:
          XCTFail()
        }
      }
    
    self.queue.addTask(task1)
    self.queue.addTask(task2)
    
    self.wait(for: [expec1, expec2], timeout: 3)
  }
  
  func testSetFailureTypeTask() {
    let expec = XCTestExpectation()
    
    let task =
      NonFailBlockProducerTask<Int>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (_, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.success(21))
      }.setFailureType(to: String.self)
       .flatMap { _ in
          BlockProducerTask<Int, String> { (_, finish) in
            Thread.sleep(forTimeInterval: 2)
            finish(.failure(.provided("Ooops")))
          }
      }.recieve {
        switch $0 {
        case let.failure(.provided(error)):
          XCTAssertEqual(error, "Ooops")
          expec.fulfill()
        default:
          XCTFail()
        }
     }
    
    self.queue.addTask(task)
    
    self.wait(for: [expec], timeout: 5)
  }
  
  func testCompactMapTask() {
    let expec1 = XCTestExpectation()
    
    let task1 =
      NonFailBlockProducerTask<Int>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (task, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.success(21))
      }.compactMap {
        $0 == 21 ? nil : 100
      }.recieve {
        switch $0 {
        case let .failure(.internal(error as ProducerTaskError)):
          XCTAssertEqual(String(describing: error), String(describing: ProducerTaskError.executionFailure))
          expec1.fulfill()
        default:
          XCTFail()
        }
      }
    
    let expec2 = XCTestExpectation()
    
    let task2 =
      NonFailBlockProducerTask<Int>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (task, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.success(21))
      }.compactMap {
        $0 == 21 ? 100 : nil
      }.recieve {
        switch $0 {
        case let .success(value):
          XCTAssertEqual(value, 100)
          expec2.fulfill()
        default:
          XCTFail()
        }
      }
    
    self.queue.addTask(task1)
    self.queue.addTask(task2)
    
    self.wait(for: [expec1, expec2], timeout: 3)
  }
  
  func testTryCompactMapTask() {
    let expec1 = XCTestExpectation()
    
    let task1 =
      NonFailBlockProducerTask<Int>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (task, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.success(21))
      }.tryCompactMap { (value) -> Int? in
        if value == 21 {
          throw "Ooops"
        } else {
          return 100
        }
      }.recieve {
        switch $0 {
        case let .failure(.provided(error as String)):
          XCTAssertEqual(error, "Ooops")
          expec1.fulfill()
        default:
          XCTFail()
        }
      }
    
    let expec2 = XCTestExpectation()
    
    let task2 =
      NonFailBlockProducerTask<Int>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (task, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.success(21))
      }.tryCompactMap {
        $0 == 21 ? nil : 100
      }.recieve {
        switch $0 {
        case let .failure(.internal(error as ProducerTaskError)):
          XCTAssertEqual(String(describing: error), String(describing: ProducerTaskError.executionFailure))
          expec2.fulfill()
        default:
          XCTFail()
        }
      }
    
    self.queue.addTask(task1)
    self.queue.addTask(task2)
    
    self.wait(for: [expec1, expec2], timeout: 3)
  }
  
  func testReplaceEmptyTask() {
    let expec1 = XCTestExpectation()
    
    let task1 =
      BlockTask<String>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (_, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.success)
      }.replaceEmpty {
          100
      }.recieve {
        switch $0 {
        case let .success(value):
          XCTAssertEqual(value, 100)
          expec1.fulfill()
        default:
          XCTFail()
        }
     }
    
    
    let expec2 = XCTestExpectation()
    
    let task2 =
      BlockTask<String>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (_, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.failure(.provided("Ooops")))
      }.replaceEmpty {
          100
      }.recieve {
        switch $0 {
        case let .failure(.provided(error)):
          XCTAssertEqual(error, "Ooops")
          expec2.fulfill()
        default:
          XCTFail()
        }
     }
    
    self.queue.addTask(task1)
    self.queue.addTask(task2)
    
    self.wait(for: [expec1, expec2], timeout: 3)
  }
  
  func testReplaceErrorTask() {
    let expec1 = XCTestExpectation()
    
    let task1 =
      BlockProducerTask<Int, String>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (_, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.failure(.provided("Ooops")))
      }.replaceError { _ in
        21
      }.recieve {
        switch $0 {
        case let .success(value):
          XCTAssertEqual(value, 21)
          expec1.fulfill()
        default:
          XCTFail()
        }
      }
    
    let expec2 = XCTestExpectation()
    
    let task2 =
      BlockProducerTask<Int, String>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (_, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.success(100))
      }.replaceError { _ in
        21
      }.recieve {
        switch $0 {
        case let .success(value):
          XCTAssertEqual(value, 100)
          expec2.fulfill()
        default:
          XCTFail()
        }
      }
    
    self.queue.addTask(task1)
    self.queue.addTask(task2)
    
    self.wait(for: [expec1, expec2], timeout: 3)
  }
  
  func testIgnoreOutputTask() {
    let expec1 = XCTestExpectation()
    
    let task1 =
      BlockProducerTask<Int, String>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (_, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.success(21))
      }.ignoreOutput()
       .recieve {
        switch $0 {
        case .success:
          XCTAssertTrue(true)
          expec1.fulfill()
        default:
          XCTFail()
        }
      }
    
    let expec2 = XCTestExpectation()
    
    let task2 =
      BlockProducerTask<Int, String>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (_, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.failure(.provided("Ooops")))
      }.ignoreOutput()
       .recieve {
          switch $0 {
          case let .failure(.provided(error)):
            XCTAssertEqual(error, "Ooops")
            expec2.fulfill()
          default:
            XCTFail()
          }
      }
    
    self.queue.addTask(task1)
    self.queue.addTask(task2)
    
    self.wait(for: [expec1, expec2], timeout: 3)
  }
  
  func testZipTask() {
    let expec1 = XCTestExpectation()
    
    let task11 =
      BlockProducerTask<Int, String>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (_, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.success(200))
      }
    
    let task12 =
      BlockProducerTask<String, String>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (_, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.success("OK"))
      }
    
    let task1 =
      task11.zip(task12).recieve {
        switch $0 {
        case let .success(value):
          XCTAssertTrue(value == (200, "OK"))
          expec1.fulfill()
        default:
          XCTFail()
        }
      }
    
    
    let expec2 = XCTestExpectation()
    
    let task21 =
      BlockProducerTask<Int, String>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (_, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.failure(.provided("Ooops")))
      }
    
    let task22 =
      BlockProducerTask<String, String>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (_, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.success("OK"))
      }
    
    let task2 =
      task21.zip(task22).recieve {
        switch $0 {
        case let .failure(.provided(error)):
          XCTAssertEqual(error, "Ooops")
          expec2.fulfill()
        default:
          XCTFail()
        }
      }
    
    self.queue.addTask(task1)
    self.queue.addTask(task2)
    
    self.wait(for: [expec1, expec2], timeout: 3)
  }
  
  func testAssertNoFailureTask() {
    let expec = XCTestExpectation()
    
    let task =
      BlockProducerTask<Int, String>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (_, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.success(21))
      }.assertNoFailure().recieve { _ in
        XCTAssertTrue(true)
        expec.fulfill()
      }
    
    self.queue.addTask(task)
    
    self.wait(for: [expec], timeout: 3)
  }
  
  func testCatchTask() {
    let expec1 = XCTestExpectation()
    
    let task1 =
      BlockProducerTask<Int, String>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (task, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.failure(.provided("Ooops")))
      }.catch { _ in
        BlockProducerTask<Int, String> { (_, finish) in
          Thread.sleep(forTimeInterval: 2)
          finish(.success(21))
        }
      }.recieve {
        switch $0 {
        case let .success(value):
          XCTAssertEqual(value, 21)
          expec1.fulfill()
        default:
          XCTFail()
        }
    }
    
    let expec2 = XCTestExpectation()
    
    let task2 =
      BlockProducerTask<Int, String>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (task, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.success(21))
      }.catch { _ in
        BlockProducerTask<Int, String> { (_, finish) in
          Thread.sleep(forTimeInterval: 2)
          finish(.success(100))
        }
      }.recieve {
        switch $0 {
        case let .success(value):
          XCTAssertEqual(value, 21)
          expec2.fulfill()
        default:
          XCTFail()
        }
    }
    
    self.queue.addTask(task1)
    self.queue.addTask(task2)
    
    self.wait(for: [expec1, expec2], timeout: 5)
  }
  
  func testTryCatchTask() {
    let expec1 = XCTestExpectation()
    
    let task1 =
      BlockProducerTask<Int, String>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (task, finish) -> Void in
        Thread.sleep(forTimeInterval: 2)
        finish(.failure(.provided("Ooops")))
      }.tryCatch { (error) -> BlockProducerTask<Int, String> in
        guard error != "Ooops" else { throw "Nooo" }
        return BlockProducerTask { (_, finish) in
          Thread.sleep(forTimeInterval: 2)
          finish(.success(21))
        }
      }.recieve {
        switch $0 {
        case let .failure(.provided(error as String)):
          XCTAssertEqual(error, "Nooo")
          expec1.fulfill()
        default:
          XCTFail()
        }
      }
    
    let expec2 = XCTestExpectation()
    
    let task2 =
      BlockProducerTask<Int, String>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (task, finish) -> Void in
        Thread.sleep(forTimeInterval: 2)
        finish(.failure(.provided("Nooo")))
      }.tryCatch { (error) -> BlockProducerTask<Int, String> in
        guard error != "Ooops" else { throw "Nooo" }
        return BlockProducerTask { (_, finish) in
          Thread.sleep(forTimeInterval: 2)
          finish(.success(21))
        }
      }.recieve {
        switch $0 {
        case let .success(value):
          XCTAssertEqual(value, 21)
          expec2.fulfill()
        default:
          XCTFail()
        }
      }
    
    let expec3 = XCTestExpectation()
    
    let task3 =
      BlockProducerTask<Int, String>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (task, finish) -> Void in
        Thread.sleep(forTimeInterval: 2)
        finish(.success(100))
      }.tryCatch { (error) -> BlockProducerTask<Int, String> in
        guard error != "Ooops" else { throw "Nooo" }
        return BlockProducerTask { (_, finish) in
          Thread.sleep(forTimeInterval: 2)
          finish(.success(21))
        }
      }.recieve {
        switch $0 {
        case let .success(value):
          XCTAssertEqual(value, 100)
          expec3.fulfill()
        default:
          XCTFail()
        }
      }
    
    self.queue.addTask(task1)
    self.queue.addTask(task2)
    self.queue.addTask(task3)

    self.wait(for: [expec1, expec2, expec3], timeout: 5)
  }
  
  func testDecodeTask() {
    struct User: Codable, Equatable { let id: Int; let username: String }
    
    let expec1 = XCTestExpectation()
    
    let task1 =
      BlockProducerTask<Data, String>.init(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (_, finish) in
        Thread.sleep(forTimeInterval: 2)
        let json = """
        {"id":21,"username":"jeudesprits"}
        """
        finish(.success(json.data(using: .utf8)!))
      }.decode(type: User.self, decoder: JSONDecoder())
       .recieve {
          switch $0 {
          case let .success(value):
            XCTAssertEqual(value, User(id: 21, username: "jeudesprits"))
            expec1.fulfill()
          default:
            XCTFail()
          }
      }
    
    
    let expec2 = XCTestExpectation()
    
    let task2 =
      BlockProducerTask<Data, String>.init(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (_, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.failure(.provided("Ooops")))
      }.decode(type: User.self, decoder: JSONDecoder())
       .recieve {
          switch $0 {
          case let .failure(.provided(error as String)):
            XCTAssertEqual(error, "Ooops")
            expec2.fulfill()
          default:
            XCTFail()
          }
      }
    
    self.queue.addTask(task1)
    self.queue.addTask(task2)
    
    self.wait(for: [expec1, expec2], timeout: 3)
  }
  
  func testEncodeTask() {
    struct User: Codable, Equatable { let id: Int; let username: String }
    
    let expec1 = XCTestExpectation()
    
    let task1 =
      BlockProducerTask<User, String>.init(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (_, finish) in
        Thread.sleep(forTimeInterval: 2)

        finish(.success(User(id: 21, username: "jeudesprits")))
      }.encode(encoder: JSONEncoder())
       .recieve {
          switch $0 {
          case let .success(value):
            let jsonData = """
            {"id":21,"username":"jeudesprits"}
            """.data(using: .utf8)!
            XCTAssertEqual(value, jsonData)
            expec1.fulfill()
          default:
            XCTFail()
          }
      }
    
    let expec2 = XCTestExpectation()
    
    let task2 =
      BlockProducerTask<User, String>.init(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (_, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.failure(.provided("Ooops")))
      }.encode(encoder: JSONEncoder())
       .recieve {
          switch $0 {
          case let .failure(.provided(error as String)):
            XCTAssertEqual(error, "Ooops")
            expec2.fulfill()
          default:
            XCTFail()
          }
      }
    
    self.queue.addTask(task1)
    self.queue.addTask(task2)
    
    self.wait(for: [expec1, expec2], timeout: 3)
  }
  
  func testMapKey() {
    let expec1 = XCTestExpectation()
    
    let task1 =
      BlockProducerTask<[Int], String>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (_, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.success([1, 2, 3, 4, 5]))
      }
      .map(\.self, \.count)
      .recieve {
        switch $0 {
        case let .success(value):
          XCTAssertTrue(value == ([1, 2, 3, 4, 5], 5))
          expec1.fulfill()
        default:
          XCTFail()
        }
      }
    
    let expec2 = XCTestExpectation()
    
    let task2 =
      BlockProducerTask<[Int], String>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (_, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.failure(.provided("Ooops")))
      }
      .map(\.self, \.count)
      .recieve {
        switch $0 {
        case let .failure(.provided(error)):
          XCTAssertEqual(error, "Ooops")
          expec2.fulfill()
        default:
          XCTFail()
        }
      }
    
    self.queue.addTask(task1)
    self.queue.addTask(task2)
    
    self.wait(for: [expec1, expec2], timeout: 3)
  }
  
  func testBreakpointTask() {
    let expec1 = XCTestExpectation()
    
    let task1 =
      BlockProducerTask<Int, String>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (_, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.success(21))
      }.breakpointOnError()
       .recieve {
          switch $0 {
          case let .success(value):
            XCTAssertEqual(value, 21)
            expec1.fulfill()
          default:
            XCTFail()
          }
      }
    
    let expec2 = XCTestExpectation()
    
    let task2 =
      BlockProducerTask<Int, String>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (_, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.success(100))
      }.breakpointOnOutput {
        $0 == 21
      }.recieve {
          switch $0 {
          case let .success(value):
            XCTAssertEqual(value, 100)
            expec2.fulfill()
          default:
            XCTFail()
          }
      }
    
    self.queue.addTask(task1)
    self.queue.addTask(task2)
    
    self.wait(for: [expec1, expec2], timeout: 3)
  }
  
  // MARK: -
  
  static var allTests = [
    ("testMapTask", testMapTask),
    ("testTryMapTask", testTryMapTask),
    ("testFlatMapTask", testFlatMapTask),
    ("testMapErrorTask", testMapErrorTask),
    ("testSetFailureTypeTask", testSetFailureTypeTask),
    ("testCompactMapTask", testCompactMapTask),
    ("testTryCompactMapTask", testTryCompactMapTask),
    ("testReplaceEmptyTask", testReplaceEmptyTask),
    ("testIgnoreOutputTask", testIgnoreOutputTask),
    ("testZipTask", testZipTask),
    ("testAssertNoFailureTask", testAssertNoFailureTask),
    ("testCatchTask", testCatchTask),
    ("testTryCatchTask", testTryCatchTask),
    ("testDecodeTask", testDecodeTask),
    ("testEncodeTask", testEncodeTask),
    ("testMapKey", testMapKey),
    ("testBreakpointTask", testBreakpointTask),
  ]
}
