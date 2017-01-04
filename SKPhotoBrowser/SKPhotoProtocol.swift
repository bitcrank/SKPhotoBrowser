//
//  SKPhoto.swift
//  SKViewExample
//
//  Created by suzuki_keishi on 2015/10/01.
//  Copyright © 2015 suzuki_keishi. All rights reserved.
//

import UIKit

@objc public protocol SKPhotoProtocol: NSObjectProtocol {
    var underlyingImage: UIImage! { get }
    var caption: String! { get }
    var index: Int { get set}
    var contentMode: UIViewContentMode { get set }
    func loadUnderlyingImageAndNotify()
    func checkCache()
}
