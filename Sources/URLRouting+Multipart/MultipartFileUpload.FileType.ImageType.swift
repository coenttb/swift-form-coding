//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 29/12/2024.
//

import Foundation
import Parsing
import URLRouting

extension MultipartFileUpload.FileType.ImageType {
    nonisolated(unsafe)
    public static let jpeg = Self(
        contentType: "image/jpeg",
        fileExtension: "jpg"
    ) { data in
        let jpegMagicNumbers: [UInt8] = [0xFF, 0xD8, 0xFF]
        guard data.prefix(3).elementsEqual(jpegMagicNumbers) else {
            throw MultipartFileUpload.MultipartError.contentMismatch(
                expected: "image/jpeg",
                detected: nil
            )
        }
    }

    nonisolated(unsafe)
    public static let png = Self(
        contentType: "image/png",
        fileExtension: "png"
    ) { data in
        let pngMagicNumbers: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        guard data.prefix(8).elementsEqual(pngMagicNumbers) else {
            throw MultipartFileUpload.MultipartError.contentMismatch(
                expected: "image/png",
                detected: nil
            )
        }
    }

    nonisolated(unsafe)
    public static let gif = Self(
        contentType: "image/gif",
        fileExtension: "gif"
    ) { data in
        let gif87a = "GIF87a".data(using: .ascii)!
        let gif89a = "GIF89a".data(using: .ascii)!
        guard data.prefix(6).elementsEqual(gif87a) || data.prefix(6).elementsEqual(gif89a) else {
            throw MultipartFileUpload.MultipartError.contentMismatch(
                expected: "image/gif",
                detected: nil
            )
        }
    }

    nonisolated(unsafe)
    public static let webp = Self(
        contentType: "image/webp",
        fileExtension: "webp"
    ) { data in
        let riffMagic = "RIFF".data(using: .ascii)!
        let webpMagic = "WEBP".data(using: .ascii)!
        guard data.prefix(4).elementsEqual(riffMagic) &&
              data.dropFirst(8).prefix(4).elementsEqual(webpMagic) else {
            throw MultipartFileUpload.MultipartError.contentMismatch(
                expected: "image/webp",
                detected: nil
            )
        }
    }

    nonisolated(unsafe)
    public static let tiff = Self(
        contentType: "image/tiff",
        fileExtension: "tiff"
    ) { data in
        let intelMagic: [UInt8] = [0x49, 0x49, 0x2A, 0x00] // II*\0
        let motorolaMagic: [UInt8] = [0x4D, 0x4D, 0x00, 0x2A] // MM\0*
        guard data.prefix(4).elementsEqual(intelMagic) ||
              data.prefix(4).elementsEqual(motorolaMagic) else {
            throw MultipartFileUpload.MultipartError.contentMismatch(
                expected: "image/tiff",
                detected: nil
            )
        }
    }

    nonisolated(unsafe)
    public static let bmp = Self(
        contentType: "image/bmp",
        fileExtension: "bmp"
    ) { data in
        let bmpMagic: [UInt8] = [0x42, 0x4D]
        guard data.prefix(2).elementsEqual(bmpMagic) else {
            throw MultipartFileUpload.MultipartError.contentMismatch(
                expected: "image/bmp",
                detected: nil
            )
        }
    }

    nonisolated(unsafe)
    public static let heic = Self(
        contentType: "image/heic",
        fileExtension: "heic"
    ) { data in
        // HEIC validation is complex due to its container format
        // This is a basic check for the ftyp box with heic brand
        guard data.count >= 12,
              let ftyp = String(data: data.subdata(in: 4..<8), encoding: .ascii),
              ftyp == "ftyp",
              let brand = String(data: data.subdata(in: 8..<12), encoding: .ascii),
              brand == "heic" else {
            throw MultipartFileUpload.MultipartError.contentMismatch(
                expected: "image/heic",
                detected: nil
            )
        }
    }

    nonisolated(unsafe)
    public static let avif = Self(
        contentType: "image/avif",
        fileExtension: "avif"
    ) { data in
        // Similar to HEIC, AVIF uses a container format
        guard data.count >= 12,
              let ftyp = String(data: data.subdata(in: 4..<8), encoding: .ascii),
              ftyp == "ftyp",
              let brand = String(data: data.subdata(in: 8..<12), encoding: .ascii),
              brand == "avif" else {
            throw MultipartFileUpload.MultipartError.contentMismatch(
                expected: "image/avif",
                detected: nil
            )
        }
    }
}
