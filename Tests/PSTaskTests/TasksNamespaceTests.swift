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
}


