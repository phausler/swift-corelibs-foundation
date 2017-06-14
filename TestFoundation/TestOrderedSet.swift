// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
    import Foundation
    import XCTest
#else
    import SwiftFoundation
    import SwiftXCTest
#endif



class TestOrderedSet : XCTestCase {
    
    static var allTests: [(String, (TestOrderedSet) -> () throws -> Void)] {
        return [
            ("test_BasicConstruction", test_BasicConstruction),
            ("test_Enumeration", test_Enumeration),
            ("test_Uniqueness", test_Uniqueness),
            ("test_reversedEnumeration", test_reversedEnumeration),
            ("test_reversedOrderedSet", test_reversedOrderedSet),
            ("test_ObjectAtIndex", test_ObjectAtIndex),
            ("test_FirstAndLastObjects", test_FirstAndLastObjects),
            ("test_Append", test_Append),
            ("test_AppendContentsOf", test_AppendContentsOf),
            ("test_RemoveAll", test_RemoveAll),
            ("test_Remove", test_Remove),
            ("test_RemoveAtIndex", test_RemoveAtIndex),
            ("test_IsEqualToOrderedSet", test_IsEqualToOrderedSet),
            ("test_Subsets", test_Subsets),
            ("test_Replace", test_Replace),
            ("test_Insert", test_Insert),
            ("test_SetAtIndex", test_SetAtIndex),
            ("test_RemoveSubrange", test_RemoveSubrange),
            ("test_Intersection", test_Intersection),
            ("test_Subtraction", test_Subtraction),
            ("test_Union", test_Union),
            ("test_Initializers", test_Initializers),
            ("test_Sorting", test_Sorting),
        ]
    }
    
    func test_BasicConstruction() {
        let set = OrderedSet<String>()
        let set2 = OrderedSet(["foo", "bar"])
        XCTAssertEqual(set.count, 0)
        XCTAssertEqual(set2.count, 2)
    }
    
    func test_Enumeration() {
        let arr = ["foo", "bar", "bar"]
        let set = OrderedSet(arr)
        var index = 0
        for item in set {
            XCTAssertEqual(arr[index], item)
            index += 1
        }
    }
    
    func test_Uniqueness() {
        let set = OrderedSet(["foo", "bar", "bar"])
        XCTAssertEqual(set.count, 2)
        XCTAssertEqual(set[0], "foo")
        XCTAssertEqual(set[1], "bar")
    }
    
    func test_reversedEnumeration() {
        let arr = ["foo", "bar", "baz"]
        let set = OrderedSet(arr)
        var index = set.count - 1
        let revSet = set.reversed()
        for item in revSet {
            XCTAssertEqual(set[index], item)
            index -= 1
        }
    }
    
    func test_reversedOrderedSet() {
        let days = ["monday", "tuesday", "wednesday", "thursday", "friday"]
        let work = OrderedSet(days)
        let krow = work.reversed()
        var index = work.count - 1
        for item in krow {
            XCTAssertEqual(work[index], item)
            index -= 1
        }
    }
    
    func test_ObjectAtIndex() {
        let set = OrderedSet(["foo", "bar", "baz"])
        XCTAssertEqual(set[0], "foo")
        XCTAssertEqual(set[1], "bar")
        XCTAssertEqual(set[2], "baz")
    }
    
    func test_FirstAndLastObjects() {
        let set = OrderedSet(["foo", "bar", "baz"])
        XCTAssertEqual(set.first, "foo")
        XCTAssertEqual(set.last, "baz")
    }
    
    func test_Append() {
        var set = OrderedSet<String>()
        set.append("1")
        set.append("2")
        XCTAssertEqual(set[0], "1")
        XCTAssertEqual(set[1], "2")
    }
    
    func test_AppendContentsOf() {
        var set = OrderedSet<String>()
        set.append(contentsOf: ["foo", "bar", "baz"])
        XCTAssertEqual(set[0], "foo")
        XCTAssertEqual(set[1], "bar")
        XCTAssertEqual(set[2], "baz")
    }
    
    func test_RemoveAll() {
        var set = OrderedSet<String>()
        set.append(contentsOf: ["foo", "bar", "baz"])
        XCTAssertEqual(set.index(of: "foo"), 0)
        set.removeAll()
        XCTAssertEqual(set.count, 0)
        XCTAssertEqual(set.index(of: "foo"), nil)
    }
    
    func test_Remove() {
        var set = OrderedSet<String>()
        set.append(contentsOf: ["foo", "bar", "baz"])
        set.remove("bar")
        XCTAssertEqual(set.count, 2)
        XCTAssertEqual(set.index(of: "baz"), 1)
    }
    
    func test_RemoveAtIndex() {
        var set = OrderedSet<String>()
        set.append(contentsOf: ["foo", "bar", "baz"])
        set.remove(at: 1)
        XCTAssertEqual(set.count, 2)
        XCTAssertEqual(set.index(of: "baz"), 1)
    }
    
    func test_IsEqualToOrderedSet() {
        let set = OrderedSet(["foo", "bar", "baz"])
        let otherSet = OrderedSet(["foo", "bar", "baz"])
        let otherOtherSet = OrderedSet(["foo", "bar", "123"])
        XCTAssertEqual(set, otherSet)
        XCTAssertNotEqual(set, otherOtherSet)
    }
    
    func test_Subsets() {
        let set = OrderedSet(["foo", "bar", "baz"])
        let otherOrderedSet = OrderedSet(["foo", "bar"])
        let otherSet = Set(["foo", "baz"])
        let otherOtherSet = Set(["foo", "bar", "baz", "123"])
        XCTAssert(otherOrderedSet.isSubset(of: set))
        XCTAssertFalse(set.isSubset(of: otherOrderedSet))
        XCTAssertFalse(set.isSubset(of: otherSet))
        XCTAssert(set.isSubset(of: otherOtherSet))
    }
    
    
    func test_Replace() {
        var set: OrderedSet<String> = ["foo", "bar", "baz"]
        set[1] = "123"
        set[2] = "456"
        XCTAssertEqual(set.count, 3)
        XCTAssertEqual(set[0], "foo")
        XCTAssertEqual(set[1], "123")
        XCTAssertEqual(set[2], "456")
    }
    
    func test_Insert() {
        var set = OrderedSet<String>()
        set.insert("foo", at: 0)
        XCTAssertEqual(set.count, 1)
        XCTAssertEqual(set[0], "foo")
        set.insert("bar", at: 1)
        XCTAssertEqual(set.count, 2)
        XCTAssertEqual(set[1], "bar")
    }
    
    func test_SetAtIndex() {
        var set = OrderedSet(arrayLiteral: "foo", "bar", "baz")
        set[1] = "123"
        XCTAssertEqual(set[0], "foo")
        XCTAssertEqual(set[1], "123")
        XCTAssertEqual(set[2], "baz")
        set[3] = "456"
        XCTAssertEqual(set[3], "456")
    }
    
    func test_RemoveSubrange() {
        var set = OrderedSet(arrayLiteral: "foo", "bar", "baz", "123", "456")
        set.removeSubrange(1...2)
        XCTAssertEqual(set.count, 3)
        XCTAssertEqual(set[0], "foo")
        XCTAssertEqual(set[1], "123")
        XCTAssertEqual(set[2], "456")
    }
    
    func test_Intersection() {
        var set = OrderedSet(arrayLiteral: "foo", "bar", "baz")
        let otherSet = OrderedSet(array: ["foo", "baz"])
        XCTAssert(set.intersects(otherSet))
        let otherOtherSet = Set(["foo", "123"])
        XCTAssert(set.intersects(otherOtherSet))
        set.formIntersection(otherSet)
        XCTAssertEqual(set.count, 2)
        XCTAssertEqual(set[0], "foo")
        XCTAssertEqual(set[1], "baz")
        set.formIntersection(otherOtherSet)
        XCTAssertEqual(set.count, 1)
        XCTAssertEqual(set[0], "foo")
        
        let nonIntersectingSet = Set(["asdf"])
        XCTAssertFalse(set.intersects(nonIntersectingSet))
    }
    
    func test_Subtraction() {
        var set = OrderedSet(arrayLiteral: "foo", "bar", "baz")
        let otherSet = OrderedSet(array: ["baz"])
        let otherOtherSet = Set(["foo"])
        set.subtract(otherSet)
        XCTAssertEqual(set.count, 2)
        XCTAssertEqual(set[0], "foo")
        XCTAssertEqual(set[1], "bar")
        set.subtract(otherOtherSet)
        XCTAssertEqual(set.count, 1)
        XCTAssertEqual(set[0], "bar")
    }
    
    func test_Union() {
        var set = OrderedSet(arrayLiteral: "foo", "bar", "baz")
        let otherSet = OrderedSet(array: ["123", "baz"])
        let otherOtherSet = Set(["foo", "456"])
        set.formUnion(otherSet)
        XCTAssertEqual(set.count, 4)
        XCTAssertEqual(set[0], "foo")
        XCTAssertEqual(set[1], "bar")
        XCTAssertEqual(set[2], "baz")
        XCTAssertEqual(set[3], "123")
        set.formUnion(otherOtherSet)
        XCTAssertEqual(set.count, 5)
        XCTAssertEqual(set[4], "456")
    }
    
    func test_Initializers() {
        let copyableObject = NSObject()
        let set = OrderedSet<AnyHashable>(arrayLiteral: copyableObject, "bar", "baz")
        let newSet = OrderedSet(set)
        XCTAssertEqual(newSet, set)
        //        XCTAssert(set[0] === newSet[0])
        
        let unorderedSet = Set<AnyHashable>(["foo", "bar", "baz"])
        let newSetFromUnorderedSet = OrderedSet(unorderedSet)
        XCTAssertEqual(newSetFromUnorderedSet.count, 3)
        XCTAssert(newSetFromUnorderedSet.contains("foo"))
    }
    
    func test_Sorting() {
        var set = OrderedSet(arrayLiteral: "a", "d", "c", "b")
        
        set.sort(options: []) { lhs, rhs in
            return lhs.compare(rhs)
        }
        XCTAssertEqual(set[0], "a")
        XCTAssertEqual(set[1], "b")
        XCTAssertEqual(set[2], "c")
        XCTAssertEqual(set[3], "d")
        
        set.sort(1..<3, options: []) { lhs, rhs in
            return rhs.compare(lhs)
        }
        XCTAssertEqual(set[0], "a")
        XCTAssertEqual(set[1], "c")
        XCTAssertEqual(set[2], "b")
        XCTAssertEqual(set[3], "d")
    }
}
