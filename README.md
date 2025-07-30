# Swift URL Form Coding

A powerful, type-safe Swift library for handling web form data encoding/decoding with `application/x-www-form-urlencoded` format.

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%2014%20|%20iOS%2017-blue.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](LICENSE)

## Features

### 🔒 **Type-Safe Form Handling**
- **URL Form Encoding/Decoding**: Complete support for `application/x-www-form-urlencoded` data
- **Custom Parsing Strategies**: Flexible handling of nested objects, arrays, and complex data structures
- **Swift 6 Compatibility**: Full support for Swift's latest concurrency and type safety features

### 🔗 **[URLRouting Integration](https://github.com/coenttb/swift-url-form-coding-url-routing)**
- **Seamless Integration**: Optional integration with Point-Free's URLRouting library
- **Conversion Protocol**: Easy integration with routing systems via the `Conversion` protocol
- **Type-Safe Routes**: Define routes with compile-time guarantees for form data handling

## Quick Start

### Installation

Add `swift-url-form-coding` to your Swift package:

```swift
dependencies: [
    .package(url: "https://github.com/coenttb/swift-url-form-coding.git", from: "0.0.1")
]
```

### Basic Form Handling

```swift
import URLFormCoding

// Define your data model
struct LoginRequest: Codable {
    let username: String
    let password: String
    let rememberMe: Bool
}

// Create encoder and decoder
let encoder = Form.Encoder()
let decoder = Form.Decoder()

// Encode to form data
let request = LoginRequest(username: "john", password: "secret", rememberMe: true)
let formData = try encoder.encode(request)
// Result: "username=john&password=secret&rememberMe=true"

// Decode from form data
let formString = "username=john&password=secret&rememberMe=true"
let decoded = try decoder.decode(LoginRequest.self, from: Data(formString.utf8))
print(decoded.username) // "john"
```

## Advanced Usage

### Custom Form Decoding Strategies

```swift
// Configure decoder for nested objects
let decoder = Form.Decoder()
decoder.parsingStrategy = .brackets  // Supports user[profile][name]=value
decoder.dateDecodingStrategy = .iso8601
decoder.arrayDecodingStrategy = .brackets

// Use the custom decoder
let formData = "user[profile][name]=John&user[profile][age]=30"
let user = try decoder.decode(ComplexUser.self, from: Data(formData.utf8))
```

### Supported Parsing Strategies

| Strategy | Example | Use Case |
|----------|---------|----------|
| **Default** | `name=value&age=30` | Simple key-value pairs |
| **Brackets** | `user[name]=John&user[age]=30` | Nested objects |
| **Accumulate** | `tags=swift&tags=ios&tags=web` | Multiple values per key |


## Core Components

### URLFormCoding

The foundation for URL-encoded form data handling:

```swift
// Basic encoding/decoding
let encoder = Form.Encoder()
let decoder = Form.Decoder()

struct User: Codable {
    let name: String
    let preferences: [String: String]
    let createdAt: Date
}

// Encode to form data
let user = User(name: "John", preferences: ["theme": "dark"], createdAt: Date())
let formData = try encoder.encode(user)
// Result: "name=John&preferences[theme]=dark&createdAt=2024-01-01T12:00:00Z"

// Decode from form data
let decoded = try decoder.decode(User.self, from: formData)
```


## Security Features

- **Input Validation**: Automatic validation of form field types and formats
- **URL Decoding**: Proper handling of URL-encoded data with security considerations
- **Memory Safety**: Efficient parsing that prevents buffer overflows

## Error Handling

```swift
do {
    let user = try formDecoder.decode(User.self, from: formData)
} catch let error as Form.Decoder.Error {
    switch error {
    case .invalidFormat:
        print("Invalid form data format")
    case .missingRequiredField(let field):
        print("Missing required field: \(field)")
    case .typeMismatch(let field, let expectedType):
        print("Type mismatch for \(field), expected \(expectedType)")
    }
}

```

## Testing

The library includes comprehensive test suites:

```bash
swift test
```

Test coverage includes:
- ✅ URL form encoding/decoding with various data types
- ✅ Custom parsing strategies (brackets, accumulate, default)
- ✅ Error handling scenarios
- ✅ Date and array decoding strategies
- ✅ Memory safety and edge cases

## Requirements

- **Swift**: 6.0+
- **Platforms**: macOS 14.0+, iOS 17.0+
- **Dependencies**: None (pure Swift implementation)

## Related Projects

### The coenttb Stack

* [swift-css](https://github.com/coenttb/swift-css): A Swift DSL for type-safe CSS
* [swift-html](https://github.com/coenttb/swift-html): A Swift DSL for type-safe HTML & CSS
* [swift-web](https://github.com/coenttb/swift-web): Foundational web development tools
* [coenttb-web](https://github.com/coenttb/coenttb-web): Enhanced web development functionality
* [coenttb-server](https://github.com/coenttb/coenttb-server): Modern server development tools

### PointFree Foundations

* [swift-url-routing](https://github.com/pointfreeco/swift-url-routing): Type-safe URL routing
* [swift-dependencies](https://github.com/pointfreeco/swift-dependencies): Dependency management system

## Contributing

Contributions are welcome! Please feel free to:

1. **Open Issues**: Report bugs or request features
2. **Submit PRs**: Improve documentation, add features, or fix bugs  
3. **Share Feedback**: Let us know how you're using the library

## Acknowledgements

This project builds upon foundational work by Point-Free (Brandon Williams and Stephen Celis). This package's Form.Encoder and Form.Decoder are from their [swift-web](https://github.com/pointfreeco/swift-web) library.

## License

This project is licensed under the **Apache 2.0 License**. See [LICENSE](LICENSE) for details.

The Form.Encoder and Form.Decoder files are licensed under the MIT License:
- https://github.com/coenttb/swift-url-form-coding/blob/main/Sources/URLFormCoding/Form.Decoder.swift
- https://github.com/coenttb/swift-url-form-coding/blob/main/Sources/URLFormCoding/Form.Encoder.swift

## Feedback & Support

Your feedback makes this project better for everyone!

> [Subscribe to my newsletter](http://coenttb.com/en/newsletter/subscribe)
>
> [Follow me on X](http://x.com/coenttb)
> 
> [Connect on LinkedIn](https://www.linkedin.com/in/tenthijeboonkkamp)

---

**swift-url-form-coding** - Type-safe web form handling for modern Swift applications.
