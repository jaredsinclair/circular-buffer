import XCTest
@testable import CircularBuffer

final class CircularBufferTests: XCTestCase {

    func testArrayLiteralExpressible() {
        let buffer: CircularBuffer<Int> = [1,2,3,4,5]
        XCTAssertEqual(buffer.count, 5)
    }

    func testExpandsUpToCapacity() {
        var buffer = CircularBuffer<Int>(capacity: 5)
        XCTAssertEqual(buffer.count, 0)

        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        buffer.append(4)
        buffer.append(5)
        XCTAssertEqual(buffer.count, 5)

        buffer.append(6)
        buffer.append(7)
        buffer.append(8)
        buffer.append(9)
        buffer.append(10)
        XCTAssertEqual(buffer.count, 5)
    }

    func testReduce() {
        let buffer: CircularBuffer<Int> = [1,1,1,1,1]
        XCTAssertEqual(buffer.reduce(0, +), 5)
    }

    static var allTests = [
        ("testArrayLiteralExpressible", testArrayLiteralExpressible),
        ("testExpandsUpToCapacity", testExpandsUpToCapacity),
        ("testReduce", testReduce),
    ]

}
