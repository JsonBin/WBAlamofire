import XCTest
@testable import WBAlamofire

class WBAlamofireTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(WBAlamofire().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
