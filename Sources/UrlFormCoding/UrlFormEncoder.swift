import Foundation

public final class UrlFormEncoder: Encoder {
    private var container: Container?
    public private(set) var codingPath: [CodingKey] = []
    public var dataEncodingStrategy: DataEncodingStrategy = .deferredToData
    public var dateEncodingStrategy: DateEncodingStrategy = .deferredToDate
    public let userInfo: [CodingUserInfoKey: Any] = [:]

    public init() {}

    public func encode<T: Encodable>(_ value: T) throws -> Data {
        try value.encode(to: self)
        guard let container = self.container else {
            throw Error.encodingError("No container found", self.codingPath)
        }

        let queryString = serialize(container)
        return Data(queryString.utf8)
    }

    private func box<T: Encodable>(_ value: T) throws -> Container {
        if let date = value as? Date {
            return try self.box(date)
        } else if let data = value as? Data {
            return try self.box(data)
        }

        let encoder = UrlFormEncoder()
        try value.encode(to: encoder)
        guard let container = encoder.container else {
            throw Error.encodingError("No container found", encoder.codingPath)
        }
        return container
    }

    private func box(_ date: Date) throws -> Container {
        switch self.dateEncodingStrategy {
        case .deferredToDate:
            let encoder = UrlFormEncoder()
            try date.encode(to: encoder)
            guard let container = encoder.container else {
                throw Error.encodingError("No container found", encoder.codingPath)
            }
            return container
        case .secondsSince1970:
            return .singleValue(String(date.timeIntervalSince1970))
        case .millisecondsSince1970:
            return .singleValue(String(date.timeIntervalSince1970 * 1000))
        case .iso8601:
            return .singleValue(iso8601DateFormatter.string(from: date))
        case let .formatted(formatter):
            return .singleValue(formatter.string(from: date))
        case let .custom(strategy):
            return .singleValue(strategy(date))
        }
    }

    private func box(_ data: Data) throws -> Container {
        switch self.dataEncodingStrategy {
        case .deferredToData:
            let encoder = UrlFormEncoder()
            try data.encode(to: encoder)
            guard let container = encoder.container else {
                throw Error.encodingError("No container found", encoder.codingPath)
            }
            return container
        case .base64:
            return .singleValue(data.base64EncodedString())
        case let .custom(strategy):
            return .singleValue(strategy(data))
        }
    }

    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        let container = KeyedContainer<Key>(encoder: self)
        self.container = .keyed([:])
        return KeyedEncodingContainer(container)
    }

    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        let container = UnkeyedContainer(encoder: self)
        self.container = .unkeyed([])
        return container
    }

    public func singleValueContainer() -> SingleValueEncodingContainer {
        let container = SingleValueContainer(encoder: self)
        self.container = nil
        return container
    }

    public enum Error: Swift.Error {
        case encodingError(String, [CodingKey])
    }

    struct KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        private let encoder: UrlFormEncoder

        var codingPath: [CodingKey] {
            return self.encoder.codingPath
        }

        init(encoder: UrlFormEncoder) {
            self.encoder = encoder
        }

        mutating func encodeNil(forKey key: Key) throws {
            var container = self.encoder.container?.params ?? [:]
            container[key.stringValue] = .singleValue("")
            self.encoder.container = .keyed(container)
        }

        mutating func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
            self.encoder.codingPath.append(key)
            defer { self.encoder.codingPath.removeLast() }
            var container = self.encoder.container?.params ?? [:]
            container[key.stringValue] = try self.encoder.box(value)
            self.encoder.container = .keyed(container)
        }

        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
            self.encoder.codingPath.append(key)
            defer { self.encoder.codingPath.removeLast() }
            let container = KeyedContainer<NestedKey>(encoder: self.encoder)
            var params = self.encoder.container?.params ?? [:]
            params[key.stringValue] = .keyed([:])
            self.encoder.container = .keyed(params)
            return KeyedEncodingContainer(container)
        }

        mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            self.encoder.codingPath.append(key)
            defer { self.encoder.codingPath.removeLast() }
            let container = UnkeyedContainer(encoder: self.encoder)
            var params = self.encoder.container?.params ?? [:]
            params[key.stringValue] = .unkeyed([])
            self.encoder.container = .keyed(params)
            return container
        }

        mutating func superEncoder() -> Encoder {
            fatalError("Not implemented")
        }

        mutating func superEncoder(forKey key: Key) -> Encoder {
            fatalError("Not implemented")
        }
    }

    struct UnkeyedContainer: UnkeyedEncodingContainer {
        private let encoder: UrlFormEncoder

        var codingPath: [CodingKey] {
            return self.encoder.codingPath
        }

        var count: Int {
            return self.encoder.container?.values?.count ?? 0
        }

        init(encoder: UrlFormEncoder) {
            self.encoder = encoder
        }

        mutating func encodeNil() throws {
            var values = self.encoder.container?.values ?? []
            values.append(.singleValue(""))
            self.encoder.container = .unkeyed(values)
        }

        mutating func encode<T>(_ value: T) throws where T: Encodable {
            var values = self.encoder.container?.values ?? []
            values.append(try self.encoder.box(value))
            self.encoder.container = .unkeyed(values)
        }

        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
            let container = KeyedContainer<NestedKey>(encoder: self.encoder)
            var values = self.encoder.container?.values ?? []
            values.append(.keyed([:]))
            self.encoder.container = .unkeyed(values)
            return KeyedEncodingContainer(container)
        }

        mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            let container = UnkeyedContainer(encoder: self.encoder)
            var values = self.encoder.container?.values ?? []
            values.append(.unkeyed([]))
            self.encoder.container = .unkeyed(values)
            return container
        }

        mutating func superEncoder() -> Encoder {
            fatalError("Not implemented")
        }
    }

    struct SingleValueContainer: SingleValueEncodingContainer {
        private let encoder: UrlFormEncoder

        var codingPath: [CodingKey] = []

        init(encoder: UrlFormEncoder) {
            self.encoder = encoder
        }

        mutating func encodeNil() throws {
            self.encoder.container = .singleValue("")
        }

        mutating func encode(_ value: Bool) throws {
            try encode(value ? "true" : "false")
        }

        mutating func encode(_ value: String) throws {
            let encoded = value.addingPercentEncoding(withAllowedCharacters: .urlQueryParamAllowed) ?? value
            self.encoder.container = .singleValue(encoded)
        }

        mutating func encode(_ value: Double) throws {
            try encode(String(value))
        }

        mutating func encode(_ value: Float) throws {
            try encode(String(value))
        }

        mutating func encode(_ value: Int) throws {
            try encode(String(value))
        }

        mutating func encode(_ value: Int8) throws {
            try encode(String(value))
        }

        mutating func encode(_ value: Int16) throws {
            try encode(String(value))
        }

        mutating func encode(_ value: Int32) throws {
            try encode(String(value))
        }

        mutating func encode(_ value: Int64) throws {
            try encode(String(value))
        }

        mutating func encode(_ value: UInt) throws {
            try encode(String(value))
        }

        mutating func encode(_ value: UInt8) throws {
            try encode(String(value))
        }

        mutating func encode(_ value: UInt16) throws {
            try encode(String(value))
        }

        mutating func encode(_ value: UInt32) throws {
            try encode(String(value))
        }

        mutating func encode(_ value: UInt64) throws {
            try encode(String(value))
        }

        mutating func encode<T>(_ value: T) throws where T: Encodable {
            if let strValue = value as? String {
                try encode(strValue)
            } else {
                let encoded = String(describing: value).addingPercentEncoding(withAllowedCharacters: .urlQueryParamAllowed) ?? String(describing: value)
                self.encoder.container = .singleValue(encoded)
            }
        }
    }

    public enum DataEncodingStrategy {
        case deferredToData
        case base64
        case custom((Data) -> String)
    }

    public enum DateEncodingStrategy {
        case deferredToDate
        case secondsSince1970
        case millisecondsSince1970
        case iso8601
        case formatted(DateFormatter)
        case custom((Date) -> String)
    }

    public enum Container {
        indirect case keyed([String: Container])
        indirect case unkeyed([Container])
        case singleValue(String)

        var params: [String: Container]? {
            switch self {
            case let .keyed(params):
                return params
            case .unkeyed, .singleValue:
                return nil
            }
        }

        var values: [Container]? {
            switch self {
            case let .unkeyed(values):
                return values
            case .keyed, .singleValue:
                return nil
            }
        }

        var value: String? {
            switch self {
            case let .singleValue(value):
                return value
            case .keyed, .unkeyed:
                return nil
            }
        }
    }
}

private func serialize(_ container: UrlFormEncoder.Container, prefix: String = "") -> String {
    switch container {
    case let .keyed(dict):
        return dict.sorted(by: { $0.key < $1.key }).map { key, value in
            let newPrefix = prefix.isEmpty ? key : "\(prefix)[\(key)]"
            return serialize(value, prefix: newPrefix)
        }.joined(separator: "&")

    case let .unkeyed(array):
        return array.enumerated().map { idx, value in
            let newPrefix = "\(prefix)[\(idx)]"
            return serialize(value, prefix: newPrefix)
        }
        .joined(separator: "&")

    case let .singleValue(value):
        return prefix.isEmpty ? value : "\(prefix)=\(value)"
    }
}

private let iso8601DateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(abbreviation: "GMT")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
    return formatter
}()



////
////  File.swift
////  swift-web
////
////  Created by Coen ten Thije Boonkkamp on 05/01/2025.
////
//
// import Foundation
//
//
//// x-www-form-urlencoded
// public final class UrlFormEncoder: Encoder {
//    private var container: Container?
//    public private(set) var codingPath: [CodingKey] = []
//    public var dataEncodingStrategy: DataEncodingStrategy = .deferredToData
//    public var dateEncodingStrategy: DateEncodingStrategy = .deferredToDate
//    public let userInfo: [CodingUserInfoKey: Any] = [:]
//    
//    public init() {}
//    
//    public func encode<T: Encodable>(_ value: T) throws -> Data {
//        try value.encode(to: self)
//        guard let container = self.container else {
//            throw Error.encodingError("No container found", self.codingPath)
//        }
//        
//        let queryString = serialize(container)
//        return Data(queryString.utf8)
//    }
//    
//    private func box<T: Encodable>(_ value: T) throws -> Container {
//        if let date = value as? Date {
//            return try self.box(date)
//        } else if let data = value as? Data {
//            return try self.box(data)
//        }
//        
//        let encoder = UrlFormEncoder()
//        try value.encode(to: encoder)
//        guard let container = encoder.container else {
//            throw Error.encodingError("No container found", encoder.codingPath)
//        }
//        return container
//    }
//    
//    private func box(_ date: Date) throws -> Container {
//        switch self.dateEncodingStrategy {
//        case .deferredToDate:
//            let encoder = UrlFormEncoder()
//            try date.encode(to: encoder)
//            guard let container = encoder.container else {
//                throw Error.encodingError("No container found", encoder.codingPath)
//            }
//            return container
//        case .secondsSince1970:
//            return .singleValue(String(date.timeIntervalSince1970))
//        case .millisecondsSince1970:
//            return .singleValue(String(date.timeIntervalSince1970 * 1000))
//        case .iso8601:
//            return .singleValue(iso8601DateFormatter.string(from: date))
//        case let .formatted(formatter):
//            return .singleValue(formatter.string(from: date))
//        case let .custom(strategy):
//            return .singleValue(strategy(date))
//        }
//    }
//    
//    private func box(_ data: Data) throws -> Container {
//        switch self.dataEncodingStrategy {
//        case .deferredToData:
//            let encoder = UrlFormEncoder()
//            try data.encode(to: encoder)
//            guard let container = encoder.container else {
//                throw Error.encodingError("No container found", encoder.codingPath)
//            }
//            return container
//        case .base64:
//            return .singleValue(data.base64EncodedString())
//        case let .custom(strategy):
//            return .singleValue(strategy(data))
//        }
//    }
//    
//    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
//        let container = KeyedContainer<Key>(encoder: self)
//        self.container = .keyed([:])
//        return KeyedEncodingContainer(container)
//    }
//    
//    public func unkeyedContainer() -> UnkeyedEncodingContainer {
//        let container = UnkeyedContainer(encoder: self)
//        self.container = .unkeyed([])
//        return container
//    }
//    
//    public func singleValueContainer() -> SingleValueEncodingContainer {
//        let container = SingleValueContainer(encoder: self)
//        self.container = nil
//        return container
//    }
//    
//    public enum Error: Swift.Error {
//        case encodingError(String, [CodingKey])
//    }
//    
//    struct KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
//        private let encoder: UrlFormEncoder
//        
//        var codingPath: [CodingKey] {
//            return self.encoder.codingPath
//        }
//        
//        init(encoder: UrlFormEncoder) {
//            self.encoder = encoder
//        }
//        
//        mutating func encodeNil(forKey key: Key) throws {
//            var container = self.encoder.container?.params ?? [:]
//            container[key.stringValue] = .singleValue("")
//            self.encoder.container = .keyed(container)
//        }
//        
//        mutating func encode(_ value: Bool, forKey key: Key) throws {
//            var container = self.encoder.container?.params ?? [:]
//            container[key.stringValue] = .singleValue(value ? "true" : "false")
//            self.encoder.container = .keyed(container)
//        }
//        
//        mutating func encode(_ value: Int, forKey key: Key) throws {
//            var container = self.encoder.container?.params ?? [:]
//            container[key.stringValue] = .singleValue(String(value))
//            self.encoder.container = .keyed(container)
//        }
//        
//        mutating func encode(_ value: Int8, forKey key: Key) throws {
//            var container = self.encoder.container?.params ?? [:]
//            container[key.stringValue] = .singleValue(String(value))
//            self.encoder.container = .keyed(container)
//        }
//        
//        mutating func encode(_ value: Int16, forKey key: Key) throws {
//            var container = self.encoder.container?.params ?? [:]
//            container[key.stringValue] = .singleValue(String(value))
//            self.encoder.container = .keyed(container)
//        }
//        
//        mutating func encode(_ value: Int32, forKey key: Key) throws {
//            var container = self.encoder.container?.params ?? [:]
//            container[key.stringValue] = .singleValue(String(value))
//            self.encoder.container = .keyed(container)
//        }
//        
//        mutating func encode(_ value: Int64, forKey key: Key) throws {
//            var container = self.encoder.container?.params ?? [:]
//            container[key.stringValue] = .singleValue(String(value))
//            self.encoder.container = .keyed(container)
//        }
//        
//        mutating func encode(_ value: UInt, forKey key: Key) throws {
//            var container = self.encoder.container?.params ?? [:]
//            container[key.stringValue] = .singleValue(String(value))
//            self.encoder.container = .keyed(container)
//        }
//        
//        mutating func encode(_ value: UInt8, forKey key: Key) throws {
//            var container = self.encoder.container?.params ?? [:]
//            container[key.stringValue] = .singleValue(String(value))
//            self.encoder.container = .keyed(container)
//        }
//        
//        mutating func encode(_ value: UInt16, forKey key: Key) throws {
//            var container = self.encoder.container?.params ?? [:]
//            container[key.stringValue] = .singleValue(String(value))
//            self.encoder.container = .keyed(container)
//        }
//        
//        mutating func encode(_ value: UInt32, forKey key: Key) throws {
//            var container = self.encoder.container?.params ?? [:]
//            container[key.stringValue] = .singleValue(String(value))
//            self.encoder.container = .keyed(container)
//        }
//        
//        mutating func encode(_ value: UInt64, forKey key: Key) throws {
//            var container = self.encoder.container?.params ?? [:]
//            container[key.stringValue] = .singleValue(String(value))
//            self.encoder.container = .keyed(container)
//        }
//        
//        mutating func encode(_ value: Float, forKey key: Key) throws {
//            var container = self.encoder.container?.params ?? [:]
//            container[key.stringValue] = .singleValue(String(value))
//            self.encoder.container = .keyed(container)
//        }
//        
//        mutating func encode(_ value: Double, forKey key: Key) throws {
//            var container = self.encoder.container?.params ?? [:]
//            container[key.stringValue] = .singleValue(String(value))
//            self.encoder.container = .keyed(container)
//        }
//        
//        mutating func encode(_ value: String, forKey key: Key) throws {
//            var container = self.encoder.container?.params ?? [:]
//            container[key.stringValue] = .singleValue(value)
//            self.encoder.container = .keyed(container)
//        }
//        
//        mutating func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
//            self.encoder.codingPath.append(key)
//            defer { self.encoder.codingPath.removeLast() }
//            var container = self.encoder.container?.params ?? [:]
//            container[key.stringValue] = try self.encoder.box(value)
//            self.encoder.container = .keyed(container)
//        }
//        
//        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
//            self.encoder.codingPath.append(key)
//            defer { self.encoder.codingPath.removeLast() }
//            let container = KeyedContainer<NestedKey>(encoder: self.encoder)
//            var params = self.encoder.container?.params ?? [:]
//            params[key.stringValue] = .keyed([:])
//            self.encoder.container = .keyed(params)
//            return KeyedEncodingContainer(container)
//        }
//        
//        mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
//            self.encoder.codingPath.append(key)
//            defer { self.encoder.codingPath.removeLast() }
//            let container = UnkeyedContainer(encoder: self.encoder)
//            var params = self.encoder.container?.params ?? [:]
//            params[key.stringValue] = .unkeyed([])
//            self.encoder.container = .keyed(params)
//            return container
//        }
//        
//        mutating func superEncoder() -> Encoder {
//            fatalError("Not implemented")
//        }
//        
//        mutating func superEncoder(forKey key: Key) -> Encoder {
//            fatalError("Not implemented")
//        }
//    }
//    
//    struct UnkeyedContainer: UnkeyedEncodingContainer {
//        private let encoder: UrlFormEncoder
//        
//        var codingPath: [CodingKey] {
//            return self.encoder.codingPath
//        }
//        var count: Int {
//            return self.encoder.container?.values?.count ?? 0
//        }
//        
//        init(encoder: UrlFormEncoder) {
//            self.encoder = encoder
//        }
//        
//        mutating func encodeNil() throws {
//            var values = self.encoder.container?.values ?? []
//            values.append(.singleValue(""))
//            self.encoder.container = .unkeyed(values)
//        }
//        
//        mutating func encode(_ value: Bool) throws {
//            var values = self.encoder.container?.values ?? []
//            values.append(.singleValue(value ? "true" : "false"))
//            self.encoder.container = .unkeyed(values)
//        }
//        
//        mutating func encode(_ value: Int) throws {
//            var values = self.encoder.container?.values ?? []
//            values.append(.singleValue(String(value)))
//            self.encoder.container = .unkeyed(values)
//        }
//        
//        mutating func encode(_ value: Int8) throws {
//            var values = self.encoder.container?.values ?? []
//            values.append(.singleValue(String(value)))
//            self.encoder.container = .unkeyed(values)
//        }
//        
//        mutating func encode(_ value: Int16) throws {
//            var values = self.encoder.container?.values ?? []
//            values.append(.singleValue(String(value)))
//            self.encoder.container = .unkeyed(values)
//        }
//        
//        mutating func encode(_ value: Int32) throws {
//            var values = self.encoder.container?.values ?? []
//            values.append(.singleValue(String(value)))
//            self.encoder.container = .unkeyed(values)
//        }
//        
//        mutating func encode(_ value: Int64) throws {
//            var values = self.encoder.container?.values ?? []
//            values.append(.singleValue(String(value)))
//            self.encoder.container = .unkeyed(values)
//        }
//        
//        mutating func encode(_ value: UInt) throws {
//            var values = self.encoder.container?.values ?? []
//            values.append(.singleValue(String(value)))
//            self.encoder.container = .unkeyed(values)
//        }
//        
//        mutating func encode(_ value: UInt8) throws {
//            var values = self.encoder.container?.values ?? []
//            values.append(.singleValue(String(value)))
//            self.encoder.container = .unkeyed(values)
//        }
//        
//        mutating func encode(_ value: UInt16) throws {
//            var values = self.encoder.container?.values ?? []
//            values.append(.singleValue(String(value)))
//            self.encoder.container = .unkeyed(values)
//        }
//        
//        mutating func encode(_ value: UInt32) throws {
//            var values = self.encoder.container?.values ?? []
//            values.append(.singleValue(String(value)))
//            self.encoder.container = .unkeyed(values)
//        }
//        
//        mutating func encode(_ value: UInt64) throws {
//            var values = self.encoder.container?.values ?? []
//            values.append(.singleValue(String(value)))
//            self.encoder.container = .unkeyed(values)
//        }
//        
//        mutating func encode(_ value: Float) throws {
//            var values = self.encoder.container?.values ?? []
//            values.append(.singleValue(String(value)))
//            self.encoder.container = .unkeyed(values)
//        }
//        
//        mutating func encode(_ value: Double) throws {
//            var values = self.encoder.container?.values ?? []
//            values.append(.singleValue(String(value)))
//            self.encoder.container = .unkeyed(values)
//        }
//        
//        mutating func encode(_ value: String) throws {
//            var values = self.encoder.container?.values ?? []
//            values.append(.singleValue(value))
//            self.encoder.container = .unkeyed(values)
//        }
//        
//        mutating func encode<T>(_ value: T) throws where T: Encodable {
//            var values = self.encoder.container?.values ?? []
//            values.append(try self.encoder.box(value))
//            self.encoder.container = .unkeyed(values)
//        }
//        
//        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
//            let container = KeyedContainer<NestedKey>(encoder: self.encoder)
//            var values = self.encoder.container?.values ?? []
//            values.append(.keyed([:]))
//            self.encoder.container = .unkeyed(values)
//            return KeyedEncodingContainer(container)
//        }
//        
//        mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
//            let container = UnkeyedContainer(encoder: self.encoder)
//            var values = self.encoder.container?.values ?? []
//            values.append(.unkeyed([]))
//            self.encoder.container = .unkeyed(values)
//            return container
//        }
//        
//        mutating func superEncoder() -> Encoder {
//            fatalError("Not implemented")
//        }
//    }
//    struct SingleValueContainer: SingleValueEncodingContainer {
//        private let encoder: UrlFormEncoder
//        
//        var codingPath: [CodingKey] {
//            return self.encoder.codingPath
//        }
//        
//        init(encoder: UrlFormEncoder) {
//            self.encoder = encoder
//        }
//        
//        mutating func encodeNil() throws {
//            self.encoder.container = .singleValue("")
//        }
//        
//        mutating func encode(_ value: Bool) throws {
//            self.encoder.container = .singleValue(value ? "true" : "false")
//        }
//        
//        mutating func encode(_ value: Int) throws {
//            self.encoder.container = .singleValue(String(value))
//        }
//        
//        mutating func encode(_ value: Int8) throws {
//            self.encoder.container = .singleValue(String(value))
//        }
//        
//        mutating func encode(_ value: Int16) throws {
//            self.encoder.container = .singleValue(String(value))
//        }
//        
//        mutating func encode(_ value: Int32) throws {
//            self.encoder.container = .singleValue(String(value))
//        }
//        
//        mutating func encode(_ value: Int64) throws {
//            self.encoder.container = .singleValue(String(value))
//        }
//        
//        mutating func encode(_ value: UInt) throws {
//            self.encoder.container = .singleValue(String(value))
//        }
//        
//        mutating func encode(_ value: UInt8) throws {
//            self.encoder.container = .singleValue(String(value))
//        }
//        
//        mutating func encode(_ value: UInt16) throws {
//            self.encoder.container = .singleValue(String(value))
//        }
//        
//        mutating func encode(_ value: UInt32) throws {
//            self.encoder.container = .singleValue(String(value))
//        }
//        
//        mutating func encode(_ value: UInt64) throws {
//            self.encoder.container = .singleValue(String(value))
//        }
//        
//        mutating func encode(_ value: Float) throws {
//            self.encoder.container = .singleValue(String(value))
//        }
//        
//        mutating func encode(_ value: Double) throws {
//            self.encoder.container = .singleValue(String(value))
//        }
//        
//        mutating func encode(_ value: String) throws {
//            self.encoder.container = .singleValue(value)
//        }
//        
//        mutating func encode<T: Encodable>(_ value: T) throws {
//            self.encoder.container = try self.encoder.box(value)
//        }
//    }
//    
//    public enum DataEncodingStrategy {
//        case deferredToData
//        case base64
//        case custom((Data) -> String)
//    }
//    
//    public enum DateEncodingStrategy {
//        case deferredToDate
//        case secondsSince1970
//        case millisecondsSince1970
//        case iso8601
//        case formatted(DateFormatter)
//        case custom((Date) -> String)
//    }
//    
//    public enum Container {
//        indirect case keyed([String: Container])
//        indirect case unkeyed([Container])
//        case singleValue(String)
//        
//        var params: [String: Container]? {
//            switch self {
//            case let .keyed(params):
//                return params
//            case .unkeyed, .singleValue:
//                return nil
//            }
//        }
//        
//        var values: [Container]? {
//            switch self {
//            case let .unkeyed(values):
//                return values
//            case .keyed, .singleValue:
//                return nil
//            }
//        }
//        
//        var value: String? {
//            switch self {
//            case let .singleValue(value):
//                return value
//            case .keyed, .unkeyed:
//                return nil
//            }
//        }
//    }
// }
//
// private func serialize(_ container: UrlFormEncoder.Container, prefix: String = "") -> String {
//    switch container {
//    case let .keyed(dict):
//        return dict.map { key, value in
//            let newPrefix = prefix.isEmpty ? key : "\(prefix)[\(key)]"
//            return serialize(value, prefix: newPrefix)
//        }.joined(separator: "&")
//        
//    case let .unkeyed(array):
//        return array.enumerated().map { index, value in
//            // Change from "\(prefix)[]" to "\(prefix)[\(index)]"
//            let newPrefix = "\(prefix)[\(index)]"
//            return serialize(value, prefix: newPrefix)
//        }
//        .joined(separator: "&")
//        
//    case let .singleValue(value):
////        let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
//        let encodedValue = value.formURLEncoded()
//        return prefix.isEmpty ? encodedValue : "\(prefix)=\(encodedValue)"
//    }
// }
//
//
// private let iso8601DateFormatter: DateFormatter = {
//    let formatter = DateFormatter()
//    formatter.calendar = Calendar(identifier: .iso8601)
//    formatter.locale = Locale(identifier: "en_US_POSIX")
//    formatter.timeZone = TimeZone(abbreviation: "GMT")
//    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
//    return formatter
// }()
//
// private let iso8601DateFormatterWithoutMilliseconds: DateFormatter = {
//    let formatter = DateFormatter()
//    formatter.calendar = Calendar(identifier: .iso8601)
//    formatter.locale = Locale(identifier: "en_US_POSIX")
//    formatter.timeZone = TimeZone(abbreviation: "GMT")
//    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
//    return formatter
// }()
//
//
// extension String {
//    func formURLEncoded() -> String {
//        // Replace spaces with '+'
//        let plusReplaced = self.replacingOccurrences(of: " ", with: "+")
//        // Percent-encode the rest
//        return plusReplaced.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? plusReplaced
//    }
// }
