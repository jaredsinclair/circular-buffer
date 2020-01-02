//
//  CircularBuffer.swift
//  CircularBuffer
//
//  Created by Jared Sinclair on 1/1/20.
//  Copyright © 2020 Nice Boy, LLC. All rights reserved.
//

public struct CircularBuffer<Element> {

    public var startIndex: Index

    public var endIndex: Index

    @usableFromInline
    internal var buffer: ContiguousArray<Element?>

    @inlinable
    public init(capacity: Int) {
        precondition(capacity > 1, "CircularBuffer does not support capacities that small.")
        let buffer = ContiguousArray<Element?>(repeating: nil, count: capacity)
        let maxIndex = buffer.count - 1
        let startIndex = Index(rawValue: 0, max: maxIndex, role: .start)
        let endIndex = Index(rawValue: 0, max: maxIndex, role: .end)
        self.init(buffer: buffer, startIndex: startIndex, endIndex: endIndex)
    }

    @inlinable
    internal init(buffer: ContiguousArray<Element?>, startIndex: Index, endIndex: Index) {
        self.buffer = buffer
        self.startIndex = startIndex
        self.endIndex = endIndex
    }

}

extension CircularBuffer : Sequence {

    public typealias Iterator = CircularIterator<Element>

    public struct CircularIterator<Element> : IteratorProtocol {

        @usableFromInline
        internal let circle: CircularBuffer<Element>

        @usableFromInline
        internal var cursor: CircularBuffer<Element>.Index?

        @inlinable
        public mutating func next() -> Element? {
            if cursor == nil {
                cursor = circle.startIndex
            } else {
                cursor = cursor?.incrementedByOne()
                if cursor?.rawValue == circle.endIndex.rawValue {
                    // Prevent infinite loop.
                    return nil
                }
            }
            return circle.buffer[cursor!.rawValue]
        }

        @inlinable
        internal init(circle: CircularBuffer<Element>) {
            self.circle = circle
        }

    }

    @inlinable
    public func makeIterator() -> Iterator {
        return Iterator(circle: self)
    }

}

extension CircularBuffer : Collection {

    public struct Index: Equatable {

        @usableFromInline
        internal enum Role: Equatable {
            case start, end
        }

        @usableFromInline
        internal let rawValue: Int

        @usableFromInline
        internal let max: Int

        @usableFromInline
        internal let wasWrapped: Bool

        @usableFromInline
        internal let role: Role

        @inlinable
        internal init(rawValue: Int, max: Int, role: Role, wasWrapped: Bool = false) {
            self.rawValue = rawValue
            self.max = max
            self.role = role
            self.wasWrapped = wasWrapped
        }

        @inlinable
        internal func incrementedByOne() -> Index {
            let next = rawValue + 1
            if next > max {
                return Index(rawValue: 0, max: max, role: role, wasWrapped: true)
            } else {
                return Index(rawValue: next, max: max, role: role, wasWrapped: wasWrapped)
            }
        }

        @inlinable
        internal func isValid(for circle: CircularBuffer<Element>) -> Bool {
            if circle.endIndex.wasWrapped {
                return (0..<circle.buffer.count).contains(rawValue)
            } else {
                return (0..<circle.endIndex.rawValue).contains(rawValue)
            }
        }

    }

    @inlinable
    public var count: Int {
        return endIndex.wasWrapped
            ? buffer.count
            : endIndex.rawValue
    }

    @inlinable
    public subscript(position: Index) -> Element {
        assert(position.isValid(for: self), "Invalid index: \(position)")
        return buffer[position.rawValue]!
    }

    @inlinable
    public func index(after i: Index) -> Index {
        return i.incrementedByOne()
    }

}

extension CircularBuffer : RangeReplaceableCollection {

    @inlinable
    public init() {
        self.init(capacity: 16)
    }

    @inlinable
    public mutating func append(_ newElement: Element) {
        buffer[endIndex.rawValue] = newElement
        if endIndex.wasWrapped {
            endIndex = endIndex.incrementedByOne()
            startIndex = startIndex.incrementedByOne()
        } else {
            endIndex = endIndex.incrementedByOne()
        }
    }

}

extension CircularBuffer : CustomStringConvertible {

    @inlinable
    public var description: String { buffer.description }

}

extension CircularBuffer : CustomDebugStringConvertible {

    @inlinable
    public var debugDescription: String {
        "CircularBuffer<\(Element.self)>(\(buffer.description))"
    }

}

extension CircularBuffer.Index : Comparable {

    @inlinable
    public static func < (lhs: CircularBuffer<Element>.Index, rhs: CircularBuffer<Element>.Index) -> Bool {
        switch (lhs.role, rhs.role) {
        case (.start, .end):
            return true
        case (.end, .start):
            return false
        case (_, _):
            return lhs.rawValue < rhs.rawValue
        }
    }

}

extension CircularBuffer : ExpressibleByArrayLiteral {

    @inlinable
    public init(arrayLiteral elements: Element...) {
        precondition(elements.count > 1, "CircularBuffer does not support capacities that small.")
        let buffer = ContiguousArray(elements as [Element?])
        let maxIndex = elements.count - 1
        let startIndex = Index(rawValue: 0, max: maxIndex, role: .start, wasWrapped: false)
        let endIndex = Index(rawValue: 0, max: maxIndex, role: .end, wasWrapped: true)
        self.init(buffer: buffer, startIndex: startIndex, endIndex: endIndex)
    }

}
