import Foundation

/// A conversion that handles file uploads in multipart/form-data format.
///
/// `Multipart.FileUpload` provides secure file upload functionality with built-in
/// validation, size limits, and content type checking. It automatically generates
/// proper multipart boundaries and headers according to RFC 7578.
///
/// ## Overview
///
/// This conversion is designed specifically for handling file uploads with:
/// - **Content validation**: Verifies file content matches expected file type
/// - **Size limits**: Configurable maximum file size (default 10MB)
/// - **Security**: Magic number validation to prevent malicious file uploads
/// - **Type safety**: Strongly typed file type system with built-in common types
///
/// ## Basic Usage
///
/// ```swift
/// // Create file upload for images
/// let imageUpload = Multipart.FileUpload(
///     fieldName: "avatar",
///     filename: "profile.jpg",
///     fileType: .image(.jpeg)
/// )
///
/// // Use in route definition
/// Route {
///     Method.post
///     Path { "upload" }
///     Body(imageUpload)
/// }
/// ```
///
/// ## Custom File Size Limits
///
/// ```swift
/// let restrictedUpload = Multipart.FileUpload(
///     fieldName: "thumbnail",
///     filename: "thumb.png",
///     fileType: .image(.png),
///     maxSize: 1024 * 1024  // 1MB limit
/// )
/// ```
///
/// ## Security Features
///
/// - **Magic number validation**: Verifies file headers match declared type
/// - **Size enforcement**: Prevents oversized file uploads
/// - **Content type validation**: Ensures uploaded content matches expectations
/// - **Safe boundary generation**: Uses cryptographically safe boundary strings
///
/// - Important: Always validate file content server-side even with client-side restrictions.
/// - Note: The conversion validates file content during both `apply` and `unapply` operations.
extension Multipart {
    public struct FileUpload {
        /// The unique boundary string used to separate multipart fields.
        public let boundary: String

        /// The name of the form field for this file upload.
        private let fieldName: String

        /// The filename to include in the multipart headers.
        private let filename: String

        /// The file type specification including validation rules.
        private let fileType: FileType

        /// The default maximum file size (10MB).
        public static let maxFileSize: Int = 10 * 1024 * 1024  // 10MB default

        /// The maximum allowed file size for this upload.
        private let maxSize: Int

        /// Creates a new multipart file upload conversion.
        ///
        /// - Parameters:
        ///   - fieldName: The form field name for this file upload
        ///   - filename: The filename to include in multipart headers
        ///   - fileType: The expected file type with validation rules
        ///   - maxSize: Maximum file size in bytes (defaults to 10MB)
        ///
        /// ## Example
        ///
        /// ```swift
        /// let pdfUpload = Multipart.FileUpload(
        ///     fieldName: "document",
        ///     filename: "report.pdf",
        ///     fileType: .pdf,
        ///     maxSize: 5 * 1024 * 1024  // 5MB limit
        /// )
        /// ```
        public init(
            fieldName: String,
            filename: String,
            fileType: FileType,
            maxSize: Int = Multipart.FileUpload.maxFileSize
        ) {
            self.fieldName = fieldName
            self.filename = filename
            self.fileType = fileType
            self.maxSize = maxSize
            self.boundary = Self.generateBoundary()
        }

        /// Generates a cryptographically safe boundary string for multipart data.
        ///
        /// The boundary uses alphanumeric characters and is prefixed with "Boundary-"
        /// to ensure uniqueness and prevent conflicts with file content.
        ///
        /// - Returns: A unique boundary string safe for multipart usage
        private static func generateBoundary() -> String {
            let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            let randomString = (0..<15).map { _ in String(characters.randomElement()!) }.joined()
            return "Boundary-\(randomString)"  // 9 + 15 = 24 characters total
        }

        public func validate(_ data: Foundation.Data) throws {
            guard !data.isEmpty else {
                throw MultipartError.emptyData
            }

            guard data.count <= maxSize else {
                throw MultipartError.fileTooLarge(size: data.count, maxSize: maxSize)
            }

            try fileType.validate(data)
        }

        public func appendBoundary(to data: inout Foundation.Data) throws {
            guard let boundaryData = "--\(boundary)\r\n".data(using: .utf8) else {
                throw MultipartError.encodingError
            }
            data.append(boundaryData)
        }

        public func appendHeaders(to data: inout Foundation.Data) throws {
            let headers = """
                Content-Disposition: form-data; name="\(fieldName)"; filename="\(filename)"
                Content-Type: \(fileType.contentType)\r\n\r\n
                """

            guard let headerData = headers.data(using: .utf8) else {
                throw MultipartError.encodingError
            }
            data.append(headerData)
        }

        public func appendClosingBoundary(to data: inout Foundation.Data) throws {
            guard let boundaryData = "\r\n--\(boundary)--\r\n".data(using: .utf8) else {
                throw MultipartError.encodingError
            }
            data.append(boundaryData)
        }
    }
}

extension Multipart.FileUpload {
    /// The Content-Type header value for this multipart file upload.
    ///
    /// Returns a properly formatted Content-Type header including the unique
    /// boundary parameter required for multipart form data parsing.
    ///
    /// - Returns: A string in the format `multipart/form-data; boundary=<unique-boundary>`
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let upload = Multipart.FileUpload(/* ... */)
    /// request.setValue(upload.contentType, forHTTPHeaderField: "Content-Type")
    /// ```
    public var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }
}

extension Multipart.FileUpload {
    /// Represents a file type with content validation capabilities.
    ///
    /// `FileType` encapsulates MIME type information, file extensions, and validation
    /// logic for different file formats. It provides a type-safe way to specify
    /// expected file types and automatically validate uploaded content.
    ///
    /// ## Built-in File Types
    ///
    /// Common file types are provided as static properties:
    /// - `.pdf` - PDF documents with magic number validation
    /// - `.csv` - CSV text files with UTF-8 validation
    /// - `.json` - JSON files with format validation
    /// - `.text` - Plain text files
    /// - `.image()` - Image files (see ``ImageType``)
    ///
    /// ## Custom File Types
    ///
    /// ```swift
    /// let xmlType = FileType(
    ///     contentType: "application/xml",
    ///     fileExtension: "xml"
    /// ) { data in
    ///     // Custom validation logic
    ///     guard data.starts(with: "<?xml".data(using: .utf8)!) else {
    ///         throw Multipart.FileUpload.MultipartError.contentMismatch(
    ///             expected: "application/xml",
    ///             detected: nil
    ///         )
    ///     }
    /// }
    /// ```
    public struct FileType {
        /// The MIME content type for this file format.
        let contentType: String

        /// The file extension (without dot) for this file format.
        let fileExtension: String

        /// Validation function that checks if data matches this file type.
        let validate: (Foundation.Data) throws -> Void

        /// Creates a new file type specification.
        ///
        /// - Parameters:
        ///   - contentType: The MIME content type (e.g., "application/pdf")
        ///   - fileExtension: The file extension without dot (e.g., "pdf")
        ///   - validate: Optional validation function that throws on invalid data
        public init(
            contentType: String,
            fileExtension: String,
            validate: @escaping (Foundation.Data) throws -> Void = { _ in }
        ) {
            self.contentType = contentType
            self.fileExtension = fileExtension
            self.validate = validate
        }
    }
}

extension Multipart.FileUpload.FileType {
    /// Represents image file types with magic number validation.
    ///
    /// `ImageType` provides specialized validation for common image formats
    /// using magic number (file signature) detection to prevent malicious
    /// file uploads disguised as images.
    ///
    /// ## Supported Image Types
    ///
    /// - `.jpeg` - JPEG images (validates FF D8 FF magic numbers)
    /// - `.png` - PNG images (validates PNG signature)
    /// - `.gif` - GIF images (validates GIF87a/GIF89a signatures)
    /// - `.webp` - WebP images (validates RIFF/WEBP signature)
    ///
    /// ## Example
    ///
    /// ```swift
    /// let imageUpload = Multipart.FileUpload(
    ///     fieldName: "photo",
    ///     filename: "profile.jpg",
    ///     fileType: .image(.jpeg)  // Validates JPEG magic numbers
    /// )
    /// ```
    ///
    /// ## Security
    ///
    /// Each image type validates the file's magic numbers (binary signature)
    /// to ensure the file content matches the declared format, preventing
    /// security vulnerabilities from disguised malicious files.
    public struct ImageType {
        /// The MIME content type for this image format.
        let contentType: String

        /// The file extension (without dot) for this image format.
        let fileExtension: String

        /// Validation function that checks magic numbers for this image type.
        let validate: (Foundation.Data) throws -> Void

        /// Creates a new image type specification.
        ///
        /// - Parameters:
        ///   - contentType: The MIME content type (e.g., "image/jpeg")
        ///   - fileExtension: The file extension without dot (e.g., "jpg")
        ///   - validate: Validation function that checks image magic numbers
        public init(
            contentType: String,
            fileExtension: String,
            validate: @escaping (Foundation.Data) throws -> Void = { _ in }
        ) {
            self.contentType = contentType
            self.fileExtension = fileExtension
            self.validate = validate
        }
    }
}

extension Multipart.FileUpload {
    /// Errors that can occur during multipart file upload processing.
    ///
    /// `MultipartError` provides detailed error information for various failure
    /// scenarios that can occur during file upload validation and processing.
    /// All errors implement `LocalizedError` to provide user-friendly descriptions.
    ///
    /// ## Error Cases
    ///
    /// - ``fileTooLarge(size:maxSize:)`` - File exceeds size limits
    /// - ``invalidContentType(_:)`` - Unsupported or malformed content type
    /// - ``contentMismatch(expected:detected:)`` - File content doesn't match declared type
    /// - ``emptyData`` - No file data provided
    /// - ``malformedBoundary`` - Invalid multipart boundary format
    /// - ``encodingError`` - Failed to encode multipart data
    ///
    /// ## Error Handling
    ///
    /// ```swift
    /// do {
    ///     let validatedData = try fileUpload.apply(uploadData)
    /// } catch let error as Multipart.FileUpload.MultipartError {
    ///     switch error {
    ///     case .fileTooLarge(let size, let maxSize):
    ///         print("File \(size) bytes exceeds limit of \(maxSize) bytes")
    ///     case .contentMismatch(let expected, let detected):
    ///         print("Expected \(expected), got \(detected ?? "unknown")")
    ///     case .emptyData:
    ///         print("No file data provided")
    ///     // Handle other cases...
    ///     }
    /// }
    /// ```
    public enum MultipartError: Equatable, LocalizedError {
        /// File size exceeds the configured maximum.
        ///
        /// - Parameters:
        ///   - size: The actual file size in bytes
        ///   - maxSize: The maximum allowed size in bytes
        case fileTooLarge(size: Int, maxSize: Int)

        /// The provided content type is invalid or unsupported.
        ///
        /// - Parameter contentType: The invalid content type string
        case invalidContentType(String)

        /// File content doesn't match the expected type.
        ///
        /// This error occurs when magic number validation fails, indicating
        /// the file content doesn't match the declared MIME type.
        ///
        /// - Parameters:
        ///   - expected: The expected content type
        ///   - detected: The detected content type (if determinable)
        case contentMismatch(expected: String, detected: String?)

        /// No file data was provided (empty upload).
        case emptyData

        /// The multipart boundary format is invalid.
        case malformedBoundary

        /// Failed to encode data in multipart format.
        case encodingError
    }
}

extension Multipart.FileUpload.MultipartError {
    /// Provides localized error descriptions for user-facing error messages.
    ///
    /// Each error case returns a descriptive message that can be displayed
    /// to users or logged for debugging purposes.
    public var errorDescription: String? {
        switch self {
        case .fileTooLarge(let size, let maxSize):
            return "File size \(size) exceeds maximum allowed size of \(maxSize) bytes"
        case .invalidContentType(let type):
            return "Invalid content type: \(type)"
        case .contentMismatch(let expected, let detected):
            return "Content type mismatch. Expected: \(expected), Detected: \(detected ?? "unknown")"
        case .emptyData:
            return "Empty file data"
        case .malformedBoundary:
            return "Malformed multipart boundary"
        case .encodingError:
            return "Failed to encode multipart form data"
        }
    }
}
