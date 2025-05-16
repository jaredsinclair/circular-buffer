import Testing
@testable import CircularBuffer

@Suite struct CircularBufferTests {

    @Test func arrayLiteralExpressible() {
        let buffer: CircularBuffer<Int> = [1,2,3,4,5]
        #expect(buffer.count == 5)
    }

    @Test func expandsUpToCapacity() {
        var buffer = CircularBuffer<Int>(capacity: 5)
        #expect(buffer.count == 0)

        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        buffer.append(4)
        buffer.append(5)
        #expect(buffer.count == 5)
        #expect(buffer == [1,2,3,4,5])

        buffer.append(6)
        buffer.append(7)
        buffer.append(8)
        buffer.append(9)
        #expect(buffer.count == 5)
        #expect(buffer == [5,6,7,8,9])
    }

    @Test func mapUnfilled() {
        var buffer = CircularBuffer<Int>(capacity: 5)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        let mapped = buffer.map { $0 * 2 }
        #expect(mapped == [2,4,6])
    }

    @Test func mapFilled() {
        var buffer = CircularBuffer<Int>(capacity: 5)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        buffer.append(4)
        buffer.append(5)
        let mapped = buffer.map { $0 * 2 }
        #expect(mapped == [2,4,6,8,10])
    }

    @Test func mapOverfilled() {
        var buffer = CircularBuffer<Int>(capacity: 3)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        buffer.append(4)
        buffer.append(5)
        let mapped = buffer.map { $0 * 2 }
        #expect(mapped == [6,8,10])
    }

    @Test func enumeratedUnfilled() {
        var buffer = CircularBuffer<Int>(capacity: 5)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        let mapped = buffer.enumerated().map {
            Twople($0.offset, $0.element * 2)
        }
        #expect(mapped == [ Twople(0,2), Twople(1,4), Twople(2,6) ])
    }

    @Test func enumeratedFilled() {
        var buffer = CircularBuffer<Int>(capacity: 5)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        buffer.append(4)
        buffer.append(5)
        let mapped = buffer.enumerated().map {
            Twople($0.offset, $0.element * 2)
        }
        #expect(mapped == [ Twople(0,2), Twople(1,4), Twople(2,6), Twople(3,8), Twople(4,10) ])
    }

    @Test func enumeratedOverfilled() {
        var buffer = CircularBuffer<Int>(capacity: 3)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        buffer.append(4)
        buffer.append(5)
        let mapped = buffer.enumerated().map {
            Twople($0.offset, $0.element * 2)
        }
        #expect(mapped == [ Twople(0,6), Twople(1,8), Twople(2,10) ])
    }

    @Test func reduce() {
        let buffer: CircularBuffer<Int> = [1,1,1,1,1]
        #expect(buffer.reduce(0, +) == 5)
    }

    @Test func replaceSubrange_sameNumberOfValues() {
        var buffer: CircularBuffer<Int> = [1,1,1,1,1]
        buffer.replaceSubrange(buffer.startIndex..<buffer.endIndex, with: Array([2,3,4,5,6]))
        #expect(buffer == [2,3,4,5,6])
    }

    @Test func replaceSubrange_firstFewOnly() {
        var buffer: CircularBuffer<Int> = [1,1,1,1,1]
        buffer.replaceSubrange(buffer.startIndex..<buffer.endIndex, with: Array([2,3,4]))
        #expect(buffer == [2,3,4,1,1])
    }

    @Test func replaceSubrange_wrappingAround() {
        var buffer: CircularBuffer<Int> = [1,1,1,1,1]
        let start = buffer.startIndex.incrementedByOne()
        let end = buffer.endIndex.incrementedByOne()
        buffer.replaceSubrange(start..<end, with: Array([2,3,4,5,6]))
        #expect(buffer == [6,2,3,4,5])
    }

    @Test func repeatingCount() {
        let buffer = CircularBuffer<Int>(repeating: 5, count: 5)
        #expect(buffer == [5,5,5,5,5])
    }

    @Test func initWithSequence() {
        var buffer = CircularBuffer<Int>(Array([1,2,3,4,5]))
        #expect(buffer == [1,2,3,4,5])

        buffer.append(6)
        buffer.append(7)
        buffer.append(8)
        #expect(buffer == [4,5,6,7,8])
    }

    @Test func appendContentsOf_fewerThanCapacity() {
        var buffer: CircularBuffer<Int> = [1,2,3,4,5]
        buffer.append(contentsOf: Array([9,9,9]))
        #expect(buffer == [4,5,9,9,9])
    }

    @Test func appendContentsOf_greaterThanCapacity() {
        var buffer: CircularBuffer<Int> = [1,2,3,4,5]
        buffer.append(contentsOf: Array([6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]))
        #expect(buffer == [16,17,18,19,20])
    }

    @Test func insertElementAtStart() {
        var buffer: CircularBuffer<Int> = [1,1,1,1,1]
        buffer.insert(9, at: buffer.startIndex)
        #expect(buffer == [9,1,1,1,1])
    }

    @Test func insertElementAtEnd() {
        var buffer: CircularBuffer<Int> = [1,1,1,1,1]
        buffer.insert(9, at: buffer.endIndex)
        #expect(buffer == [9,1,1,1,1]) // the end is the beginning
    }

    @Test func insertElementAtPenultimate() {
        var buffer: CircularBuffer<Int> = [1,1,1,1,1]
        let index = buffer.startIndex
            .incrementedByOne()
            .incrementedByOne()
            .incrementedByOne()
            .incrementedByOne()
        buffer.insert(9, at: index)
        #expect(buffer == [1,1,1,1,9])
    }

    @Test func dropLast() {
        var buffer = CircularBuffer<Int>(capacity: 99)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        buffer.append(4)
        buffer.append(5)
        let slice = buffer.dropLast()
        #expect(Array(slice) == [1,2,3,4])
    }

    @Test func dropFirst() {
        var buffer = CircularBuffer<Int>(capacity: 4)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        buffer.append(4)
        buffer.append(5)
        let slice = buffer.dropFirst()
        #expect(Array(slice) == [2])
    }

    @Test func removeFirstDoesntWrap() {
        var buffer = CircularBuffer<Int>(capacity: 5)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        let first = buffer.removeFirst()
        #expect(first == 1)
        #expect(Array(buffer) == [2,3])
    }

    @Test func removeFirstWraps() {
        var buffer = CircularBuffer<Int>(capacity: 3)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        buffer.append(4)
        buffer.append(5)
        let first = buffer.removeFirst()
        #expect(first == 3)
        #expect(Array(buffer) == [4,5])
    }

    @Test func removeFirstNDoesntWrap() {
        var buffer = CircularBuffer<Int>(capacity: 5)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        buffer.removeFirst(2)
        #expect(Array(buffer) == [3])
    }

    @Test func removeFirstNWraps() {
        var buffer = CircularBuffer<Int>(capacity: 4)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        buffer.append(4)
        buffer.append(5)
        buffer.removeFirst(2)
        #expect(Array(buffer) == [4,5])
    }

    @Test func removeAllWhere() {
        var buffer = CircularBuffer<Int>(capacity: 5)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        buffer.append(4)
        buffer.append(5)
        buffer.removeAll(where: { $0.isMultiple(of: 2) })
        #expect(Array(buffer) == [1,3,5])
        buffer.append(6)
        buffer.append(7)
        buffer.append(8)
        #expect(Array(buffer) == [3,5,6,7,8])
        buffer.removeAll(where: { $0 < 7 })
        #expect(Array(buffer) == [7,8])
        buffer.append(9)
        buffer.append(10)
        buffer.append(11)
        #expect(Array(buffer) == [7,8,9,10,11])
    }

    @Test func removeAtStart() {
        var buffer = CircularBuffer<Int>(capacity: 5)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        buffer.append(4)
        buffer.append(5)
        let removed = buffer.remove(at: buffer.startIndex)
        #expect(removed == 1)
        #expect(Array(buffer) == [2,3,4,5])
    }

    @Test func removeAtMiddle() {
        var buffer = CircularBuffer<Int>(capacity: 5)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        buffer.append(4)
        buffer.append(5)
        let removed = buffer.remove(at: buffer.startIndex.incrementedByOne().incrementedByOne())
        #expect(removed == 3)
        #expect(Array(buffer) == [1,2,4,5])
    }

    @Test func removeAtMiddleWrapped() {
        var buffer = CircularBuffer<Int>(capacity: 5)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        buffer.append(4)
        buffer.append(5)
        buffer.append(6)
        buffer.append(7)
        let removed = buffer.remove(at: buffer.startIndex.incrementedByOne().incrementedByOne())
        #expect(removed == 5)
        #expect(Array(buffer) == [3,4,6,7])
    }

    @Test func removeAtEnd() {
        var buffer = CircularBuffer<Int>(capacity: 5)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        buffer.append(4)
        buffer.append(5)
        let removed = buffer.remove(at: buffer.endIndex)
        #expect(removed == 1)
        #expect(Array(buffer) == [2,3,4,5])
    }

    @Test func removeAtEndWrapped() {
        var buffer = CircularBuffer<Int>(capacity: 5)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        buffer.append(4)
        buffer.append(5)
        buffer.append(6)
        buffer.append(7)
        let removed = buffer.remove(at: buffer.endIndex)
        #expect(removed == 3)
        #expect(Array(buffer) == [4,5,6,7])
    }

}

private struct Twople: Equatable {

    let offset, element: Int

    init(_ offset: Int, _ element: Int) {
        self.offset = offset
        self.element = element
    }

}
