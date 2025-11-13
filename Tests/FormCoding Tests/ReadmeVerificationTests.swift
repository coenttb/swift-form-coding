import Testing
import Foundation
@testable import FormCoding

@Suite("README Verification")
struct ReadmeVerificationTests {

    @Test("Example from README: URL Form Encoding")
    func urlFormEncoding() throws {
        // URL Form Encoding
        struct LoginForm: Codable {
            let username: String
            let password: String
        }

        let encoder = Form.Encoder()
        let form = LoginForm(username: "john", password: "secret")
        let formData = try encoder.encode(form)

        // Verify data was encoded
        #expect(formData.count > 0)

        // Verify it can be decoded back
        let decoder = Form.Decoder()
        let decoded = try decoder.decode(LoginForm.self, from: formData)
        #expect(decoded.username == "john")
        #expect(decoded.password == "secret")
    }

    @Test("Example from README: Multipart File Upload")
    func multipartFileUpload() throws {
        // Multipart File Upload
        let imageUpload = try Multipart.FileUpload(
            fieldName: "avatar",
            filename: "profile.jpg",
            fileType: .image(.jpeg),
            maxSize: 5 * 1024 * 1024
        )

        // Verify properties
        #expect(imageUpload.fieldName == "avatar")
        #expect(imageUpload.filename == "profile.jpg")
        #expect(imageUpload.maxSize == 5 * 1024 * 1024)
    }
}
