//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 29/12/2024.
//

import Foundation
import Parsing
import URLRouting

extension MultipartFileUpload.FileType {
    nonisolated(unsafe)
    public static let csv: Self = .init(
        contentType: "text/csv",
        fileExtension: "csv"
    ) { data in
        guard let _ = String(data: data, encoding: .utf8) else {
            throw MultipartFileUpload.MultipartError.contentMismatch(
                expected: "text/csv",
                detected: nil
            )
        }
    }

    nonisolated(unsafe)
    public static let pdf: Self = .init(
        contentType: "application/pdf",
        fileExtension: "pdf"
    ) { data in
        guard data.prefix(4).elementsEqual("%PDF".data(using: .utf8)!) else {
            throw MultipartFileUpload.MultipartError.contentMismatch(
                expected: "application/pdf",
                detected: nil
            )
        }
    }

    nonisolated(unsafe)
    public static let excel: Self = .init(
        contentType: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        fileExtension: "xlsx"
    )

    nonisolated(unsafe)
    public static let json: Self = .init(
        contentType: "application/json",
        fileExtension: "json"
    )

    nonisolated(unsafe)
    public static let text: Self = .init(
        contentType: "text/plain",
        fileExtension: "txt"
    )

    nonisolated
    public static func image(_ type: ImageType) -> MultipartFileUpload.FileType {
        MultipartFileUpload.FileType(
            contentType: type.contentType,
            fileExtension: type.fileExtension,
            validate: type.validate
        )
    }

    nonisolated(unsafe)
    public static let docx: Self = .init(
        contentType: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        fileExtension: "docx"
    )

    nonisolated(unsafe)
    public static let doc: Self = .init(
        contentType: "application/msword",
        fileExtension: "doc"
    )

    nonisolated(unsafe)
    public static let zip: Self = .init(
        contentType: "application/zip",
        fileExtension: "zip"
    )

    nonisolated(unsafe)
    public static let mp3: Self = .init(
        contentType: "audio/mpeg",
        fileExtension: "mp3"
    )

    nonisolated(unsafe)
    public static let wav: Self = .init(
        contentType: "audio/wav",
        fileExtension: "wav"
    )

    nonisolated(unsafe)
    public static let mp4: Self = .init(
        contentType: "video/mp4",
        fileExtension: "mp4"
    )

    nonisolated(unsafe)
    public static let sqlite: Self = .init(
        contentType: "application/x-sqlite3",
        fileExtension: "sqlite"
    )

    nonisolated(unsafe)
    public static let swift: Self = .init(
        contentType: "text/x-swift",
        fileExtension: "swift"
    )

    nonisolated(unsafe)
    public static let javascript: Self = .init(
        contentType: "application/javascript",
        fileExtension: "js"
    )

    nonisolated(unsafe)
    public static let ttf: Self = .init(
        contentType: "font/ttf",
        fileExtension: "ttf"
    )

    nonisolated(unsafe)
    public static let svg: Self = .init(
        contentType: "image/svg+xml",
        fileExtension: "svg"
    )
}
