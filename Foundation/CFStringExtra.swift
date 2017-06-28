//
//  CFStringExtra.swift
//  SwiftFoundation
//
//  Created by Philippe Hausler on 6/24/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import CoreFoundation

#if os(OSX) || os(iOS)
internal let kCFStringEncodingMacRoman =  CFStringBuiltInEncodings.macRoman.rawValue
internal let kCFStringEncodingWindowsLatin1 =  CFStringBuiltInEncodings.windowsLatin1.rawValue
internal let kCFStringEncodingISOLatin1 =  CFStringBuiltInEncodings.isoLatin1.rawValue
internal let kCFStringEncodingNextStepLatin =  CFStringBuiltInEncodings.nextStepLatin.rawValue
internal let kCFStringEncodingASCII =  CFStringBuiltInEncodings.ASCII.rawValue
internal let kCFStringEncodingUnicode =  CFStringBuiltInEncodings.unicode.rawValue
internal let kCFStringEncodingUTF8 =  CFStringBuiltInEncodings.UTF8.rawValue
internal let kCFStringEncodingNonLossyASCII =  CFStringBuiltInEncodings.nonLossyASCII.rawValue
internal let kCFStringEncodingUTF16 = CFStringBuiltInEncodings.UTF16.rawValue
internal let kCFStringEncodingUTF16BE =  CFStringBuiltInEncodings.UTF16BE.rawValue
internal let kCFStringEncodingUTF16LE =  CFStringBuiltInEncodings.UTF16LE.rawValue
internal let kCFStringEncodingUTF32 =  CFStringBuiltInEncodings.UTF32.rawValue
internal let kCFStringEncodingUTF32BE =  CFStringBuiltInEncodings.UTF32BE.rawValue
internal let kCFStringEncodingUTF32LE =  CFStringBuiltInEncodings.UTF32LE.rawValue
    
internal let kCFStringGraphemeCluster = CFStringCharacterClusterType.graphemeCluster
internal let kCFStringComposedCharacterCluster = CFStringCharacterClusterType.composedCharacterCluster
internal let kCFStringCursorMovementCluster = CFStringCharacterClusterType.cursorMovementCluster
internal let kCFStringBackwardDeletionCluster = CFStringCharacterClusterType.backwardDeletionCluster

internal let kCFStringNormalizationFormD = CFStringNormalizationForm.D
internal let kCFStringNormalizationFormKD = CFStringNormalizationForm.KD
internal let kCFStringNormalizationFormC = CFStringNormalizationForm.C
internal let kCFStringNormalizationFormKC = CFStringNormalizationForm.KC
    
#endif
