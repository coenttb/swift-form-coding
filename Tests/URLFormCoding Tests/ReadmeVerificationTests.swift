import Foundation
import Testing
import URLFormCoding
import URLFormCodingURLRouting
import URLMultipartFormCoding

@Suite("README Verification Tests")
struct ReadmeVerificationTests {

  // MARK: - Basic Form Handling (Line 37-62)

  @Test("README Line 37-62: Basic Form Handling")
  func testBasicFormHandling() throws {
    // Define your data model
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

    // Verify it contains the expected fields
    let formString = String(data: formData, encoding: .utf8)!
    #expect(formString.contains("username=john"))
    #expect(formString.contains("password=secret"))
    #expect(formString.contains("rememberMe=true"))

    // Decode from form data
    let formStringInput = "username=john&password=secret&rememberMe=true"
    let decoded = try decoder.decode(LoginRequest.self, from: Data(formStringInput.utf8))
    #expect(decoded.username == "john")
    #expect(decoded.password == "secret")
    #expect(decoded.rememberMe == true)
  }

  // MARK: - URLRouting Integration (Line 64-83)

  @Test("README Line 64-83: URLRouting Integration")
  func testURLRoutingIntegration() throws {
    // Define your data model
    struct LoginRequest: Codable {
      let username: String
      let password: String
      let rememberMe: Bool
    }

    // Create a form conversion
    let loginForm = Form.Conversion(LoginRequest.self)

    // Handle form data
    let formData = "username=john&password=secret&rememberMe=true"
    let request = try loginForm.apply(Data(formData.utf8))
    #expect(request.username == "john")
    #expect(request.password == "secret")
    #expect(request.rememberMe == true)
  }

  // MARK: - Multipart File Upload (Line 82-99)

  @Test("README Line 82-99: Multipart File Upload")
  func testMultipartFileUpload() {
    // Define file upload for user avatars
    let avatarUpload = Multipart.FileUpload(
      fieldName: "avatar",
      filename: "profile.jpg",
      fileType: .image(.jpeg),
      maxSize: 2 * 1024 * 1024  // 2MB limit
    )

    // The file upload automatically validates:
    // - File size limits
    // - JPEG magic number signature
    // - Content type matching

    // Verify file upload properties
    #expect(avatarUpload.contentType.contains("multipart/form-data"))
    #expect(avatarUpload.contentType.contains("boundary="))
  }
}
