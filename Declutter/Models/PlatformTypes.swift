//
//  PlatformTypes.swift
//  Declutter
//
//  Created by Kiro on 2025/12/05.
//

import Foundation

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif
