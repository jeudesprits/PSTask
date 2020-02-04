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

  private let queue = TaskQueue(name: "com.PSTask.TasksNamespaceTests", qos: .userInitiated)
  
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
         finish(.failure(.providedFailure("Ooops")))
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
    
    queue.addTask(task1)
    queue.addTask(task2)
    
    wait(for: [expec1, expec2], timeout: 3)
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
        case let .failure(.providedFailure(error as String)):
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
    
    queue.addTask(task1)
    queue.addTask(task2)
    
    wait(for: [expec1, expec2], timeout: 3)
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
        finish(.failure(.providedFailure("Ooops")))
      }.flatMap { (value) in
        BlockProducerTask<Int, String> { (_, finish) in
          Thread.sleep(forTimeInterval: 2)
          finish(.success(value + value))
        }
      }.recieve {
        switch $0 {
        case let .failure(.providedFailure(error)):
          XCTAssertEqual(error, "Ooops")
          expec2.fulfill()
        default:
          XCTFail()
        }
      }
    
    queue.addTask(task1)
    queue.addTask(task2)
    
    wait(for: [expec1, expec2], timeout: 5)
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
        finish(.failure(.providedFailure("Oopps")))
      }.mapError {
        OoopsError.ooops($0)
      }.recieve {
        switch $0 {
        case let .failure(.providedFailure(.ooops(value))):
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
    
    queue.addTask(task1)
    queue.addTask(task2)
    
    wait(for: [expec1, expec2], timeout: 3)
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
            finish(.failure(.providedFailure("Ooops")))
          }
      }.recieve {
        switch $0 {
        case let.failure(.providedFailure(error)):
          XCTAssertEqual(error, "Ooops")
          expec.fulfill()
        default:
          XCTFail()
        }
     }
    
    queue.addTask(task)
    
    wait(for: [expec], timeout: 5)
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
        case let .failure(.internalFailure(error as ProducerTaskError)):
          XCTAssertEqual(error, ProducerTaskError.executionFailure)
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
    
    queue.addTask(task1)
    queue.addTask(task2)
    
    wait(for: [expec1, expec2], timeout: 3)
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
        case let .failure(.providedFailure(error as String)):
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
        case let .failure(.internalFailure(error as ProducerTaskError)):
          XCTAssertEqual(error, ProducerTaskError.executionFailure)
          expec2.fulfill()
        default:
          XCTFail()
        }
      }
    
    queue.addTask(task1)
    queue.addTask(task2)
    
    wait(for: [expec1, expec2], timeout: 3)
  }
  
  func testReplaceErrorTask() {
    let expec1 = XCTestExpectation()
    
    let task1 =
      BlockProducerTask<Int, String>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (_, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.failure(.providedFailure("Ooops")))
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
    
    queue.addTask(task1)
    queue.addTask(task2)
    
    wait(for: [expec1, expec2], timeout: 3)
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
        finish(.failure(.providedFailure("Ooops")))
      }.ignoreOutput()
       .recieve {
          switch $0 {
          case let .failure(.providedFailure(error)):
            XCTAssertEqual(error, "Ooops")
            expec2.fulfill()
          default:
            XCTFail()
          }
      }
    
    queue.addTask(task1)
    queue.addTask(task2)
    
    wait(for: [expec1, expec2], timeout: 3)
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
        finish(.failure(.providedFailure("Ooops")))
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
        case let .failure(.providedFailure(error)):
          XCTAssertEqual(error, "Ooops")
          expec2.fulfill()
        default:
          XCTFail()
        }
      }
    
    queue.addTask(task1)
    queue.addTask(task2)
    
    wait(for: [expec1, expec2], timeout: 3)
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
    
    queue.addTask(task)
    
    wait(for: [expec], timeout: 3)
  }
  
  func testCatchTask() {
    let expec1 = XCTestExpectation()
    
    let task1 =
      BlockProducerTask<Int, String>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (task, finish) in
        Thread.sleep(forTimeInterval: 2)
        finish(.failure(.providedFailure("Ooops")))
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
    
    queue.addTask(task1)
    queue.addTask(task2)
    
    wait(for: [expec1, expec2], timeout: 5)
  }
  
  func testTryCatchTask() {
    let expec1 = XCTestExpectation()
    
    let task1 =
      BlockProducerTask<Int, String>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (task, finish) -> Void in
        Thread.sleep(forTimeInterval: 2)
        finish(.failure(.providedFailure("Ooops")))
      }.tryCatch { (error) -> BlockProducerTask<Int, String> in
        guard error != "Ooops" else { throw "Nooo" }
        return BlockProducerTask { (_, finish) in
          Thread.sleep(forTimeInterval: 2)
          finish(.success(21))
        }
      }.recieve {
        switch $0 {
        case let .failure(.providedFailure(error as String)):
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
        finish(.failure(.providedFailure("Nooo")))
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
    
    queue.addTask(task1)
    queue.addTask(task2)
    queue.addTask(task3)

    wait(for: [expec1, expec2, expec3], timeout: 5)
  }
}


