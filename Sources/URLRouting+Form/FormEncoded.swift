import Foundation
import Parsing
import UrlFormCoding

extension Conversion {
    @inlinable
    public static func form<Value>(
        _ type: Value.Type,
        decoder: UrlFormDecoder = .init(),
        encoder: UrlFormEncoder = .init()
    ) -> Self where Self == FormCoding<Value> {
        .init(type, decoder: decoder, encoder: encoder)
    }

    @inlinable
    public func form<Value>(
        _ type: Value.Type,
        decoder: UrlFormDecoder = .init(),
        encoder: UrlFormEncoder = .init()
    ) -> Conversions.Map<Self, FormCoding<Value>> {
        self.map(.form(type, decoder: decoder, encoder: encoder))
    }
}

public struct FormCoding<Value: Codable>: Conversion {
    public let decoder: UrlFormDecoder
    public let encoder: UrlFormEncoder

    @inlinable
    public init(
        _ type: Value.Type,
        decoder: UrlFormDecoder = .init(),
        encoder: UrlFormEncoder = .init()
    ) {
        self.decoder = decoder
        self.encoder = encoder
    }

    @inlinable
    public func apply(_ input: Data) throws -> Value {
        try decoder.decode(Value.self, from: input)
    }

    @inlinable
    public func unapply(_ output: Value) throws -> Data {
        try encoder.encode(output)
    }
}
