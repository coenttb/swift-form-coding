# Swift URL Form Coding

A powerful, type-safe Swift library for handling web form data encoding/decoding with support for both `application/x-www-form-urlencoded` and `multipart/form-data` formats, featuring seamless URLRouting integration.

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%2010.15%20|%20iOS%2013%20|%20tvOS%2013%20|%20watchOS%206-blue.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](LICENSE)

## Features

### 🔒 **Type-Safe Form Handling**
- **URL Form Encoding/Decoding**: Complete support for `application/x-www-form-urlencoded` data
- **Multipart Form Data**: RFC 7578 compliant multipart/form-data processing
- **Custom Parsing Strategies**: Flexible handling of nested objects, arrays, and complex data structures
- **Swift 6 Compatibility**: Full support for Swift's latest concurrency and type safety features

### 📁 **File Upload Support**
- **Secure File Handling**: Built-in file upload support with validation
- **Magic Number Validation**: Automatic file type verification using file signatures
- **Size Limits**: Configurable file size restrictions with sensible defaults
- **Predefined File Types**: Built-in support for images, documents, and more

### 🔗 **URLRouting Integration**
- **Seamless Integration**: First-class support for Point-Free's URLRouting library
- **Conversion Protocol**: Easy integration with routing systems via the `Conversion` protocol
- **Type-Safe Routes**: Define routes with compile-time guarantees for form data handling
- **Chaining Support**: Compose conversions for complex data transformations

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

### URLRouting Integration

```swift
import URLRouting
import URLFormCoding
import URLFormCodingURLRouting

// Define your data model
struct LoginRequest: Codable {
    let username: String
    let password: String
    let rememberMe: Bool
}

// Create a form conversion
let loginForm = Conversion.form(LoginRequest.self)

// Use in route definition
let loginRoute = Route {
    Method.post
    Path { "login" }
    Body(loginForm)
}

// Handle form data
let formData = "username=john&password=secret&rememberMe=true"
let request = try loginForm.apply(Data(formData.utf8))
print(request.username) // "john"
```

### Multipart Form Handling

```swift
import URLMultipartFormCoding
import URLMultipartFormCodingURLRouting

// Define a form field
let textField = Multipart.FormField(
    name: "description",
    value: "User uploaded content"
)

// Define file upload for user avatars
let avatarUpload = Multipart.FileUpload(
    fieldName: "avatar",
    filename: "profile.jpg",
    fileType: .image(.jpeg),
    maxSize: 2 * 1024 * 1024  // 2MB limit
)

// Use in route definition
let uploadRoute = Route {
    Method.post
    Path { "upload"; "avatar" }
    Body(avatarUpload.conversion)
}

// The conversion automatically validates:
// ✅ File size limits
// ✅ JPEG magic number signature
// ✅ Content type matching
```

## Advanced Usage

### Custom Form Decoding Strategies

```swift
// Configure decoder for nested objects
let decoder = Form.Decoder()
decoder.parsingStrategy = .brackets  // Supports user[profile][name]=value
decoder.dateDecodingStrategy = .iso8601
decoder.arrayDecodingStrategy = .brackets

// Create form with custom configuration
let advancedForm = Conversion.form(
    ComplexUser.self,
    decoder: decoder
)

// Use in route definition
let complexRoute = Route {
    Method.post
    Path { "users" }
    Body(advancedForm)
}
```

### Supported Parsing Strategies

| Strategy | Example | Use Case |
|----------|---------|----------|
| **Default** | `name=value&age=30` | Simple key-value pairs |
| **Brackets** | `user[name]=John&user[age]=30` | Nested objects |
| **Accumulate** | `tags=swift&tags=ios&tags=web` | Multiple values per key |

### Custom File Types

```swift
import URLMultipartFormCoding

// Define custom file type with validation
let customFileType = Multipart.FileUpload.FileType(
    contentType: "application/json",
    fileExtension: "json"
) { data in
    // Custom validation logic
    _ = try JSONSerialization.jsonObject(with: data)
}

let jsonUpload = Multipart.FileUpload(
    fieldName: "config",
    filename: "settings.json", 
    fileType: customFileType,
    maxSize: 1024 * 1024  // 1MB limit
)
```

### Supported File Types

| Type | Content Type | Validation |
|------|-------------|------------|
| **JPEG** | `image/jpeg` | Magic number validation |
| **PNG** | `image/png` | PNG signature check |
| **PDF** | `application/pdf` | %PDF header validation |
| **Custom** | User-defined | Custom validation function |

### Chaining Conversions

```swift
// Chain multiple conversions together
let stringToUser = Conversion<String, Data>.utf8
    .form(User.self)

// Use in route definition
let chainedRoute = Route {
    Method.post
    Path { "users" }
    Body(stringToUser)
}
```

## Core Components

### Form.Encoder & Form.Decoder

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

// Decode from form data
let decoded = try decoder.decode(User.self, from: formData)
```

### Form.Conversion

The main conversion type for URLRouting integration:

```swift
// Basic form conversion
let userForm = Form.Conversion(User.self)

// Custom configuration
let encoder = Form.Encoder()
let decoder = Form.Decoder()

let customForm = Form.Conversion(
    User.self,
    decoder: decoder,
    encoder: encoder
)
```

### Multipart Components

Multipart form data handling components:

```swift
import URLMultipartFormCoding

// Basic form field
let field = Multipart.FormField(
    name: "username",
    value: "john_doe"
)

// File upload with validation
let upload = Multipart.FileUpload(
    fieldName: "document",
    filename: "report.pdf", 
    fileType: .pdf,
    maxSize: 5 * 1024 * 1024  // 5MB
)
```

## Security Features

### Form Data Security
- **Input Validation**: Automatic validation of form field types and formats
- **URL Decoding**: Proper handling of URL-encoded data with security considerations
- **Memory Safety**: Efficient parsing that prevents buffer overflows
- **Type Safety**: Compile-time guarantees for form data structure

### File Upload Security
- **Magic Number Validation**: Prevents malicious files disguised as safe formats
- **Size Limits**: Configurable limits prevent DoS attacks via large files  
- **Content Type Validation**: Ensures uploaded content matches declared type
- **Safe Boundary Generation**: Cryptographically secure multipart boundaries

## Error Handling

### Form Data Errors

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

// Form conversions integrate seamlessly with URLRouting error handling
do {
    let user = try Conversion.form(User.self).apply(formData)
    // Handle successful conversion
} catch {
    // Handle any conversion errors
    print("Form conversion failed: \(error)")
}
```

### Multipart Form Errors

```swift
import URLMultipartFormCoding

do {
    let fileData = try fileUpload.conversion.apply(uploadData)
} catch let error as Multipart.FileUpload.ValidationError {
    switch error {
    case .fileTooLarge(let size, let limit):
        print("File too large: \(size) bytes, limit: \(limit)")
    case .invalidFileType(let expected, let actual):
        print("Invalid file type: expected \(expected), got \(actual)")
    case .emptyFile:
        print("Uploaded file is empty")
    case .invalidMagicNumber:
        print("File signature validation failed")
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
- ✅ URLRouting integration and conversion protocols
- ✅ Multipart form field processing
- ✅ File upload validation and security checks
- ✅ Error handling scenarios
- ✅ Custom parsing strategies
- ✅ Magic number validation for file types
- ✅ Round-trip data integrity
- ✅ Edge cases and Unicode handling

## Requirements

- **Swift**: 6.0+
- **Platforms**: macOS 10.15+, iOS 13.0+, tvOS 13.0+, watchOS 6.0+
- **Dependencies**: 
  - [swift-url-routing](https://github.com/pointfreeco/swift-url-routing) (0.6.0+)
  - [swift-dependencies](https://github.com/pointfreeco/swift-dependencies) (1.1.5+)

## Contributing

Contributions are welcome! Please feel free to:

1. **Open Issues**: Report bugs or request features
2. **Submit PRs**: Improve documentation, add features, or fix bugs  
3. **Share Feedback**: Let us know how you're using the library

## Acknowledgements

This project builds upon foundational work by Point-Free (Brandon Williams and Stephen Celis). This package's Form.Encoder and Form.Decoder are forked from their [swift-web](https://github.com/pointfreeco/swift-web) in [pointfree-url-form-coding](https://github.com/coenttb/pointfree-url-form-coding).

## License

This project is licensed under the **Apache 2.0 License**. See [LICENSE](LICENSE) for details.

## Feedback & Support

Your feedback makes this project better for everyone!

> [Subscribe to my newsletter](http://coenttb.com/en/newsletter/subscribe)
>
> [Follow me on X](http://x.com/coenttb)
> 
> [Connect on LinkedIn](https://www.linkedin.com/in/tenthijeboonkkamp)

---

**swift-url-form-coding** - Type-safe web form handling with multipart support and URLRouting integration for modern Swift applications.
