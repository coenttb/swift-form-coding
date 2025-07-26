import Foundation
import Parsing
import URLRouting

public struct MultipartFileUpload: Conversion {
    private let boundary: String
    private let fieldName: String
    private let filename: String
    private let fileType: FileType
    public static let maxFileSize: Int = 10 * 1024 * 1024  // 10MB default
    private let maxSize: Int

    public init(
        fieldName: String,
        filename: String,
        fileType: FileType,
        maxSize: Int = MultipartFileUpload.maxFileSize
    ) {
        self.fieldName = fieldName
        self.filename = filename
        self.fileType = fileType
        self.maxSize = maxSize
        self.boundary = Self.generateBoundary()
    }

    private static func generateBoundary() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomString = (0..<15).map { _ in String(characters.randomElement()!) }.joined()
        return "Boundary-\(randomString)"  // 9 + 15 = 24 characters total
    }

    // MARK: - Conversion Protocol Implementation

    public func apply(_ input: Data) throws -> Data {
        try validate(input)
        return input
    }

    public func unapply(_ data: Data) throws -> Data {
        try validate(data)

        var body = Data()
        try appendBoundary(to: &body)
        try appendHeaders(to: &body)
        body.append(data)
        try appendClosingBoundary(to: &body)

        return body
    }

    private func validate(_ data: Data) throws {
        guard !data.isEmpty else {
            throw MultipartError.emptyData
        }

        guard data.count <= maxSize else {
            throw MultipartError.fileTooLarge(size: data.count, maxSize: maxSize)
        }

        try fileType.validate(data)
    }

    private func appendBoundary(to data: inout Data) throws {
        guard let boundaryData = "--\(boundary)\r\n".data(using: .utf8) else {
            throw MultipartError.encodingError
        }
        data.append(boundaryData)
    }

    private func appendHeaders(to data: inout Data) throws {
        let headers = """
            Content-Disposition: form-data; name="\(fieldName)"; filename="\(filename)"
            Content-Type: \(fileType.contentType)\r\n\r\n
            """

        guard let headerData = headers.data(using: .utf8) else {
            throw MultipartError.encodingError
        }
        data.append(headerData)
    }

    private func appendClosingBoundary(to data: inout Data) throws {
        guard let boundaryData = "\r\n--\(boundary)--\r\n".data(using: .utf8) else {
            throw MultipartError.encodingError
        }
        data.append(boundaryData)
    }
}

extension MultipartFileUpload {
    public var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }
}

extension MultipartFileUpload {
    public struct FileType {
        let contentType: String
        let fileExtension: String
        let validate: (Data) throws -> Void

        public init(
            contentType: String,
            fileExtension: String,
            validate: @escaping (Data) throws -> Void = { _ in }
        ) {
            self.contentType = contentType
            self.fileExtension = fileExtension
            self.validate = validate
        }
    }
}

extension MultipartFileUpload.FileType {
    public struct ImageType {
        let contentType: String
        let fileExtension: String
        let validate: (Data) throws -> Void

        public init(
            contentType: String,
            fileExtension: String,
            validate: @escaping (Data) throws -> Void = { _ in }
        ) {
            self.contentType = contentType
            self.fileExtension = fileExtension
            self.validate = validate
        }
    }
}

extension MultipartFileUpload {
    public enum MultipartError: Equatable, LocalizedError {
        case fileTooLarge(size: Int, maxSize: Int)
        case invalidContentType(String)
        case contentMismatch(expected: String, detected: String?)
        case emptyData
        case malformedBoundary
        case encodingError
    }
}

extension MultipartFileUpload.MultipartError {
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
