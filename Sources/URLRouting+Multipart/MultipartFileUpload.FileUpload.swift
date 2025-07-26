//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 29/12/2024.
//

import Foundation
import Parsing
import URLRouting

public struct FileUpload {
    let fieldName: String
    let filename: String
    let fileType: MultipartFileUpload.FileType
    let data: Data
    let maxSize: Int

    public init(
        fieldName: String = "file",
        filename: String,
        fileType: MultipartFileUpload.FileType,
        data: Data,
        maxSize: Int = MultipartFileUpload.maxFileSize
    ) {
        self.fieldName = fieldName
        self.filename = filename
        self.fileType = fileType
        self.data = data
        self.maxSize = maxSize
    }
}

extension FileUpload {
    public static func csv(
        named fieldName: String = "file",
        filename: String = "file.csv",
        data: Data,
        maxSize: Int = MultipartFileUpload.maxFileSize
    ) -> FileUpload {
        FileUpload(
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
        maxSize: Int = MultipartFileUpload.maxFileSize
    ) -> FileUpload {
        FileUpload(
            fieldName: fieldName,
            filename: filename,
            fileType: .pdf,
            data: data,
            maxSize: maxSize
        )
    }
}
