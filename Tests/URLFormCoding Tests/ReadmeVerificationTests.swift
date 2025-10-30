import Foundation
import Testing

@testable import URLFormCoding

@Suite("README Verification Tests")
struct ReadmeVerificationTests {

  // MARK: - Basic Form Handling (Lines 41-66)

  @Test("README Line 41-66: Basic Form Handling")
  func testBasicFormHandling() throws {
    struct LoginRequest: Codable, Equatable {
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

    // Verify format
    let formString = String(data: formData, encoding: .utf8)!
    #expect(formString.contains("username=john"))
    #expect(formString.contains("password=secret"))
    #expect(formString.contains("rememberMe=true"))

    // Decode from form data
    let formDataString = "username=john&password=secret&rememberMe=true"
    let decoded = try decoder.decode(LoginRequest.self, from: Data(formDataString.utf8))
    #expect(decoded.username == "john")
    #expect(decoded.password == "secret")
    #expect(decoded.rememberMe == true)
  }

  // MARK: - URLRouting Integration (Lines 67-84)

  @Test("README Line 67-84: URLRouting Integration - Import Verification")
  func testURLRoutingIntegrationImports() {
    // This test verifies that the imports work as shown in README
    // Actual routing integration requires URLRouting package

    struct LoginRequest: Codable {
      let username: String
      let password: String
      let rememberMe: Bool
    }

    // Verify Form types are accessible
    _ = Form.Encoder()
    _ = Form.Decoder()

    // Verify basic form operations work
    let formData = "username=john&password=secret&rememberMe=true"
    let data = Data(formData.utf8)

    // This matches the README's example of applying form data
    let decoder = Form.Decoder()
    let request = try? decoder.decode(LoginRequest.self, from: data)
    #expect(request?.username == "john")
  }

  // MARK: - Custom Form Decoding Strategies (Lines 113-135)

  @Test("README Line 113-135: Custom Form Decoding Strategies")
  func testCustomFormDecodingStrategies() throws {
    struct ComplexUser: Codable, Equatable {
      let name: String
      let age: Int
    }

    // Configure decoder for nested objects
    let decoder = Form.Decoder()
    decoder.parsingStrategy = .brackets
    decoder.dateDecodingStrategy = .iso8601
    decoder.arrayDecodingStrategy = .brackets

    // Test basic decoding with configured decoder
    let formData = "name=John&age=30"
    let user = try decoder.decode(ComplexUser.self, from: Data(formData.utf8))

    #expect(user.name == "John")
    #expect(user.age == 30)
  }

  // MARK: - Supported Parsing Strategies (Lines 137-143)

  @Test("README Line 137-143: Supported Parsing Strategies")
  func testSupportedParsingStrategies() throws {
    struct User: Codable, Equatable {
      let name: String
      let age: Int
    }

    // Test Default strategy: simple key-value pairs
    let defaultDecoder = Form.Decoder()
    let simpleData = "name=value&age=30"
    let user1 = try defaultDecoder.decode(User.self, from: Data(simpleData.utf8))
    #expect(user1.name == "value")
    #expect(user1.age == 30)

    // Test Brackets strategy: nested objects
    let bracketsDecoder = Form.Decoder()
    bracketsDecoder.parsingStrategy = .brackets
    // Note: Actual bracket parsing would be tested with nested structures
    // This verifies the strategy can be set
    #expect(bracketsDecoder.parsingStrategy == .brackets)

    // Test Accumulate strategy: multiple values per key
    let accumulateDecoder = Form.Decoder()
    accumulateDecoder.parsingStrategy = .accumulateValues
    #expect(accumulateDecoder.parsingStrategy == .accumulateValues)
  }

  // MARK: - Form Encoder & Decoder (Lines 192-213)

  @Test("README Line 192-213: Form Encoder & Decoder")
  func testFormEncoderAndDecoder() throws {
    struct User: Codable, Equatable {
      let name: String
    }

    // Basic encoding/decoding
    let encoder = Form.Encoder()
    let decoder = Form.Decoder()

    let user = User(name: "John")
    let formData = try encoder.encode(user)

    // Verify encoded format
    let formString = String(data: formData, encoding: .utf8)!
    #expect(formString.contains("name=John"))

    // Decode from form data
    let decoded = try decoder.decode(User.self, from: formData)
    #expect(decoded.name == "John")
    #expect(decoded == user)
  }

  // MARK: - Security Features (Lines 256-267)

  @Test("README Line 256-267: Security Features - Input Validation")
  func testSecurityFeaturesInputValidation() throws {
    struct SafeData: Codable {
      let field: String
    }

    // Test that decoder handles URL-encoded data safely
    let decoder = Form.Decoder()

    // URL-encoded data with special characters
    let safeData = "field=Hello%20World"
    let decoded = try decoder.decode(SafeData.self, from: Data(safeData.utf8))
    #expect(decoded.field == "Hello World")

    // Verify type safety - wrong type should fail
    struct WrongType: Codable {
      let field: Int
    }

    #expect(throws: Error.self) {
      try decoder.decode(WrongType.self, from: Data(safeData.utf8))
    }
  }

  // MARK: - Error Handling (Lines 269-295)

  @Test("README Line 269-295: Error Handling")
  func testErrorHandling() {
    struct User: Codable {
      let name: String
      let age: Int
    }

    let formDecoder = Form.Decoder()

    // Test invalid form data format
    let invalidData = "not-valid-form-data-structure"

    do {
      let _ = try formDecoder.decode(User.self, from: Data(invalidData.utf8))
      Issue.record("Expected decoding to fail")
    } catch {
      // Error is expected for invalid format
      #expect(error is DecodingError)
    }
  }
}
