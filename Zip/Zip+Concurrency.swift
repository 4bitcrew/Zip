// ********************** Zip+Concurrency **********************
// * Copyright © 2025 Roy Marmelstein. All rights reserved.
// * Created on 8/16/25, for Zip
// * John Ayers <john@4bitcrew.com>
// * Unauthorized copying of this file is strictly prohibited
// ********************** Zip+Concurrency **********************


import Foundation

extension Zip {
    public enum ZipEvent: Sendable {
        case progress(Double)
        case finished
    }

    public enum UnzipEvent: Sendable {
        case progress(Double)
        case fileOutput(URL)
        case finished
    }


    @MainActor
    public static func unzipFileAsync(
        _ zipFileUrl: URL,
        destination: URL,
        overwrite: Bool,
        password: String? = nil,
        progressHandler: ((Double) -> Void)? = nil,
        fileOutputHandler: ((URL) -> Void)? = nil
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try Zip.unzipFile(
                        zipFileUrl,
                        destination: destination,
                        overwrite: overwrite,
                        password: password,
                        progress: { progress in
                            DispatchQueue.main.async {
                                progressHandler?(progress)
                            }
                        },
                        fileOutputHandler: { fileUrl in
                            DispatchQueue.main.async {
                                fileOutputHandler?(fileUrl)
                            }
                        }
                    )
                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    @MainActor
    public static func unzipFileStream(
        _ zipFileUrl: URL,
        destination: URL,
        overwrite: Bool,
        password: String? = nil
    ) -> AsyncThrowingStream<UnzipEvent, Error> {
        AsyncThrowingStream { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try Zip.unzipFile(
                        zipFileUrl,
                        destination: destination,
                        overwrite: overwrite,
                        password: password,
                        progress: { progress in
                            DispatchQueue.main.async {
                                continuation.yield(.progress(progress))
                            }
                        },
                        fileOutputHandler: { url in
                            continuation.yield(.fileOutput(url))
                        })
                    continuation.yield(.finished)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    @MainActor
    public static func zipFileAsync(
        _ urls: [URL],
        zipFilePath: URL,
        password: String? = nil,
        compression: ZipCompression = .DefaultCompression,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try Zip.zipFiles(
                        paths: urls,
                        zipFilePath: zipFilePath,
                        password: password,
                        compression: compression) { progress in
                            DispatchQueue.main.async {
                                progressHandler?(progress)
                            }
                        }
                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public static func zipFileStream(
        _ urls: [URL],
        zipFilePath: URL,
        password: String? = nil,
        compression: ZipCompression = .DefaultCompression
    ) -> AsyncThrowingStream<ZipEvent, Error> {
        return AsyncThrowingStream { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try Zip.zipFiles(paths: urls, zipFilePath: zipFilePath, password: password, compression: compression) { progress in
                        continuation.yield(.progress(progress))
                        continuation.yield(.finished)
                        continuation.finish()
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
