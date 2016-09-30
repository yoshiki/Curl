import XCTest
@testable import Curl

class CurlTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(Curl().text, "Hello, World!")
    }


    static var allTests : [(String, (CurlTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
