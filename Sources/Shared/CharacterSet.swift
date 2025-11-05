//
//  File.swift
//  swift-urlrouting-multipart
//
//  Created by Coen ten Thije Boonkkamp on 26/07/2025.
//

import Foundation

extension CharacterSet {
    static let urlQueryParamAllowed = CharacterSet
        .urlQueryAllowed
        .subtracting(Self(charactersIn: ":#[]@!$&'()*+,;="))
}

//public extension CharacterSet {
//  static let urlQueryComponentAllowed = CharacterSet.urlQueryAllowed
//    .subtracting(CharacterSet(charactersIn: "&="))
//}
