import XCTest
@testable import PSTask

final class PSTaskTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(PSTask().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
