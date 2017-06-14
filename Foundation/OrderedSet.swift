// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

// Prime numbers. Values above 100 have been adjusted up so that the
// malloced block size will be just below a multiple of 512; values
// above 1200 have been adjusted up to just below a multiple of 4096.
// TODO: This probably could be tuned a bit better for rehashing performance.
#if arch(x86_64) || arch(arm64)
let _HashingGrowthPatterns: [Int] = [13, 23, 41, 71, 127, 191, 251, 383, 631, 1087, 1723,
                                     2803, 4523, 7351, 11959, 19447, 31231, 50683, 81919, 132607,
                                     214519, 346607, 561109, 907759, 1468927, 2376191, 3845119,
                                     6221311, 10066421, 16287743, 26354171, 42641881, 68996069,
                                     111638519, 180634607, 292272623, 472907251, 765180413, 1238087663, 2003267557, 3241355263, 5244622819]
#else
let _HashingGrowthPatterns: [Int] = [13, 23, 41, 71, 127, 191, 251, 383, 631, 1087, 1723,
                                     2803, 4523, 7351, 11959, 19447, 31231, 50683, 81919, 132607,
                                     214519, 346607, 561109, 907759, 1468927, 2376191, 3845119,
                                     6221311, 10066421, 16287743, 26354171, 42641881, 68996069,
                                     111638519, 180634607, 292272623, 472907251]
#endif

internal class _OrderedSetBacking<Element : Hashable> {
    struct ElementStorage {
        /// Nullable so that we can reuse the storage without reallocating the array
        var value: Element?
        
        /// Used for fast path access to avoid comparisons
        var hash: Int
        
        /// used for both ordered storage AND for available entries
        var next: Int?
        
        /// used only for ordered storage (nil when in the available list)
        var prev: Int?
        
        /// used only for hashed storage (nil when in the available list)
        var nextHash: Int?
        
        /// used only for hashed storage (nil when in the available list)
        var prevHash: Int?
    }
    
    struct _OrderedSetBackingStorage {
        /// The storage for the elements
        var elements: [ElementStorage]
        
        /// Head of the doublly linked list of elmenets that are hashed
        var buckets: [Int?]
        
        /// The requested bucket size index
        var bucketSize: Int
        
        /// Used for tracking when we need to rehash the storage
        var collisions = 0
        /// Head of the doublly linked list of elements that are ordered
        var first: Int?
        
        /// Tail of the doublly linked list of elements that are ordered
        var last: Int?
        
        /// Head of the singlly linked list of elements that are available for use
        var available: Int?
        
        /// Fast path access to how many elements we have stored
        var count = 0
        
        /// This MUST be reset when changes are appplied that may apply to ordered indexes
        var _arrangedIndexes: [Int]?
        
        /// Setup a storage that has a specific bucket size.
        init(_ bucketSize: Int) {
            elements = Array<ElementStorage>()
            buckets = Array<Int?>(repeating: nil, count: _HashingGrowthPatterns[bucketSize])
            self.bucketSize = bucketSize
        }
        
        /// Setup a storage by rehashing another storage.
        /// This only needs to relayout the elements hashing, the order is already determined by the other storage.
        init(rehashing other: _OrderedSetBackingStorage, to bucketSize: Int) {
            elements = other.elements
            buckets = Array<Int?>(repeating: nil, count: _HashingGrowthPatterns[bucketSize])
            self.bucketSize = bucketSize
            first = other.first
            last = other.last
            available = other.available
            count = other.count
            for idx in 0..<elements.count {
                if elements[idx].nextHash != nil {
                    let hash = elements[idx].hash
                    elements[idx].nextHash = bucket(for: hash)
                    elements[idx].prevHash = nil
                    assign(bucket: hash, to: idx)
                }
            }
        }
        
        /// Get a bucket value for a given hash value
        func bucket(for hash: Int) -> Int? {
            let bucketIndex = Int(UInt(bitPattern: hash) % UInt(buckets.count))
            return buckets[bucketIndex]
        }
        
        /// Register an index to a given bucket hash value
        mutating func assign(bucket hash: Int, to value: Int?) {
            let bucketIndex = Int(UInt(bitPattern: hash) % UInt(buckets.count))
            if buckets[bucketIndex] != nil {
                collisions += 1
            }
            buckets[bucketIndex] = value
        }
        
    }
    
    /// Initialized with 13 buckets, the bucket size will be incrementing prime numbers (which should distribute relatively well as modulos)
    var _storage = _OrderedSetBackingStorage(0)
    
    /// Default initialziation of empty OrderedSets
    init() { }
    
    /// Used to easily make copies of the backing
    init(_ storage: _OrderedSetBackingStorage) {
        _storage = storage
    }
    
    /// This should end up being amortized upon non mutations as constant time access
    var arrangedIndexes: [Int] {
        get {
            guard let indexes = _storage._arrangedIndexes else {
                var indexes = [Int]()
                indexes.reserveCapacity(_storage.count)
                var index = _storage.first
                while let idx = index {
                    indexes.append(idx)
                    index = _storage.elements[idx].next
                }
                _storage._arrangedIndexes = indexes
                assert(indexes.count == _storage.count)
                return indexes
            }
            return indexes
        }
    }
    
    subscript(_ index: Int) -> Element {
        /// primitive funnel for accessing elements from the ordered index
        get {
            return _storage.elements[arrangedIndexes[index]].value!
        }
        /// convience method for replacing an element at a given index
        set {
            replaceSubrange(index..<(index+1), with: CollectionOfOne(newValue))
        }
    }
    
    /// primitive funnel for accessing the count
    var count: Int { return _storage.count }
    
    /// convience method for appending an element
    @discardableResult
    func append(_ element: Element) -> (Bool, Element) {
        let (success, after, _) = insert(element, after: _storage.last)
        return (success, after)
    }
    
    /// primitive funnel for removing an element at an index and returning it to the available list
    func recycle(_ index: Int) {
        if _storage.first == index {
            _storage.first = _storage.elements[index].next
        }
        if _storage.last == index {
            _storage.last = _storage.elements[index].prev
        }
        if let prev = _storage.elements[index].prevHash {
            _storage.elements[prev].nextHash = _storage.elements[index].nextHash
        }
        if let prev = _storage.elements[index].prev {
            _storage.elements[prev].next = _storage.elements[index].next
        }
        if let next = _storage.elements[index].nextHash {
            _storage.elements[next].prevHash = _storage.elements[index].prevHash
        }
        if let next = _storage.elements[index].next {
            _storage.elements[next].prev = _storage.elements[index].prev
        }
        _storage.elements[index] = ElementStorage(value: nil, hash: 0, next: _storage.available, prev: nil, nextHash: nil, prevHash: nil)
        
        _storage.count -= 1
        _storage.available = index
    }
    
    /// primitive funnel method for inserting an element at a given index
    /// - parameter element: The element to be inserted
    /// - parameter index: The index to be inserted after (nil means insert at the head)
    func insert(_ element: Element, after index: Int?) -> (Bool, Element, Int?) {
        
        var newIndex: Int
        var next: Int?
        var prev: Int?
        var nextHash: Int?
        let prevHash: Int? = nil // just a placeholder
        
        if _storage.collisions > _HashingGrowthPatterns[_storage.bucketSize] {
            _storage = _OrderedSetBackingStorage(rehashing: _storage, to: _storage.bucketSize + 1)
        }
        
        let hash = element.hashValue
        var bucketIndex = _storage.bucket(for: hash)
        nextHash = bucketIndex
        
        while let idx = bucketIndex {
            if _storage.elements[idx].hash == hash {
                if _storage.elements[idx].value == element {
                    return (false, _storage.elements[idx].value!, nil)
                }
            }
            bucketIndex = _storage.elements[idx].nextHash
        }
        
        if let idx = index {
            next = _storage.elements[idx].next
            prev = idx
        } else {
            next = _storage.first
        }
        
        if let avail = _storage.available {
            newIndex = avail
            _storage.available = _storage.elements[avail].next
            _storage.elements[newIndex] = ElementStorage(value: element, hash: hash, next: next, prev: prev, nextHash: nextHash, prevHash: prevHash)
        } else {
            newIndex = _storage.elements.count
            _storage.elements.append(ElementStorage(value: element, hash: hash, next: next, prev: prev, nextHash: nextHash, prevHash: prevHash))
        }
        
        if let idx = prev {
            _storage.elements[idx].next = newIndex
        }
        
        if prev == nil {
            _storage.first = newIndex
        }
        
        if let idx = next {
            _storage.elements[idx].prev = newIndex
        }
        
        if next == nil {
            _storage.last = newIndex
        }
        
        if let idx = prevHash {
            _storage.elements[idx].nextHash = newIndex
        }
        
        if let idx = nextHash {
            _storage.elements[idx].prevHash = newIndex
        }
        
        _storage.assign(bucket: hash, to: newIndex)
        _storage._arrangedIndexes = nil
        _storage.count += 1
        
        return (true, element, newIndex)
    }
    
    /// primitive funnel method for replacing a range of elements with a collection
    /// - parameter subrange: The range to replace, has a shorthand of "append" via [count...count+1] || [count..<count]
    /// - parameter newElements: The collection of elements to insert in the removed region
    func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: C) where C : Collection, C.Iterator.Element == Element {
        var index: Int?
        // this is a check for the shorthand of "append" via [count...count+1] || [count..<count]
        if !(subrange.lowerBound == _storage.count && (subrange.count == 0 || subrange.count == 1)) {
            let indexes = arrangedIndexes[subrange]
            _storage._arrangedIndexes = nil
            
            if let start = indexes.first {
                index = _storage.elements[start].prev
            }
            
            for idx in indexes {
                recycle(idx)
            }
        } else {
            index = _storage.last
        }
        
        for element in newElements {
            let (_, _, idx) = insert(element, after: index)
            if let i = idx {
                index = i
            }
        }
    }
    
    /// primitive funnel method to remove an element (by hashing)
    func remove(_ element: Element) -> Element? {
        let hash = element.hashValue
        let bucketIndex = _storage.bucket(for: hash)
        var index = bucketIndex
        while let idx = index {
            if _storage.elements[idx].hash == hash {
                if _storage.elements[idx].value == element {
                    let value = _storage.elements[idx].value
                    recycle(idx)
                    _storage._arrangedIndexes = nil
                    return value
                }
            }
            index = _storage.elements[idx].nextHash
        }
        return nil
    }
    
    /// primitive funnel method to update an element (by hashing)
    func update(with element: Element) -> Element? {
        let hash = element.hashValue
        let bucketIndex = _storage.bucket(for: hash)
        var index = bucketIndex
        while let idx = index {
            if _storage.elements[idx].hash == hash {
                if _storage.elements[idx].value == element {
                    let old = _storage.elements[idx].value
                    _storage.elements[idx].value = element
                    return old
                }
            }
            index = _storage.elements[idx].nextHash
        }
        return nil
    }
    
    /// primitive funnel method for getting a member from the set (identity is a thing... why SetAlgebra does not have this I dont know...)
    func member(_ element: Element) -> Element? {
        let hash = element.hashValue
        let bucketIndex = _storage.bucket(for: hash)
        var index = bucketIndex
        while let idx = index {
            if _storage.elements[idx].hash == hash {
                if _storage.elements[idx].value == element {
                    return _storage.elements[idx].value
                }
            }
            index = _storage.elements[idx].nextHash
        }
        return nil
    }
    
    
    /// primitive funnel method to create a copy of the backing for CoW semantics
    func mutableCopy() -> _OrderedSetBacking<Element> {
        return _OrderedSetBacking(_storage)
    }
}

public struct OrderedSet<Element : Hashable> {
    internal var _backing: _OrderedSetBacking<Element>
    
    public init() {
        _backing = _OrderedSetBacking<Element>()
    }
    
    // OrderedSet does not preserve identity or subclassing behavior when bridged
    // all bridges of references are O(n) complexity
    public init?(_ reference: NSOrderedSet) {
        guard let elements = reference.array as? [Element] else {
            return nil
        }
        self.init()
        for element in elements {
            append(element)
        }
    }
}

public struct OrderedSetIterator<Element : Hashable> : IteratorProtocol {
    var orderedSet: OrderedSet<Element>
    var index: Int?
    internal init(_ orderedSet: OrderedSet<Element>) {
        self.orderedSet = orderedSet
        // The OrderedSetIterator skips the amoritzed cost of the arrangedIndexes since it just needs to walk forward in the linked list of elements
        /// TODO: This probably could be abstracted into a funnel method
        index = orderedSet._backing._storage.first
    }
    
    public mutating func next() -> Element? {
        guard let idx = index else {
            return nil
        }
        /// TODO: This probably could be abstracted into a funnel method
        let element = orderedSet._backing._storage.elements[idx].value
        index = orderedSet._backing._storage.elements[idx].next
        return element
    }
}

extension OrderedSet : Sequence {
    public func makeIterator() -> OrderedSetIterator<Element> {
        return OrderedSetIterator(self)
    }
}

extension OrderedSet : Collection {
    public typealias Index = Int
    
    public subscript(position: Index) -> Element {
        get {
            return _backing[position]
        }
        set {
            _backing[position] = newValue
        }
    }
    
    public var count: Int {
        return _backing.count
    }
    
    public var isEmpty: Bool {
        return count == 0
    }
    
    public func index(after idx: Index) -> Index {
        return idx + 1
    }
    
    public var startIndex: Index {
        return 0
    }
    
    public var endIndex: Index {
        return count
    }
    
    public mutating func append(_ newElement: Element) {
        if !isKnownUniquelyReferenced(&_backing) {
            _backing = _backing.mutableCopy()
        }
        _backing.append(newElement)
    }
}

extension OrderedSet : BidirectionalCollection {
    public func index(before idx: Index) -> Index {
        return idx - 1
    }
}

extension OrderedSet : RangeReplaceableCollection {
    public init<S : Sequence>(_ sequence: S) where S.Iterator.Element == Element {
        self.init()
        for element in sequence {
            append(element)
        }
    }
    
    public mutating func replaceSubrange<C, R>(_ subrange: R, with newElements: C) where C : Collection, C.Iterator.Element == Element, R : RangeExpression, R.Bound == Index {
        if !isKnownUniquelyReferenced(&_backing) {
            _backing = _backing.mutableCopy()
        }
        
        _backing.replaceSubrange(subrange.relative(to: self), with: newElements)
    }
}

extension OrderedSet : Equatable {
    public static func ==(lhs: OrderedSet<Element>, rhs: OrderedSet<Element>) -> Bool {
        if lhs.count != rhs.count { return false }
        for element in lhs {
            if !rhs.contains(element) { return false }
        }
        return true
    }
}

extension OrderedSet : Hashable {
    public var hashValue: Int {
        get {
            /// TODO: this could be mixed better
            let cnt = count
            if cnt == 0 { return cnt.hashValue }
            if let element0 = first {
                if cnt == 1 { return cnt.hashValue ^ element0.hashValue }
                if let elementN = last {
                    return cnt.hashValue ^ element0.hashValue ^ elementN.hashValue
                }
            }
            return 0.hashValue
        }
    }
}

extension OrderedSet : ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Element...) {
        self.init()
        for element in elements {
            append(element)
        }
    }
}

extension OrderedSet : SetAlgebra {
    public mutating func formSymmetricDifference(_ other: OrderedSet<Element>) {
        if !isKnownUniquelyReferenced(&_backing) {
            _backing = _backing.mutableCopy()
        }
        let intersected = intersection(other)
        formUnion(other)
        for element in intersected {
            remove(element)
        }
    }
    
    public mutating func formIntersection(_ other: OrderedSet<Element>) {
        if !isKnownUniquelyReferenced(&_backing) {
            _backing = _backing.mutableCopy()
        }
        let unique: [Element] = flatMap { (element: Element) -> Element? in
            return other.contains(element) ? nil : element
        }
        for element in unique {
            remove(element)
        }
    }
    
    public mutating func formUnion(_ other: OrderedSet<Element>) {
        if !isKnownUniquelyReferenced(&_backing) {
            _backing = _backing.mutableCopy()
        }
        append(contentsOf: other)
    }
    
    @discardableResult
    public mutating func update(with newMember: Element) -> Element? {
        if !isKnownUniquelyReferenced(&_backing) {
            _backing = _backing.mutableCopy()
        }
        return _backing.update(with: newMember)
    }
    
    @discardableResult
    public mutating func remove(_ member: Element) -> Element? {
        if !isKnownUniquelyReferenced(&_backing) {
            _backing = _backing.mutableCopy()
        }
        return _backing.remove(member)
    }
    
    @discardableResult
    public mutating func insert(_ newMember: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        if !isKnownUniquelyReferenced(&_backing) {
            _backing = _backing.mutableCopy()
        }
        return _backing.append(newMember)
    }
    
    public func symmetricDifference(_ other: OrderedSet<Element>) -> OrderedSet<Element> {
        var set = self
        set.formSymmetricDifference(other)
        return set
    }
    
    public func intersection(_ other: OrderedSet<Element>) -> OrderedSet<Element> {
        var set = self
        set.formIntersection(other)
        return set
    }
    
    public func union(_ other: OrderedSet<Element>) -> OrderedSet<Element> {
        var set = self
        set.formUnion(other)
        return set
    }
    
    public mutating func subtract(_ other: OrderedSet<Element>) {
        for element in other {
            remove(element)
        }
    }
}

/// extension methods to apply SetAlgebra from Sequences
extension OrderedSet {
    public mutating func formSymmetricDifference<S: Sequence>(_ other: S) where S.Iterator.Element == Element {
        if !isKnownUniquelyReferenced(&_backing) {
            _backing = _backing.mutableCopy()
        }
        let intersected = intersection(other)
        formUnion(other)
        subtract(intersected)
    }
    
    public mutating func formIntersection<S: Sequence>(_ other: S) where S.Iterator.Element == Element {
        if !isKnownUniquelyReferenced(&_backing) {
            _backing = _backing.mutableCopy()
        }
        let unique: [Element] = flatMap { (element: Element) -> Element? in
            return other.contains(element) ? nil : element
        }
        for element in unique {
            remove(element)
        }
    }
    
    public mutating func formUnion<S: Sequence>(_ other: S) where S.Iterator.Element == Element {
        if !isKnownUniquelyReferenced(&_backing) {
            _backing = _backing.mutableCopy()
        }
        
        append(contentsOf: other)
    }
    
    public func symmetricDifference<S: Sequence>(_ other: S) -> OrderedSet<Element> where S.Iterator.Element == Element {
        var set = self
        set.formSymmetricDifference(other)
        return set
    }
    
    public func intersection<S: Sequence>(_ other: S) -> OrderedSet<Element> where S.Iterator.Element == Element {
        var set = self
        set.formIntersection(other)
        return set
    }
    
    public func union<S: Sequence>(_ other: S) -> OrderedSet<Element> where S.Iterator.Element == Element {
        var set = self
        set.formUnion(other)
        return set
    }
}

/// common objc like APIs from NSOrderedSet/NSMutableOrderedSet
extension OrderedSet {
    public init(array: Array<Element>) {
        self.init()
        for element in array {
            append(element)
        }
    }
    
    public func member(_ element: Element) -> Element? {
        return _backing.member(element)
    }
    
    public func isSubset<S: SetAlgebra>(of other: S) -> Bool where S.Element == Element {
        for element in self {
            if !other.contains(element) { return false }
        }
        return true
    }
    
    public func intersects<S: SetAlgebra>(_ other: S) -> Bool where S.Element == Element {
        for element in self {
            if other.contains(element) { return true }
        }
        return false
    }
    
    public mutating func subtract<S: SetAlgebra>(_ other: S) where S.Element == Element {
        let elementsToRemove = flatMap { other.contains($0) ? $0 : nil }
        for element in elementsToRemove {
            remove(element)
        }
    }
    
    public subscript(indexes: IndexSet) -> [Element] {
        get {
            var entries = [Element]()
            for idx in indexes {
                guard idx < count && idx >= 0 else {
                    fatalError("\(self): Index out of bounds")
                }
                entries.append(self[idx])
            }
            return entries
        }
        set {
            for (indexLocation, index) in indexes.enumerated() {
                self[index] = newValue[indexLocation]
            }
        }
    }
    
    public mutating func moveElements(at indexes: IndexSet, to idx: Int) {
        var removed = [Element]()
        for index in indexes.lazy.reversed() {
            let obj = self[index]
            removed.append(obj)
            remove(at: index)
            
        }
        for element in removed {
            insert(element, at: idx)
        }
    }
    
    public mutating func insert(_ elements: [Element], at indexes: IndexSet) {
        for (indexLocation, index) in indexes.enumerated() {
            insert(elements[indexLocation], at: index)
        }
    }
    
    public mutating func removeElements(at indexes: IndexSet) {
        for index in indexes.lazy.reversed() {
            remove(at: index)
        }
    }
    
    public mutating func sort(_ range: Range<Index>? = nil, options opts: NSSortOptions = [], usingComparator cmptr: (Element, Element) -> ComparisonResult) {
        let r: Range<Index>
        if let region = range {
            r = region
        } else {
            r = startIndex..<endIndex
        }
        if r.count < 2 { return }
        var values = self[r]
        var indexes = UnsafeMutablePointer<CFIndex>.allocate(capacity: r.count)
        defer { indexes.deallocate(capacity: r.count) }
        CFSortIndexes(indexes, r.count, CFOptionFlags(opts.rawValue)) { (idx1, idx2) -> CFComparisonResult in
            return CFComparisonResult(rawValue: cmptr(values[r.lowerBound + idx1], values[r.lowerBound + idx2]).rawValue)!
        }
        var list2 = UnsafeMutablePointer<Element>.allocate(capacity: r.count)
        defer { list2.deallocate(capacity: r.count) }
        for idx in 0..<r.count {
            list2.advanced(by: idx).initialize(to: values[indexes.advanced(by: idx).pointee + r.lowerBound])
        }
        replaceSubrange(r, with: UnsafeMutableBufferPointer(start: list2, count: r.count))
    }
}

#if DEPLOYMENT_RUNTIME_SWIFT
internal typealias OrderedSetBridgeType = _ObjectTypeBridgeable
#else
internal typealias OrderedSetBridgeType = _ObjectiveCBridgeable
#endif

extension OrderedSet : OrderedSetBridgeType {
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSOrderedSet?) -> OrderedSet<Element> {
        guard let src = source else {
            return OrderedSet<Element>()
        }
        return OrderedSet(src)!
    }
    
    @discardableResult
    public static func _conditionallyBridgeFromObjectiveC(_ source: NSOrderedSet, result: inout OrderedSet<Element>?) -> Bool {
        guard let res = OrderedSet<Element>(source) else {
            return false
        }
        result = res
        return true
    }
    
    public static func _forceBridgeFromObjectiveC(_ source: NSOrderedSet, result: inout OrderedSet<Element>?) {
        result = OrderedSet(source)
    }
    
    public func _bridgeToObjectiveC() -> NSOrderedSet {
        let mset = NSMutableOrderedSet()
        for element in self {
            mset.add(element)
        }
        return mset.copy() as! NSOrderedSet
    }
}



