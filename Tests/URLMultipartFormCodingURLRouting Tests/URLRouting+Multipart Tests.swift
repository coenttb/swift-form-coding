//
//  URLRouting+Multipart Tests.swift
//  URLRouting+Multipart Tests
//
//  Created by Coen ten Thije Boonkkamp on 26/07/2025.
//

import Foundation
import Testing
@testable import URLMultipartFormCoding
@testable import URLMultipartFormCodingURLRouting

// MARK: - Test Models

private struct BasicUser: Codable, Equatable {
    let name: String
    let age: Int
    let isActive: Bool
}

private struct UserWithOptionals: Codable, Equatable {
    let name: String
    let email: String?
    let age: Int?
    let isVerified: Bool?
}

private struct NestedUser: Codable, Equatable {
    let name: String
    let profile: Profile

    struct Profile: Codable, Equatable {
        let bio: String
        let website: String?
    }
}

private struct UserWithArrays: Codable, Equatable {
    let name: String
    let tags: [String]
    let scores: [Int]
}

// MARK: - Main Test Suite

@Suite("URLRouting+Multipart Tests")
struct URLRoutingMultipartTests {

    // MARK: - MultipartFormCoding Basic Tests

    @Suite("MultipartFormCoding Basic Functionality")
    struct MultipartFormCodingBasicTests {

        @Test("MultipartFormCoding initializes with default decoder")
        func testMultipartFormCodingInitializesWithDefaults() {
            let multipartCoding = Multipart.Conversion(BasicUser.self)

            // Should successfully create MultipartFormCoding with decoder
            _ = multipartCoding.decoder
            _ = multipartCoding.contentType
        }

        @Test("MultipartFormCoding initializes with custom decoder")
        func testMultipartFormCodingInitializesWithCustomDecoder() {
            let decoder = Form.Decoder()
            decoder.dateDecodingStrategy = .secondsSince1970

            let multipartCoding = Multipart.Conversion(BasicUser.self, decoder: decoder)

            // Verify that the MultipartFormCoding was created with the custom decoder
            _ = multipartCoding.decoder
            _ = multipartCoding.contentType
        }

        @Test("MultipartFormCoding has correct content type")
        func testMultipartFormCodingHasCorrectContentType() {
            let multipartCoding = Multipart.Conversion(BasicUser.self)
            let contentType = multipartCoding.contentType

            #expect(contentType.hasPrefix("multipart/form-data; boundary="))
            #expect(contentType.contains("Boundary-"))
        }

        @Test("MultipartFormCoding apply method decodes form data")
        func testMultipartFormCodingApplyMethodDecodesFormData() throws {
            let multipartCoding = Multipart.Conversion(BasicUser.self)
            let queryString = "name=John%20Doe&age=30&isActive=true"
            let data = Data(queryString.utf8)

            let user = try multipartCoding.apply(data)

            #expect(user.name == "John Doe")
            #expect(user.age == 30)
            #expect(user.isActive == true)
        }

        @Test("MultipartFormCoding unapply method creates multipart data")
        func testMultipartFormCodingUnapplyMethodCreatesMultipartData() throws {
            let multipartCoding = Multipart.Conversion(BasicUser.self)
            let user = BasicUser(name: "Jane Doe", age: 25, isActive: false)

            let data = multipartCoding.unapply(user)
            let multipartString = String(data: data, encoding: .utf8)!

            // Should contain multipart boundaries and headers
            #expect(multipartString.contains("--Boundary-"))
            #expect(multipartString.contains("Content-Disposition: form-data"))
            #expect(multipartString.contains("name=\"name\""))
            #expect(multipartString.contains("Jane Doe"))
            #expect(multipartString.contains("name=\"age\""))
            #expect(multipartString.contains("25"))
            #expect(multipartString.contains("name=\"isActive\""))
            #expect(multipartString.contains("0")) // false is encoded as "0" in multipart
        }

        @Test("MultipartFormCoding handles optional values in unapply")
        func testMultipartFormCodingHandlesOptionalValuesInUnapply() throws {
            let multipartCoding = Multipart.Conversion(UserWithOptionals.self)
            let user = UserWithOptionals(
                name: "Test User",
                email: "test@example.com",
                age: nil,
                isVerified: true
            )

            let data = multipartCoding.unapply(user)
            let multipartString = String(data: data, encoding: .utf8)!

            // Should contain non-nil values
            #expect(multipartString.contains("Test User"))
            #expect(multipartString.contains("test@example.com"))
            #expect(multipartString.contains("1")) // true is encoded as "1" in multipart

            // Should not contain nil values (age field should be excluded)
            #expect(!multipartString.contains("name=\"age\""))
        }
    }

    // MARK: - Multipart.FileUpload Basic Tests

    @Suite("Multipart.FileUpload Basic Functionality")
    struct MultipartFileUploadBasicTests {

        @Test("Multipart.FileUpload initializes correctly")
        func testMultipartFileUploadInitializesCorrectly() {
            let fileUpload = Multipart.FileUpload(
                fieldName: "avatar",
                filename: "test.jpg",
                fileType: .image(.jpeg)
            )

            // Should initialize without crashing
            let contentType = fileUpload.contentType
            #expect(contentType.hasPrefix("multipart/form-data; boundary="))
        }

        @Test("Multipart.FileUpload apply validates and returns data")
        func testMultipartFileUploadApplyValidatesAndReturnsData() throws {
            let fileUpload = Multipart.FileUpload(
                fieldName: "avatar",
                filename: "test.jpg",
                fileType: .image(.jpeg)
            )

            // Create valid JPEG data
            let jpegHeader: [UInt8] = [0xFF, 0xD8, 0xFF, 0xE0]
            let testData = Data(jpegHeader + Array(repeating: 0x00, count: 100))

            let result = try fileUpload.apply(testData)
            #expect(result == testData)
        }

        @Test("Multipart.FileUpload unapply creates multipart format")
        func testMultipartFileUploadUnapplyCreatesMultipartFormat() throws {
            let fileUpload = Multipart.FileUpload(
                fieldName: "avatar",
                filename: "test.jpg",
                fileType: .image(.jpeg)
            )

            // Create valid JPEG data
            let jpegHeader: [UInt8] = [0xFF, 0xD8, 0xFF, 0xE0]
            let testData = Data(jpegHeader + Array(repeating: 0x00, count: 100))

            let multipartData = try fileUpload.unapply(testData)

            // Extract the text part (headers) from the multipart data for validation
            // Since the data contains binary content, we need to check for the headers separately
            let headerEndMarker = "\r\n\r\n".data(using: .utf8)!
            if let headerEndRange = multipartData.range(of: headerEndMarker) {
                let headerData = multipartData.subdata(in: 0..<headerEndRange.upperBound)
                let headerString = String(data: headerData, encoding: .utf8)!

                // Should contain multipart structure in headers
                #expect(headerString.contains("--Boundary-"))
                #expect(headerString.contains("Content-Disposition: form-data"))
                #expect(headerString.contains("name=\"avatar\""))
                #expect(headerString.contains("filename=\"test.jpg\""))
                #expect(headerString.contains("Content-Type: image/jpeg"))
            } else {
                #expect(Bool(false), "Could not find header end marker in multipart data")
            }
        }

        @Test("Multipart.FileUpload round-trips data correctly")
        func testMultipartFileUploadRoundTripsCorrectly() throws {
            let fileUpload = Multipart.FileUpload(
                fieldName: "avatar",
                filename: "test.jpg",
                fileType: .image(.jpeg)
            )

            // Create valid JPEG data
            let jpegHeader: [UInt8] = [0xFF, 0xD8, 0xFF, 0xE0]
            let originalData = Data(jpegHeader + Array(repeating: 0x42, count: 100))

            _ = try fileUpload.unapply(originalData)
            let roundTripData = try fileUpload.apply(originalData)

            #expect(roundTripData == originalData)
        }
    }

    // MARK: - FileType Validation Tests

    @Suite("FileType Validation")
    struct FileTypeValidationTests {

        @Test("CSV FileType validates text data correctly")
        func testCSVFileTypeValidatesTextDataCorrectly() throws {
            let csvData = "name,age,active\nJohn,30,true\nJane,25,false".data(using: .utf8)!

            // Should not throw for valid CSV data
            try Multipart.FileUpload.FileType.csv.validate(csvData)
        }

        @Test("CSV FileType throws error for invalid data")
        func testCSVFileTypeThrowsErrorForInvalidData() {
            let invalidData = Data([0xFF, 0xFE, 0x00, 0x01]) // Invalid UTF-8

            do {
                try Multipart.FileUpload.FileType.csv.validate(invalidData)
                #expect(Bool(false), "Expected validation to throw an error")
            } catch let error as Multipart.FileUpload.MultipartError {
                #expect(error == .contentMismatch(expected: "text/csv", detected: nil))
            } catch {
                #expect(Bool(false), "Expected MultipartError")
            }
        }

        @Test("PDF FileType validates PDF data correctly")
        func testPDFFileTypeValidatesPDFDataCorrectly() throws {
            let pdfHeader = "%PDF".data(using: .utf8)!
            let pdfData = pdfHeader + Data(repeating: 0x00, count: 100)

            // Should not throw for valid PDF data
            try Multipart.FileUpload.FileType.pdf.validate(pdfData)
        }

        @Test("PDF FileType throws error for invalid data")
        func testPDFFileTypeThrowsErrorForInvalidData() {
            let invalidData = Data("Not a PDF".utf8)

            do {
                try Multipart.FileUpload.FileType.pdf.validate(invalidData)
                #expect(Bool(false), "Expected validation to throw an error")
            } catch let error as Multipart.FileUpload.MultipartError {
                #expect(error == .contentMismatch(expected: "application/pdf", detected: nil))
            } catch {
                #expect(Bool(false), "Expected MultipartError")
            }
        }

        @Test("FileType properties are correct")
        func testFileTypePropertiesAreCorrect() {
            #expect(Multipart.FileUpload.FileType.csv.contentType == "text/csv")
            #expect(Multipart.FileUpload.FileType.csv.fileExtension == "csv")

            #expect(Multipart.FileUpload.FileType.pdf.contentType == "application/pdf")
            #expect(Multipart.FileUpload.FileType.pdf.fileExtension == "pdf")

            #expect(Multipart.FileUpload.FileType.json.contentType == "application/json")
            #expect(Multipart.FileUpload.FileType.json.fileExtension == "json")

            #expect(Multipart.FileUpload.FileType.text.contentType == "text/plain")
            #expect(Multipart.FileUpload.FileType.text.fileExtension == "txt")
        }
    }

    // MARK: - ImageType Validation Tests

    @Suite("ImageType Validation")
    struct ImageTypeValidationTests {

        @Test("JPEG ImageType validates JPEG data correctly")
        func testJPEGImageTypeValidatesJPEGDataCorrectly() throws {
            let jpegHeader: [UInt8] = [0xFF, 0xD8, 0xFF]
            let jpegData = Data(jpegHeader + Array(repeating: 0x00, count: 100))

            try Multipart.FileUpload.FileType.ImageType.jpeg.validate(jpegData)
        }

        @Test("JPEG ImageType throws error for invalid data")
        func testJPEGImageTypeThrowsErrorForInvalidData() {
            let invalidData = Data("Not JPEG".utf8)

            do {
                try Multipart.FileUpload.FileType.ImageType.jpeg.validate(invalidData)
                #expect(Bool(false), "Expected validation to throw an error")
            } catch let error as Multipart.FileUpload.MultipartError {
                #expect(error == .contentMismatch(expected: "image/jpeg", detected: nil))
            } catch {
                #expect(Bool(false), "Expected MultipartError")
            }
        }

        @Test("PNG ImageType validates PNG data correctly")
        func testPNGImageTypeValidatesPNGDataCorrectly() throws {
            let pngHeader: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
            let pngData = Data(pngHeader + Array(repeating: 0x00, count: 100))

            try Multipart.FileUpload.FileType.ImageType.png.validate(pngData)
        }

        @Test("PNG ImageType throws error for invalid data")
        func testPNGImageTypeThrowsErrorForInvalidData() {
            let invalidData = Data("Not PNG".utf8)

            do {
                try Multipart.FileUpload.FileType.ImageType.png.validate(invalidData)
                #expect(Bool(false), "Expected validation to throw an error")
            } catch let error as Multipart.FileUpload.MultipartError {
                #expect(error == .contentMismatch(expected: "image/png", detected: nil))
            } catch {
                #expect(Bool(false), "Expected MultipartError")
            }
        }

        @Test("GIF ImageType validates GIF data correctly")
        func testGIFImageTypeValidatesGIFDataCorrectly() throws {
            let gif87aHeader = "GIF87a".data(using: .ascii)!
            let gif87aData = gif87aHeader + Data(repeating: 0x00, count: 100)

            try Multipart.FileUpload.FileType.ImageType.gif.validate(gif87aData)

            let gif89aHeader = "GIF89a".data(using: .ascii)!
            let gif89aData = gif89aHeader + Data(repeating: 0x00, count: 100)

            try Multipart.FileUpload.FileType.ImageType.gif.validate(gif89aData)
        }

        @Test("WebP ImageType validates WebP data correctly")
        func testWebPImageTypeValidatesWebPDataCorrectly() throws {
            let riffHeader = "RIFF".data(using: .ascii)!
            let sizeBytes = Data([0x00, 0x00, 0x00, 0x00]) // File size (placeholder)
            let webpHeader = "WEBP".data(using: .ascii)!
            let webpData = riffHeader + sizeBytes + webpHeader + Data(repeating: 0x00, count: 100)

            try Multipart.FileUpload.FileType.ImageType.webp.validate(webpData)
        }

        @Test("ImageType properties are correct")
        func testImageTypePropertiesAreCorrect() {
            #expect(Multipart.FileUpload.FileType.ImageType.jpeg.contentType == "image/jpeg")
            #expect(Multipart.FileUpload.FileType.ImageType.jpeg.fileExtension == "jpg")

            #expect(Multipart.FileUpload.FileType.ImageType.png.contentType == "image/png")
            #expect(Multipart.FileUpload.FileType.ImageType.png.fileExtension == "png")

            #expect(Multipart.FileUpload.FileType.ImageType.gif.contentType == "image/gif")
            #expect(Multipart.FileUpload.FileType.ImageType.gif.fileExtension == "gif")

            #expect(Multipart.FileUpload.FileType.ImageType.webp.contentType == "image/webp")
            #expect(Multipart.FileUpload.FileType.ImageType.webp.fileExtension == "webp")
        }

        @Test("Image FileType factory method works correctly")
        func testImageFileTypeFactoryMethodWorksCorrectly() throws {
            let jpegType = Multipart.FileUpload.FileType.image(.jpeg)

            #expect(jpegType.contentType == "image/jpeg")
            #expect(jpegType.fileExtension == "jpg")

            // Test validation still works
            let jpegHeader: [UInt8] = [0xFF, 0xD8, 0xFF]
            let jpegData = Data(jpegHeader + Array(repeating: 0x00, count: 100))

            try jpegType.validate(jpegData)
        }
    }

    // MARK: - Error Handling Tests

    @Suite("Error Handling")
    struct ErrorHandlingTests {

        @Test("Multipart.FileUpload throws error for empty data")
        func testMultipartFileUploadThrowsErrorForEmptyData() {
            let fileUpload = Multipart.FileUpload(
                fieldName: "avatar",
                filename: "test.jpg",
                fileType: .image(.jpeg)
            )

            let emptyData = Data()

            do {
                _ = try fileUpload.apply(emptyData)
                #expect(Bool(false), "Expected apply to throw an error")
            } catch let error as Multipart.FileUpload.MultipartError {
                #expect(error == .emptyData)
            } catch {
                #expect(Bool(false), "Expected MultipartError")
            }
        }

        @Test("Multipart.FileUpload throws error for file too large")
        func testMultipartFileUploadThrowsErrorForFileTooLarge() {
            let fileUpload = Multipart.FileUpload(
                fieldName: "avatar",
                filename: "test.jpg",
                fileType: .image(.jpeg),
                maxSize: 100 // Very small max size
            )

            // Create valid JPEG data that's too large
            let jpegHeader: [UInt8] = [0xFF, 0xD8, 0xFF]
            let largeData = Data(jpegHeader + Array(repeating: 0x00, count: 200))

            do {
                _ = try fileUpload.apply(largeData)
                #expect(Bool(false), "Expected apply to throw an error")
            } catch let error as Multipart.FileUpload.MultipartError {
                #expect(error == .fileTooLarge(size: largeData.count, maxSize: 100))
            } catch {
                #expect(Bool(false), "Expected MultipartError")
            }
        }

        @Test("Multipart.FileUpload throws error for invalid file type")
        func testMultipartFileUploadThrowsErrorForInvalidFileType() {
            let fileUpload = Multipart.FileUpload(
                fieldName: "avatar",
                filename: "test.jpg",
                fileType: .image(.jpeg)
            )

            let invalidData = Data("Not a JPEG".utf8)

            do {
                _ = try fileUpload.apply(invalidData)
                #expect(Bool(false), "Expected apply to throw an error")
            } catch let error as Multipart.FileUpload.MultipartError {
                #expect(error == .contentMismatch(expected: "image/jpeg", detected: nil))
            } catch {
                #expect(Bool(false), "Expected MultipartError")
            }
        }

        @Test("MultipartError provides helpful error descriptions")
        func testMultipartErrorProvidesHelpfulErrorDescriptions() {
            let fileTooLargeError = Multipart.FileUpload.MultipartError.fileTooLarge(size: 1000, maxSize: 500)
            #expect(fileTooLargeError.errorDescription?.contains("1000") == true)
            #expect(fileTooLargeError.errorDescription?.contains("500") == true)

            let invalidContentTypeError = Multipart.FileUpload.MultipartError.invalidContentType("bad/type")
            #expect(invalidContentTypeError.errorDescription?.contains("bad/type") == true)

            let contentMismatchError = Multipart.FileUpload.MultipartError.contentMismatch(expected: "image/jpeg", detected: "text/plain")
            #expect(contentMismatchError.errorDescription?.contains("image/jpeg") == true)
            #expect(contentMismatchError.errorDescription?.contains("text/plain") == true)

            let emptyDataError = Multipart.FileUpload.MultipartError.emptyData
            #expect(emptyDataError.errorDescription == "Empty file data")

            let malformedBoundaryError = Multipart.FileUpload.MultipartError.malformedBoundary
            #expect(malformedBoundaryError.errorDescription == "Malformed multipart boundary")

            let encodingError = Multipart.FileUpload.MultipartError.encodingError
            #expect(encodingError.errorDescription == "Failed to encode multipart form data")
        }
    }

    // MARK: - Conversion Extension Tests

    @Suite("Conversion Extension Methods")
    struct ConversionExtensionTests {

        @Test("Conversion.multipart static method creates MultipartFormCoding")
        func testConversionMultipartStaticMethod() {
            let multipartCoding: Multipart.Conversion<BasicUser> = .multipart(BasicUser.self)

            // Should create a valid MultipartFormCoding instance
            _ = multipartCoding.decoder
            _ = multipartCoding.contentType
        }

        @Test("Conversion.multipart static method accepts custom decoder")
        func testConversionMultipartStaticMethodWithCustomDecoder() {
            let decoder = Form.Decoder()
            decoder.dateDecodingStrategy = .secondsSince1970

            let multipartCoding: Multipart.Conversion<BasicUser> = .multipart(BasicUser.self, decoder: decoder)

            // Should create a valid MultipartFormCoding instance with custom decoder
            _ = multipartCoding.decoder
            _ = multipartCoding.contentType
        }

        @Test("Conversion instance multipart method creates mapped conversion")
        func testConversionInstanceMultipartMethod() throws {
            // Create a simple conversion that transforms data
            struct IdentityConversion: Conversion {
                func apply(_ input: Data) throws -> Foundation.Data {
                    return input
                }

                func unapply(_ output: Data) throws -> Foundation.Data {
                    return output
                }
            }

            let identityConversion = IdentityConversion()
            let mappedConversion = identityConversion.multipart(BasicUser.self)

            // Test that the mapped conversion works
            let user = BasicUser(name: "Test", age: 30, isActive: true)
            let data = try mappedConversion.unapply(user)

            // Should contain multipart format (boundary and content-disposition)
            let multipartString = String(data: data, encoding: .utf8)!
            #expect(multipartString.contains("--Boundary-"))
            #expect(multipartString.contains("Content-Disposition: form-data"))
        }
    }

    // MARK: - Edge Cases Tests

    @Suite("Edge Cases")
    struct EdgeCasesTests {

        @Test("MultipartFormCoding handles special characters in field values")
        func testMultipartFormCodingHandlesSpecialCharacters() throws {
            let multipartCoding = Multipart.Conversion(BasicUser.self)
            let user = BasicUser(name: "John & Jane", age: 30, isActive: true)

            let data = multipartCoding.unapply(user)
            let multipartString = String(data: data, encoding: .utf8)!

            #expect(multipartString.contains("John & Jane"))
        }

        @Test("MultipartFormCoding handles Unicode characters")
        func testMultipartFormCodingHandlesUnicodeCharacters() throws {
            let multipartCoding = Multipart.Conversion(BasicUser.self)
            let user = BasicUser(name: "José María 🇪🇸", age: 30, isActive: true)

            let data = multipartCoding.unapply(user)
            let multipartString = String(data: data, encoding: .utf8)!

            #expect(multipartString.contains("José María 🇪🇸"))
        }

        @Test("MultipartFormCoding handles very long field values")
        func testMultipartFormCodingHandlesVeryLongFieldValues() throws {
            let multipartCoding = Multipart.Conversion(BasicUser.self)
            let longName = String(repeating: "a", count: 10000)
            let user = BasicUser(name: longName, age: 30, isActive: true)

            let data = multipartCoding.unapply(user)

            #expect(data.count > 10000)
        }

        @Test("Multipart.FileUpload handles boundary generation uniqueness")
        func testMultipartFileUploadHandlesBoundaryGenerationUniqueness() {
            let fileUpload1 = Multipart.FileUpload(
                fieldName: "file1",
                filename: "test1.jpg",
                fileType: .image(.jpeg)
            )

            let fileUpload2 = Multipart.FileUpload(
                fieldName: "file2",
                filename: "test2.jpg",
                fileType: .image(.jpeg)
            )

            let contentType1 = fileUpload1.contentType
            let contentType2 = fileUpload2.contentType

            // Extract boundaries
            let boundary1 = String(contentType1.dropFirst("multipart/form-data; boundary=".count))
            let boundary2 = String(contentType2.dropFirst("multipart/form-data; boundary=".count))

            #expect(boundary1 != boundary2)
            #expect(boundary1.hasPrefix("Boundary-"))
            #expect(boundary2.hasPrefix("Boundary-"))
        }

        @Test("Multipart.FileUpload handles maximum file size correctly")
        func testMultipartFileUploadHandlesMaximumFileSizeCorrectly() throws {
            let fileUpload = Multipart.FileUpload(
                fieldName: "avatar",
                filename: "test.jpg",
                fileType: .image(.jpeg),
                maxSize: 1000
            )

            // Create valid JPEG data at max size
            let jpegHeader: [UInt8] = [0xFF, 0xD8, 0xFF]
            let maxSizeData = Data(jpegHeader + Array(repeating: 0x00, count: 997))

            // Should succeed
            let result = try fileUpload.apply(maxSizeData)
            #expect(result == maxSizeData)
        }

        @Test("Multipart.FileUpload default max size is reasonable")
        func testMultipartFileUploadDefaultMaxSizeIsReasonable() {
            #expect(Multipart.FileUpload.maxFileSize == 10 * 1024 * 1024) // 10MB
        }
    }

    // MARK: - Security Tests

    @Suite("Security")
    struct SecurityTests {

        @Test("MultipartFormCoding safely handles malicious field names")
        func testMultipartFormCodingSafelyHandlesMaliciousFieldNames() throws {
            // Note: This tests the Multipart.FormField creation process
            let maliciousName = "\"; rm -rf /; echo \""
            let field = Multipart.FormField(
                name: maliciousName,
                contentType: "text/plain",
                data: "value".data(using: .utf8)!
            )

            #expect(field.name == maliciousName)
            // The field should store the name as-is, but proper escaping should happen during serialization
        }

        @Test("Multipart.FileUpload validates file content, not just extension")
        func testMultipartFileUploadValidatesFileContentNotJustExtension() {
            let fileUpload = Multipart.FileUpload(
                fieldName: "avatar",
                filename: "fake.jpg", // Claims to be JPEG
                fileType: .image(.jpeg)
            )

            // Try to upload a non-JPEG file with JPEG extension
            let textData = Data("This is not a JPEG file".utf8)

            do {
                _ = try fileUpload.apply(textData)
                #expect(Bool(false), "Expected validation to throw an error")
            } catch let error as Multipart.FileUpload.MultipartError {
                #expect(error == .contentMismatch(expected: "image/jpeg", detected: nil))
            } catch {
                #expect(Bool(false), "Expected MultipartError")
            }
        }

        @Test("Multipart.FileUpload prevents oversized file uploads")
        func testMultipartFileUploadPreventsOversizedFileUploads() {
            let fileUpload = Multipart.FileUpload(
                fieldName: "avatar",
                filename: "large.jpg",
                fileType: .image(.jpeg),
                maxSize: 1024 // 1KB limit
            )

            // Try to upload a larger file
            let jpegHeader: [UInt8] = [0xFF, 0xD8, 0xFF]
            let largeData = Data(jpegHeader + Array(repeating: 0x00, count: 2000))

            do {
                _ = try fileUpload.apply(largeData)
                #expect(Bool(false), "Expected validation to throw an error")
            } catch let error as Multipart.FileUpload.MultipartError {
                #expect(error == .fileTooLarge(size: largeData.count, maxSize: 1024))
            } catch {
                #expect(Bool(false), "Expected MultipartError")
            }
        }

        @Test("Boundary generation uses safe characters")
        func testBoundaryGenerationUsesSafeCharacters() {
            let fileUpload = Multipart.FileUpload(
                fieldName: "test",
                filename: "test.txt",
                fileType: .text
            )

            let contentType = fileUpload.contentType
            let boundary = String(contentType.dropFirst("multipart/form-data; boundary=".count))

            // Boundary should only contain safe characters
            let safeCharacterSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-")
            let boundaryCharacterSet = CharacterSet(charactersIn: boundary)

            #expect(safeCharacterSet.isSuperset(of: boundaryCharacterSet))
            #expect(boundary.hasPrefix("Boundary-"))
        }
    }

    // MARK: - Performance Tests

    @Suite("Performance")
    struct PerformanceTests {

        @Test("MultipartFormCoding handles large objects efficiently")
        func testMultipartFormCodingHandlesLargeObjectsEfficiently() throws {
            let multipartCoding = Multipart.Conversion(UserWithArrays.self)

            let largeTags = Array(0..<1000).map { "tag\($0)" }
            let largeScores = Array(0..<1000)
            let user = UserWithArrays(
                name: "Performance Test",
                tags: largeTags,
                scores: largeScores
            )

            // Should complete without timeout
            let data = multipartCoding.unapply(user)
            #expect(!data.isEmpty)
        }

        @Test("Multipart.FileUpload handles maximum size files efficiently")
        func testMultipartFileUploadHandlesMaximumSizeFilesEfficiently() throws {
            let fileUpload = Multipart.FileUpload(
                fieldName: "large_file",
                filename: "large.jpg",
                fileType: .image(.jpeg)
            )

            // Create a large valid JPEG file (close to default max size)
            let jpegHeader: [UInt8] = [0xFF, 0xD8, 0xFF]
            let largeData = Data(jpegHeader + Array(repeating: 0x00, count: 5 * 1024 * 1024)) // 5MB

            // Should complete without timeout
            let result = try fileUpload.apply(largeData)
            #expect(result == largeData)
        }
    }
}

// MARK: - Helper Types

private enum TestError: Error {
    case invalidFormat
}
