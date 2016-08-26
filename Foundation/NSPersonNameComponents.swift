// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


open class NSPersonNameComponents : NSObject, NSCopying, NSSecureCoding {
    
    public convenience required init?(coder aDecoder: NSCoder) {
        self.init()
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        func bridgeOptionalString(_ value: NSString?) -> String? {
            if let obj = value {
                return String._unconditionallyBridgeFromObjectiveC(obj)
            } else {
                return nil
            }
        }
        self.namePrefix = bridgeOptionalString(aDecoder.decodeObject(of: NSString.self, forKey: "NS.namePrefix") as NSString?)
        self.givenName = bridgeOptionalString(aDecoder.decodeObject(of: NSString.self, forKey: "NS.givenName") as NSString?)
        self.middleName = bridgeOptionalString(aDecoder.decodeObject(of: NSString.self, forKey: "NS.middleName") as NSString?)
        self.familyName = bridgeOptionalString(aDecoder.decodeObject(of: NSString.self, forKey: "NS.familyName") as NSString?)
        self.nameSuffix = bridgeOptionalString(aDecoder.decodeObject(of: NSString.self, forKey: "NS.nameSuffix") as NSString?)
        self.nickname = bridgeOptionalString(aDecoder.decodeObject(of: NSString.self, forKey: "NS.nickname") as NSString?)
    }
    
    static public var supportsSecureCoding: Bool { return true }
    
    open func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        aCoder.encode(self.namePrefix?._bridgeToObjectiveC(), forKey: "NS.namePrefix")
        aCoder.encode(self.givenName?._bridgeToObjectiveC(), forKey: "NS.givenName")
        aCoder.encode(self.middleName?._bridgeToObjectiveC(), forKey: "NS.middleName")
        aCoder.encode(self.familyName?._bridgeToObjectiveC(), forKey: "NS.familyName")
        aCoder.encode(self.nameSuffix?._bridgeToObjectiveC(), forKey: "NS.nameSuffix")
        aCoder.encode(self.nickname?._bridgeToObjectiveC(), forKey: "NS.nickname")
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        let comps = NSPersonNameComponents()
        comps.namePrefix = namePrefix
        comps.givenName = givenName
        comps.middleName = middleName
        comps.familyName = familyName
        comps.nameSuffix = nameSuffix
        comps.nickname = nickname
        return comps
    }
    
    /* The below examples all assume the full name Dr. Johnathan Maple Appleseed Esq., nickname "Johnny" */
    
    /* Pre-nominal letters denoting title, salutation, or honorific, e.g. Dr., Mr. */
    open var namePrefix: String?
    
    /* Name bestowed upon an individual by one's parents, e.g. Johnathan */
    open var givenName: String?
    
    /* Secondary given name chosen to differentiate those with the same first name, e.g. Maple  */
    open var middleName: String?
    
    /* Name passed from one generation to another to indicate lineage, e.g. Appleseed  */
    open var familyName: String?
    
    /* Post-nominal letters denoting degree, accreditation, or other honor, e.g. Esq., Jr., Ph.D. */
    open var nameSuffix: String?
    
    /* Name substituted for the purposes of familiarity, e.g. "Johnny"*/
    open var nickname: String?
    
    /* Each element of the phoneticRepresentation should correspond to an element of the original PersonNameComponents instance.
       The phoneticRepresentation of the phoneticRepresentation object itself will be ignored. nil by default, must be instantiated.
    */
    /*@NSCopying*/ open var phoneticRepresentation: PersonNameComponents?
    
    internal func isEqualToComponents(_ other: PersonNameComponents) -> Bool {
        if other.namePrefix != namePrefix {
            return false
        }
        if other.givenName != givenName {
            return false
        }
        if other.middleName != middleName {
            return false
        }
        if other.familyName != familyName {
            return false
        }
        if other.nameSuffix != nameSuffix {
            return false
        }
        if other.nickname != nickname {
            return false
        }
        return true
    }
    
    open override func isEqual(_ value: Any?) -> Bool {
        if let other = value as? PersonNameComponents {
            return isEqualToComponents(other)
        } else if let other = value as? NSPersonNameComponents {
            return isEqualToComponents(PersonNameComponents._unconditionallyBridgeFromObjectiveC(other))
        }
        return false
    }
}

extension NSPersonNameComponents : _StructTypeBridgeable {
    public typealias _StructType = PersonNameComponents

    public func _bridgeToSwift() -> _StructType {
        return PersonNameComponents._unconditionallyBridgeFromObjectiveC(self)
    }
}
