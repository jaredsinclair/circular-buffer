//
//  CircularBuffer.swift
//  CircularBuffer
//
//  Created by Jared Sinclair on 1/1/20.
//  Copyright © 2021 Nice Boy, LLC. All rights reserved.
//

/// Fixed-size circular (ring) buffer implementation that (with caveats)
/// conforms to Swift collection protocols.
///
/// The intended use case for CircularBuffer is to instantiate a buffer, either
/// with a full ring of starting values or with only a stated capacity, and
/// afterwards to only call `append(_:)` to add elements to the tail end of the
/// buffer. Non-destructive collection operations are encouraged (`map` e.g.).
///
/// - Note: some collection operations, like `replaceSubrange(_:with:)` are
///   discouraged or unsupported, and others like `remove(at:)` are downright
///   prevented through precondition failures. Stick to `append(_:)` and non-
///   destructive operations.
public struct CircularBuffer<Element> {

    /// The index of the head (oldest) element.
    ///
    /// You should have no need to use this, it's here only as a requirement of
    /// the `Collection` protocol.
    public var startIndex: Index

    /// The first index after the tail (most recent) element. This index is
    /// functionally equivalent to the `startIndex` since the buffer always
    /// wraps around to the head, never grows.
    ///
    /// In other words, you have no need to use this, it's here only as a
    /// requirement of the `Collection` protocol.
    public var endIndex: Index

    /// The underlying storage that `Index` is able to index into.
    ///
    /// We use `ContiguousArray` instead of `Array` because it can potentially
    /// be much faster when storing Objective-C types.
    ///
    /// Since CircularBuffer is designed to have a fixed size, the array is
    /// initialized to contain a `nil` value for any as-yet unused slots.
    @usableFromInline
    internal var buffer: ContiguousArray<Element?>

    /// Initializes a buffer with `capacity` number of fixed, empty slots.
    @inlinable
    public init(capacity: Int) {
        let buffer = ContiguousArray<Element?>(repeating: nil, count: capacity)
        let maxIndex = buffer.count - 1
        let startIndex = Index(rawValue: 0, max: maxIndex, role: .start, wasWrapped: false) // initial head is never wrapped
        let endIndex = Index(rawValue: 0, max: maxIndex, role: .end, wasWrapped: false) // not wrapped because buffer's empty
        self.init(buffer: buffer, startIndex: startIndex, endIndex: endIndex)
    }

    /// Initializes a buffer from any `Sequence` of `Element`.
    @inlinable
    public init<S: Sequence>(_ sequence: S) where S.Element == Element {
        let buffer = ContiguousArray<Element?>(sequence.map { $0 })
        let maxIndex = buffer.count - 1
        let startIndex = Index(rawValue: 0, max: maxIndex, role: .start, wasWrapped: false) // initial head is never wrapped
        let endIndex = Index(rawValue: 0, max: maxIndex, role: .end, wasWrapped: true) // is wrapped because buffer's already full
        self.init(buffer: buffer, startIndex: startIndex, endIndex: endIndex)
    }

    /// Unchecked memberwise initializer used by all other initializers.
    @inlinable
    internal init(buffer: ContiguousArray<Element?>, startIndex: Index, endIndex: Index) {
        precondition(buffer.count > 1, "CircularBuffer does not support capacities that small.")
        self.buffer = buffer
        self.startIndex = startIndex
        self.endIndex = endIndex
    }

}

// MARK: - Sequence

extension CircularBuffer : Sequence {

    /// Required by `Sequence`.
    public typealias Iterator = CircularIterator<Element>

    /// Required by `Sequence`.
    public struct CircularIterator<Element> : IteratorProtocol {

        /// A back-reference to the circular buffer the iterator is used with.
        @usableFromInline
        internal let circle: CircularBuffer<Element>

        /// The current index into a slot in the circular buffer.
        @usableFromInline
        internal var cursor: CircularBuffer<Element>.Index?

        /// Returns the next element in the buffer, if there is one remaining.
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

        /// Initializes an iterator.
        @inlinable
        internal init(circle: CircularBuffer<Element>) {
            self.circle = circle
        }

    }

    /// Required by `Sequence`.
    @inlinable
    public func makeIterator() -> Iterator {
        return Iterator(circle: self)
    }

}

// MARK: - Collection

extension CircularBuffer : Collection {

    /// Required by `Collection`, and relied upon by `CircularBuffer.Iterator`.
    public struct Index: Equatable {

        /// Circular buffer only ever has two indices: one for the head (the
        /// oldest element) and one for the tail (the newest element). Since
        /// these may sometimes both point to the same raw index in the
        /// underlying contiguous array, a "role" must be assigned to further
        /// distinguish the two in the implementation of various operations.
        ///
        /// Since "head" and "tail" are potentially vague, we use "start" and
        /// "end" since those helpfully connote both physically and temporally
        /// contrasting locations.
        @usableFromInline
        internal enum Role: Equatable {
            case start, end
        }

        /// The index into the underylying contiguous array.
        @usableFromInline
        internal let rawValue: Int

        /// The maximum number of allowed elements in the buffer.
        @usableFromInline
        internal let max: Int

        /// Whether the index has wrapped around the end of the underlying
        /// contiguous buffer. This is a potential state for both the start and
        /// the end index roles.
        @usableFromInline
        internal let wasWrapped: Bool

        /// The role (start vs end).
        @usableFromInline
        internal let role: Role

        /// Memberwise initializer.
        @inlinable
        internal init(rawValue: Int, max: Int, role: Role, wasWrapped: Bool) {
            self.rawValue = rawValue
            self.max = max
            self.role = role
            self.wasWrapped = wasWrapped
        }

        /// Increments the index returning the next valid index, wrapping
        /// arround to the beginning of the contigous array's indices if
        /// needed. The returned value retains the role of the receiver.
        @inlinable
        internal func incrementedByOne() -> Index {
            let next = rawValue + 1
            if next > max {
                return Index(rawValue: 0, max: max, role: role, wasWrapped: true)
            } else {
                return Index(rawValue: next, max: max, role: role, wasWrapped: wasWrapped)
            }
        }

        /// Returns `true` if the index can be safely used to index into the
        /// non-empty contents of the circular buffer.
        @inlinable
        internal func isValid(for circle: CircularBuffer<Element>) -> Bool {
            if circle.endIndex.wasWrapped {
                return (0..<circle.buffer.count).contains(rawValue)
            } else {
                return (0..<circle.endIndex.rawValue).contains(rawValue)
            }
        }

    }

    /// Required by `Collection`.
    @inlinable
    public var count: Int {
        return endIndex.wasWrapped
            ? buffer.count
            : endIndex.rawValue
    }

    /// Required by `Collection`.
    @inlinable
    public subscript(position: Index) -> Element {
        assert(position.isValid(for: self), "Invalid index: \(position)")
        return buffer[position.rawValue]!
    }

    /// Required by `Collection`.
    @inlinable
    public func index(after i: Index) -> Index {
        return i.incrementedByOne()
    }

}

// MARK: - RangeReplaceableCollection

extension CircularBuffer : RangeReplaceableCollection {

    /// Required by `RangeReplaceableCollection`.
    @inlinable
    public init() {
        self.init(capacity: 16)
    }

    /// Required by `RangeReplaceableCollection`.
    @inlinable
    public mutating func replaceSubrange<C>(_ subrange: Range<Index>, with newElements: C) where C : Collection, Self.Element == C.Element {
        var index = subrange.lowerBound
        var iterator = newElements.makeIterator()
        while let next = iterator.next() {
            buffer[index.rawValue] = next
            index = index.incrementedByOne()
        }
    }

    /// Overrides the default implementation provided by `RangeReplaceableCollection`.
    @inlinable
    public mutating func append(_ newElement: Element) {
        // We have to provide a custom implementation for `append(_:)` because
        // the inferred implementation doesn't know that CircularBuffer has a
        // fixed size. Calling `append(_:)` should not grow the buffer, merely
        // append the new element to the tail end of the buffer.
        buffer[endIndex.rawValue] = newElement
        if endIndex.wasWrapped {
            endIndex = endIndex.incrementedByOne()
            startIndex = startIndex.incrementedByOne()
        } else {
            endIndex = endIndex.incrementedByOne()
        }
    }

    /// Overrides the default implementation provided by `RangeReplaceableCollection`.
    ///
    /// - Warning: This method is wholly unsupported. It will always trap.
    @inlinable
    public mutating func remove(at i: Index) -> Element {
        preconditionFailure("\(#function) is not supported by CircularBuffer.")
    }

}

// MARK: - Bric-a-Brac

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
        self.init(elements)
    }

}

extension CircularBuffer: Equatable where Element: Equatable {

    public static func == (lhs: CircularBuffer<Element>, rhs: CircularBuffer<Element>) -> Bool {
        // Two CircularBuffer's are equal if iterating through them produces
        // identical elements from start to finish, regardless of whether the
        // underlying indices are aligned or not.
        zip(lhs, rhs).contains { left, right in
            left != right
        } == false
    }

}
