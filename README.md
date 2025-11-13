# swift-form-coding

A convenience umbrella package that re-exports all form coding functionality for Swift.

## Overview

This package provides a single import for all form data encoding/decoding needs in Swift. It re-exports two independent packages:

- **[swift-url-form-coding](https://github.com/coenttb/swift-url-form-coding)** - URL form encoding/decoding (`application/x-www-form-urlencoded`)
- **[swift-multipart-form-coding](https://github.com/coenttb/swift-multipart-form-coding)** - Multipart form data with file uploads (`multipart/form-data`)

## Installation

Add this package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/coenttb/swift-form-coding", from: "1.0.0")
]
```

Then add the product to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "FormCoding", package: "swift-form-coding")
    ]
)
```

## Usage

```swift
import FormCoding

// URL Form Encoding
struct LoginForm: Codable {
    let username: String
    let password: String
}

let encoder = Form.Encoder()
let form = LoginForm(username: "john", password: "secret")
let formData = try encoder.encode(form)
// Result: "username=john&password=secret"

// Multipart File Upload
let imageUpload = Multipart.FileUpload(
    fieldName: "avatar",
    filename: "profile.jpg",
    fileType: .image(.jpeg),
    maxSize: 5 * 1024 * 1024
)
```

## When to Use Each Package

**Use URL Form Coding when:**
- Submitting simple form data without files
- Working with REST APIs that expect `application/x-www-form-urlencoded`
- You need PHP/Rails-style bracket notation for arrays

**Use Multipart Form Coding when:**
- Uploading files (images, documents, etc.)
- Mixing file uploads with form fields
- You need per-field content-type specification

## Individual Packages

If you only need one type of form coding, import the specific package instead:

```swift
// Just URL form encoding
dependencies: [
    .package(url: "https://github.com/coenttb/swift-url-form-coding", from: "0.1.0")
]

// Just multipart file uploads
dependencies: [
    .package(url: "https://github.com/coenttb/swift-multipart-form-coding", from: "0.1.0")
]
```

## Architecture

This is a minimal umbrella package with no code of its own. It simply re-exports:
- `URLFormCoding`
- `URLFormCodingURLRouting`
- `MultipartFormCoding`
- `MultipartFormCodingURLRouting`

The underlying packages are **completely independent** - they share no dependencies and can be used separately.

## Features

### URL Form Coding
- ✅ Codable integration for form data
- ✅ Multiple array encoding strategies (accumulate, brackets, indexed)
- ✅ Custom date/data encoding strategies
- ✅ URLRouting integration
- ✅ RFC 2388 compliant

### Multipart Form Coding
- ✅ Secure file upload validation
- ✅ Magic number (file signature) checking
- ✅ Configurable size limits
- ✅ Built-in file type support (images, documents, etc.)
- ✅ RFC 2045/2046/7578 compliant
- ✅ URLRouting integration

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Related Packages

- [swift-url-form-coding](https://github.com/coenttb/swift-url-form-coding) - URL form encoding/decoding
- [swift-multipart-form-coding](https://github.com/coenttb/swift-multipart-form-coding) - Multipart form data with file uploads
