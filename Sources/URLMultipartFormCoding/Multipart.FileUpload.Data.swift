//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 29/12/2024.
//

import Foundation

extension Multipart.FileUpload {
    public struct Data {
        let fieldName: String
        let filename: String
        let fileType: Multipart.FileUpload.FileType
        let data: Foundation.Data
        let maxSize: Int

        public init(
            fieldName: String = "file",
            filename: String,
            fileType: Multipart.FileUpload.FileType,
            data: Foundation.Data,
            maxSize: Int = Multipart.FileUpload.maxFileSize
        ) {
            self.fieldName = fieldName
            self.filename = filename
            self.fileType = fileType
            self.data = data
            self.maxSize = maxSize
        }
    }
}

extension Multipart.FileUpload.Data {
    public static func csv(
        named fieldName: String = "file",
        filename: String = "file.csv",
        data: Data,
        maxSize: Int = Multipart.FileUpload.maxFileSize
    ) -> Self {
        .init(
            fieldName: fieldName,
            filename: filename,
            fileType: .csv,
            data: data,
            maxSize: maxSize
        )
    }

    public static func pdf(
        named fieldName: String = "file",
        filename: String = "file.pdf",
        data: Data,
        maxSize: Int = Multipart.FileUpload.maxFileSize
    ) -> Self {
        .init(
            fieldName: fieldName,
            filename: filename,
            fileType: .pdf,
            data: data,
            maxSize: maxSize
        )
    }
}
