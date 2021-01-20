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
        XCTAssertEqual(buffer, [1,2,3,4,5])

        buffer.append(6)
        buffer.append(7)
        buffer.append(8)
        buffer.append(9)
        XCTAssertEqual(buffer.count, 5)
        XCTAssertEqual(buffer, [5,6,7,8,9])
    }

    func testReduce() {
        let buffer: CircularBuffer<Int> = [1,1,1,1,1]
        XCTAssertEqual(buffer.reduce(0, +), 5)
    }

    func testReplaceSubrange_sameNumberOfValues() {
        var buffer: CircularBuffer<Int> = [1,1,1,1,1]
        buffer.replaceSubrange(buffer.startIndex..<buffer.endIndex, with: Array([2,3,4,5,6]))
        XCTAssertEqual(buffer, [2,3,4,5,6])
    }

    func testReplaceSubrange_firstFewOnly() {
        var buffer: CircularBuffer<Int> = [1,1,1,1,1]
        buffer.replaceSubrange(buffer.startIndex..<buffer.endIndex, with: Array([2,3,4]))
        XCTAssertEqual(buffer, [2,3,4,1,1])
    }

    func testReplaceSubrange_wrappingAround() {
        var buffer: CircularBuffer<Int> = [1,1,1,1,1]
        let start = buffer.startIndex.incrementedByOne()
        let end = buffer.endIndex.incrementedByOne()
        buffer.replaceSubrange(start..<end, with: Array([2,3,4,5,6]))
        XCTAssertEqual(buffer, [6,2,3,4,5])
    }

    func testRepeatingCount() {
        let buffer = CircularBuffer<Int>(repeating: 5, count: 5)
        XCTAssertEqual(buffer, [5,5,5,5,5])
    }

    func testInitWithSequence() {
        var buffer = CircularBuffer<Int>(Array([1,2,3,4,5]))
        XCTAssertEqual(buffer, [1,2,3,4,5])

        buffer.append(6)
        buffer.append(7)
        buffer.append(8)
        XCTAssertEqual(buffer, [4,5,6,7,8])
    }

    func testAppendContentsOf_fewerThanCapacity() {
        var buffer: CircularBuffer<Int> = [1,2,3,4,5]
        buffer.append(contentsOf: Array([9,9,9]))
        XCTAssertEqual(buffer, [4,5,9,9,9])
    }

    func testAppendContentsOf_greaterThanCapacity() {
        var buffer: CircularBuffer<Int> = [1,2,3,4,5]
        buffer.append(contentsOf: Array([6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]))
        XCTAssertEqual(buffer, [16,17,18,19,20])
    }

    func testInsertElementAtStart() {
        var buffer: CircularBuffer<Int> = [1,1,1,1,1]
        buffer.insert(9, at: buffer.startIndex)
        XCTAssertEqual(buffer, [9,1,1,1,1])
    }

    func testInsertElementAtEnd() {
        var buffer: CircularBuffer<Int> = [1,1,1,1,1]
        buffer.insert(9, at: buffer.endIndex)
        XCTAssertEqual(buffer, [9,1,1,1,1]) // the end is the beginning
    }

    func testInsertElementAtPenultimate() {
        var buffer: CircularBuffer<Int> = [1,1,1,1,1]
        let index = buffer.startIndex
            .incrementedByOne()
            .incrementedByOne()
            .incrementedByOne()
            .incrementedByOne()
        buffer.insert(9, at: index)
        XCTAssertEqual(buffer, [1,1,1,1,9])
    }

    func testDropLast() {
        var buffer = CircularBuffer<Int>(capacity: 99)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        buffer.append(4)
        buffer.append(5)
        let slice = buffer.dropLast()
        XCTAssertEqual(Array(slice), [1,2,3,4])
    }

}
