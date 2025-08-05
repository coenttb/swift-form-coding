//
//  MultipartURLFormCoding Tests.swift
//  swift-url-form-coding-url-routing
//
//  Created by Coen ten Thije Boonkkamp on 26/07/2025.
//

import Foundation
import Testing
@testable import URLMultipartFormCoding

// MARK: - Basic FileUpload Tests

@Suite("FileUpload Basic Functionality")
struct FileUploadBasicTests {

    @Test("FileUpload initializes with correct default values")
    func fileUploadInitialization() {
        let upload = Multipart.FileUpload(
            fieldName: "test_field",
            filename: "test.txt",
            fileType: .text
        )

        #expect(!upload.boundary.isEmpty)
        #expect(upload.boundary.hasPrefix("Boundary-"))
        #expect(upload.boundary.count == 24) // "Boundary-" (9) + 15 random chars
        #expect(upload.contentType == "multipart/form-data; boundary=\(upload.boundary)")
    }

    @Test("FileUpload validates file size limits")
    func fileSizeValidation() async throws {
        let smallUpload = Multipart.FileUpload(
            fieldName: "small",
            filename: "small.txt",
            fileType: .text,
            maxSize: 100
        )

        let validData = "Valid content".data(using: .utf8)!
        let oversizedData = Data(repeating: 0x41, count: 200) // 200 bytes

        // Valid size should pass
        #expect(throws: Never.self) {
            try smallUpload.validate(validData)
        }

        // Oversized should throw
        #expect(throws: Multipart.FileUpload.MultipartError.self) {
            try smallUpload.validate(oversizedData)
        }
    }

    @Test("FileUpload rejects empty data")
    func emptyDataValidation() {
        let upload = Multipart.FileUpload(
            fieldName: "test",
            filename: "empty.txt",
            fileType: .text
        )

        let emptyData = Data()

        #expect(throws: Multipart.FileUpload.MultipartError.emptyData) {
            try upload.validate(emptyData)
        }
    }

    @Test("FileUpload generates unique boundaries")
    func uniqueBoundaryGeneration() {
        let upload1 = Multipart.FileUpload(fieldName: "test1", filename: "test1.txt", fileType: .text)
        let upload2 = Multipart.FileUpload(fieldName: "test2", filename: "test2.txt", fileType: .text)

        #expect(upload1.boundary != upload2.boundary)
    }
}

// MARK: - FileType Tests

@Suite("FileType Validation")
struct FileTypeTests {

    @Test("PDF file type validates magic numbers correctly")
    func pdfValidation() async throws {
        let validPDF = "%PDF-1.4\n%âãÏÓ".data(using: .utf8)!
        let invalidPDF = "Not a PDF file".data(using: .utf8)!

        // Valid PDF should pass
        #expect(throws: Never.self) {
            try Multipart.FileUpload.FileType.pdf.validate(validPDF)
        }

        // Invalid PDF should throw
        #expect(throws: Multipart.FileUpload.MultipartError.self) {
            try Multipart.FileUpload.FileType.pdf.validate(invalidPDF)
        }
    }

    @Test("CSV file type validates UTF-8 encoding")
    func csvValidation() async throws {
        let validCSV = "name,age,city\nJohn,30,NYC".data(using: .utf8)!
        let invalidCSV = Data([0xFF, 0xFE, 0xFF, 0xFE]) // Invalid UTF-8

        // Valid UTF-8 CSV should pass
        #expect(throws: Never.self) {
            try Multipart.FileUpload.FileType.csv.validate(validCSV)
        }

        // Invalid UTF-8 should throw
        #expect(throws: Multipart.FileUpload.MultipartError.self) {
            try Multipart.FileUpload.FileType.csv.validate(invalidCSV)
        }
    }

    @Test("Text file type accepts any content")
    func textValidation() {
        let textData = "Any text content".data(using: .utf8)!
        let binaryData = Data([0x00, 0x01, 0x02, 0x03])

        // Both should pass for plain text type
        #expect(throws: Never.self) {
            try Multipart.FileUpload.FileType.text.validate(textData)
        }

        #expect(throws: Never.self) {
            try Multipart.FileUpload.FileType.text.validate(binaryData)
        }
    }

    @Test("JSON file type accepts content without validation")
    func jsonValidation() {
        let validJSON = "{\"name\": \"test\", \"value\": 123}".data(using: .utf8)!
        let invalidJSON = "not json".data(using: .utf8)!

        // Both should pass since JSON type doesn't validate content
        #expect(throws: Never.self) {
            try Multipart.FileUpload.FileType.json.validate(validJSON)
        }

        #expect(throws: Never.self) {
            try Multipart.FileUpload.FileType.json.validate(invalidJSON)
        }
    }
}

// MARK: - Image Type Tests

@Suite("Image Type Validation")
struct ImageTypeTests {

    @Test("JPEG image type validates magic numbers")
    func jpegValidation() async throws {
        let validJPEG = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]) // JPEG header
        let invalidJPEG = Data([0x89, 0x50, 0x4E, 0x47]) // PNG header

        let jpegType = Multipart.FileUpload.FileType.image(.jpeg)

        // Valid JPEG should pass
        #expect(throws: Never.self) {
            try jpegType.validate(validJPEG)
        }

        // Invalid JPEG should throw
        #expect(throws: Multipart.FileUpload.MultipartError.self) {
            try jpegType.validate(invalidJPEG)
        }
    }

    @Test("PNG image type validates magic numbers")
    func pngValidation() async throws {
        let validPNG = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) // PNG signature
        let invalidPNG = Data([0xFF, 0xD8, 0xFF]) // JPEG header

        let pngType = Multipart.FileUpload.FileType.image(.png)

        // Valid PNG should pass
        #expect(throws: Never.self) {
            try pngType.validate(validPNG)
        }

        // Invalid PNG should throw
        #expect(throws: Multipart.FileUpload.MultipartError.self) {
            try pngType.validate(invalidPNG)
        }
    }

    @Test("GIF image type validates both versions")
    func gifValidation() async throws {
        let gif87a = "GIF87a".data(using: .ascii)! + Data([0x00, 0x00])
        let gif89a = "GIF89a".data(using: .ascii)! + Data([0x00, 0x00])
        let invalidGIF = "NOTGIF".data(using: .ascii)!

        let gifType = Multipart.FileUpload.FileType.image(.gif)

        // Both GIF versions should pass
        #expect(throws: Never.self) {
            try gifType.validate(gif87a)
        }

        #expect(throws: Never.self) {
            try gifType.validate(gif89a)
        }

        // Invalid GIF should throw
        #expect(throws: Multipart.FileUpload.MultipartError.self) {
            try gifType.validate(invalidGIF)
        }
    }

    @Test("WebP image type validates RIFF container")
    func webpValidation() async throws {
        // WebP signature: RIFF + 4 bytes size + WEBP
        let validWebP = "RIFF".data(using: .ascii)! +
                       Data([0x20, 0x00, 0x00, 0x00]) + // File size (little endian)
                       "WEBP".data(using: .ascii)!
        let invalidWebP = "RIFF".data(using: .ascii)! +
                         Data([0x20, 0x00, 0x00, 0x00]) +
                         "WAVE".data(using: .ascii)! // WAV file

        let webpType = Multipart.FileUpload.FileType.image(.webp)

        // Valid WebP should pass
        #expect(throws: Never.self) {
            try webpType.validate(validWebP)
        }

        // Invalid WebP should throw
        #expect(throws: Multipart.FileUpload.MultipartError.self) {
            try webpType.validate(invalidWebP)
        }
    }

    @Test("TIFF image type validates endianness markers")
    func tiffValidation() async throws {
        let intelTIFF = Data([0x49, 0x49, 0x2A, 0x00]) // Intel byte order
        let motorolaTIFF = Data([0x4D, 0x4D, 0x00, 0x2A]) // Motorola byte order
        let invalidTIFF = Data([0x00, 0x00, 0x00, 0x00])

        let tiffType = Multipart.FileUpload.FileType.image(.tiff)

        // Both byte orders should pass
        #expect(throws: Never.self) {
            try tiffType.validate(intelTIFF)
        }

        #expect(throws: Never.self) {
            try tiffType.validate(motorolaTIFF)
        }

        // Invalid TIFF should throw
        #expect(throws: Multipart.FileUpload.MultipartError.self) {
            try tiffType.validate(invalidTIFF)
        }
    }

    @Test("BMP image type validates bitmap signature")
    func bmpValidation() async throws {
        let validBMP = Data([0x42, 0x4D]) + Data(repeating: 0x00, count: 10) // BM header
        let invalidBMP = Data([0x50, 0x4E]) // Not BM

        let bmpType = Multipart.FileUpload.FileType.image(.bmp)

        // Valid BMP should pass
        #expect(throws: Never.self) {
            try bmpType.validate(validBMP)
        }

        // Invalid BMP should throw
        #expect(throws: Multipart.FileUpload.MultipartError.self) {
            try bmpType.validate(invalidBMP)
        }
    }

    @Test("HEIC image type validates container format")
    func heicValidation() async throws {
        // HEIC: 4 bytes size + "ftyp" + "heic" + additional data
        let validHEIC = Data([0x00, 0x00, 0x00, 0x20]) + // Size
                       "ftyp".data(using: .ascii)! +
                       "heic".data(using: .ascii)! +
                       Data(repeating: 0x00, count: 16)
        let invalidHEIC = Data([0x00, 0x00, 0x00, 0x20]) +
                         "ftyp".data(using: .ascii)! +
                         "jpeg".data(using: .ascii)! // Wrong brand

        let heicType = Multipart.FileUpload.FileType.image(.heic)

        // Valid HEIC should pass
        #expect(throws: Never.self) {
            try heicType.validate(validHEIC)
        }

        // Invalid HEIC should throw
        #expect(throws: Multipart.FileUpload.MultipartError.self) {
            try heicType.validate(invalidHEIC)
        }
    }

    @Test("AVIF image type validates container format")
    func avifValidation() async throws {
        // AVIF: 4 bytes size + "ftyp" + "avif" + additional data
        let validAVIF = Data([0x00, 0x00, 0x00, 0x20]) + // Size
                       "ftyp".data(using: .ascii)! +
                       "avif".data(using: .ascii)! +
                       Data(repeating: 0x00, count: 16)
        let invalidAVIF = Data([0x00, 0x00, 0x00, 0x20]) +
                         "ftyp".data(using: .ascii)! +
                         "heic".data(using: .ascii)! // Wrong brand

        let avifType = Multipart.FileUpload.FileType.image(.avif)

        // Valid AVIF should pass
        #expect(throws: Never.self) {
            try avifType.validate(validAVIF)
        }

        // Invalid AVIF should throw
        #expect(throws: Multipart.FileUpload.MultipartError.self) {
            try avifType.validate(invalidAVIF)
        }
    }
}

// MARK: - FormField Tests

@Suite("FormField Functionality")
struct FormFieldTests {

    @Test("FormField initializes correctly with all parameters")
    func formFieldInitialization() {
        let data = "test content".data(using: .utf8)!
        let field = Multipart.FormField(
            name: "test_field",
            filename: "test.txt",
            contentType: "text/plain",
            data: data
        )

        #expect(field.name == "test_field")
        #expect(field.filename == "test.txt")
        #expect(field.contentType == "text/plain")
        #expect(field.data == data)
    }

    @Test("FormField initializes with optional parameters")
    func formFieldOptionalParameters() {
        let data = "simple content".data(using: .utf8)!
        let field = Multipart.FormField(
            name: "simple_field",
            data: data
        )

        #expect(field.name == "simple_field")
        #expect(field.filename == nil)
        #expect(field.contentType == nil)
        #expect(field.data == data)
    }
}

// MARK: - Multipart Boundary and Header Tests

@Suite("Multipart Format Generation")
struct MultipartFormatTests {

    @Test("FileUpload generates proper multipart boundaries")
    func boundaryGeneration() throws {
        let upload = Multipart.FileUpload(
            fieldName: "document",
            filename: "test.pdf",
            fileType: .pdf
        )

        var data = Data()
        try upload.appendBoundary(to: &data)

        let boundaryString = String(data: data, encoding: .utf8)!
        #expect(boundaryString == "--\(upload.boundary)\r\n")
        #expect(boundaryString.hasPrefix("--Boundary-"))
        #expect(boundaryString.hasSuffix("\r\n"))
    }

    @Test("FileUpload generates proper multipart headers")
    func headerGeneration() throws {
        let upload = Multipart.FileUpload(
            fieldName: "avatar",
            filename: "profile.jpg",
            fileType: .image(.jpeg)
        )

        var data = Data()
        try upload.appendHeaders(to: &data)

        let headersString = String(data: data, encoding: .utf8)!
        #expect(headersString.contains("Content-Disposition: form-data"))
        #expect(headersString.contains("name=\"avatar\""))
        #expect(headersString.contains("filename=\"profile.jpg\""))
        #expect(headersString.contains("Content-Type: image/jpeg"))
        #expect(headersString.hasSuffix("\r\n\r\n"))
    }

    @Test("FileUpload generates proper closing boundary")
    func closingBoundaryGeneration() throws {
        let upload = Multipart.FileUpload(
            fieldName: "file",
            filename: "test.txt",
            fileType: .text
        )

        var data = Data()
        try upload.appendClosingBoundary(to: &data)

        let closingString = String(data: data, encoding: .utf8)!
        #expect(closingString == "\r\n--\(upload.boundary)--\r\n")
        #expect(closingString.hasPrefix("\r\n--Boundary-"))
        #expect(closingString.hasSuffix("--\r\n"))
    }
}

// MARK: - Error Handling Tests

@Suite("Error Handling")
struct ErrorHandlingTests {

    @Test("MultipartError provides proper descriptions")
    func errorDescriptions() {
        let fileTooLargeError = Multipart.FileUpload.MultipartError.fileTooLarge(
            size: 1000,
            maxSize: 500
        )
        #expect(fileTooLargeError.errorDescription?.contains("1000") == true)
        #expect(fileTooLargeError.errorDescription?.contains("500") == true)

        let invalidContentError = Multipart.FileUpload.MultipartError.invalidContentType("invalid/type")
        #expect(invalidContentError.errorDescription?.contains("invalid/type") == true)

        let contentMismatchError = Multipart.FileUpload.MultipartError.contentMismatch(
            expected: "image/png",
            detected: "image/jpeg"
        )
        #expect(contentMismatchError.errorDescription?.contains("image/png") == true)
        #expect(contentMismatchError.errorDescription?.contains("image/jpeg") == true)

        let emptyDataError = Multipart.FileUpload.MultipartError.emptyData
        #expect(emptyDataError.errorDescription?.contains("Empty") == true)

        let malformedBoundaryError = Multipart.FileUpload.MultipartError.malformedBoundary
        #expect(malformedBoundaryError.errorDescription?.contains("boundary") == true)

        let encodingError = Multipart.FileUpload.MultipartError.encodingError
        #expect(encodingError.errorDescription?.contains("encode") == true)
    }

    @Test("MultipartError equality works correctly")
    func errorEquality() {
        let error1 = Multipart.FileUpload.MultipartError.fileTooLarge(size: 100, maxSize: 50)
        let error2 = Multipart.FileUpload.MultipartError.fileTooLarge(size: 100, maxSize: 50)
        let error3 = Multipart.FileUpload.MultipartError.fileTooLarge(size: 200, maxSize: 50)

        #expect(error1 == error2)
        #expect(error1 != error3)

        let emptyError1 = Multipart.FileUpload.MultipartError.emptyData
        let emptyError2 = Multipart.FileUpload.MultipartError.emptyData
        #expect(emptyError1 == emptyError2)
    }
}

// MARK: - Integration Tests

@Suite("Integration Tests")
struct IntegrationTests {

    @Test("Complete multipart form construction works")
    func completeMultipartForm() throws {
        let upload = Multipart.FileUpload(
            fieldName: "document",
            filename: "report.pdf",
            fileType: .pdf,
            maxSize: 1024 * 1024 // 1MB
        )

        let pdfContent = "%PDF-1.4\nHello World PDF Content".data(using: .utf8)!

        // Validate the content
        try upload.validate(pdfContent)

        // Build complete multipart form
        var formData = Data()
        try upload.appendBoundary(to: &formData)
        try upload.appendHeaders(to: &formData)
        formData.append(pdfContent)
        try upload.appendClosingBoundary(to: &formData)

        let formString = String(data: formData, encoding: .utf8)!

        // Verify structure
        #expect(formString.contains("--\(upload.boundary)"))
        #expect(formString.contains("Content-Disposition: form-data"))
        #expect(formString.contains("name=\"document\""))
        #expect(formString.contains("filename=\"report.pdf\""))
        #expect(formString.contains("Content-Type: application/pdf"))
        #expect(formString.contains("Hello World PDF Content"))
        #expect(formString.contains("--\(upload.boundary)--"))

        // Verify content type header
        #expect(upload.contentType == "multipart/form-data; boundary=\(upload.boundary)")
    }

    @Test("File type validation works with real-world data")
    func realWorldFileValidation() throws {
        // Test with various file types
        let testCases: [(Multipart.FileUpload.FileType, Data, Bool)] = [
            // Valid cases
            (.pdf, "%PDF-1.4".data(using: .utf8)!, true),
            (.csv, "name,age\nJohn,30".data(using: .utf8)!, true),
            (.text, "Any text content".data(using: .utf8)!, true),
            (.json, "{\"valid\": \"json\"}".data(using: .utf8)!, true),
            (.image(.jpeg), Data([0xFF, 0xD8, 0xFF, 0xE0]), true),
            (.image(.png), Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]), true),

            // Invalid cases
            (.pdf, "Not a PDF".data(using: .utf8)!, false),
            (.image(.jpeg), Data([0x89, 0x50, 0x4E, 0x47]), false), // PNG header for JPEG
            (.image(.png), Data([0xFF, 0xD8, 0xFF]), false) // JPEG header for PNG
        ]

        for (fileType, data, shouldSucceed) in testCases {
            if shouldSucceed {
                #expect(throws: Never.self) {
                    try fileType.validate(data)
                }
            } else {
                #expect(throws: Multipart.FileUpload.MultipartError.self) {
                    try fileType.validate(data)
                }
            }
        }
    }

    @Test("Multiple file uploads with different types")
    func multipleFileUploads() throws {
        let imageUpload = Multipart.FileUpload(
            fieldName: "avatar",
            filename: "profile.jpg",
            fileType: .image(.jpeg)
        )

        let documentUpload = Multipart.FileUpload(
            fieldName: "resume",
            filename: "resume.pdf",
            fileType: .pdf
        )

        // Ensure different boundaries
        #expect(imageUpload.boundary != documentUpload.boundary)

        // Validate both can handle their respective content types
        let jpegData = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10])
        let pdfData = "%PDF-1.4\nContent".data(using: .utf8)!

        #expect(throws: Never.self) {
            try imageUpload.validate(jpegData)
        }

        #expect(throws: Never.self) {
            try documentUpload.validate(pdfData)
        }

        // Cross-validation should fail
        #expect(throws: Multipart.FileUpload.MultipartError.self) {
            try imageUpload.validate(pdfData)
        }

        #expect(throws: Multipart.FileUpload.MultipartError.self) {
            try documentUpload.validate(jpegData)
        }
    }
}

// MARK: - Performance Tests

@Suite("Performance Tests")
struct PerformanceTests {

    @Test("Boundary generation performance")
    func boundaryGenerationPerformance() {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Generate 1000 boundaries
        var boundaries: Set<String> = []
        for _ in 0..<1000 {
            let upload = Multipart.FileUpload(
                fieldName: "test",
                filename: "test.txt",
                fileType: .text
            )
            boundaries.insert(upload.boundary)
        }

        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

        // Ensure all boundaries are unique
        #expect(boundaries.count == 1000)

        // Should complete within reasonable time (less than 1 second)
        #expect(timeElapsed < 1.0)
    }

    @Test("Large file validation performance")
    func largeFileValidationPerformance() throws {
        let largeData = Data(repeating: 0x41, count: 1024 * 1024) // 1MB of 'A's
        let upload = Multipart.FileUpload(
            fieldName: "large_file",
            filename: "large.txt",
            fileType: .text,
            maxSize: 2 * 1024 * 1024 // 2MB limit
        )

        let startTime = CFAbsoluteTimeGetCurrent()
        try upload.validate(largeData)
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

        // Validation should be fast even for large files
        #expect(timeElapsed < 0.1)
    }
}
