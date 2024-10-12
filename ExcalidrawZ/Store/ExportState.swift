//
//  AppStore.swift
//  ExcalidrawZ
//
//  Created by Dove Zachary on 2023/7/25.
//

import SwiftUI
import WebKit
import Combine
import os.log
import UniformTypeIdentifiers

import ChocofordUI

struct ExportedImageData {
    var name: String
    var data: Data
    var url: URL
}

final class ExportState: ObservableObject {
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ExportState")
    enum Status {
        case notRequested
        case loading
        case finish
    }
    
    var excalidrawWebCoordinator: ExcalidrawView.Coordinator?
    
    @Published var status: Status = .notRequested
    var download: WKDownload?
    var url: URL?
    
    enum ExportType {
        case image, file
    }
    func requestExport(type: ExportType) async throws {
        guard let excalidrawWebCoordinator else {
            struct WebCoordinatorNotReadyError: Error {}
            throw WebCoordinatorNotReadyError()
        }
        switch type {
            case .image:
                  try await excalidrawWebCoordinator.exportPNG()
            case .file:
                break
        }
    }
    
    func beginExport(url: URL, download: WKDownload) {
        self.logger.info("Begin export <url: \(url)>")
        self.status = .loading
        self.url = url
        self.download = download
    }
    
    func finishExport(download: WKDownload) {
        if download == self.download {
            self.logger.info("Finish export")
            self.status = .finish
        }
    }
    

    
    enum ImageType {
        case png
        case svg
    }
    
    func exportCurrentFileToImage(type: ImageType, embedScene: Bool) async throws -> ExportedImageData {
        guard let excalidrawWebCoordinator else {
            struct NoWebCoordinatorError: LocalizedError {
                var errorDescription: String? {
                    "Miss web coordinator"
                }
            }
            throw NoWebCoordinatorError()
        }
        guard let file = await self.excalidrawWebCoordinator?.parent?.file else {
            struct NoFileError: LocalizedError {
                var errorDescription: String? {
                    "Miss current file"
                }
            }
            throw NoFileError()
        }
        let imageData: Data
        let utType: UTType
        switch type {
            case .png:
                imageData = try await excalidrawWebCoordinator.exportElementsToPNGData(
                    elements: file.elements,
                    embedScene: embedScene
                )
                utType = embedScene ? .excalidrawPNG : .png
            case .svg:
                imageData = try await excalidrawWebCoordinator.exportElementsToSVGData(
                    elements: file.elements,
                    embedScene: embedScene
                )
                utType = embedScene ? .excalidrawSVG :.svg
        }
        
        let directory: URL = try getTempDirectory()
        let filename = await excalidrawWebCoordinator.parent?.file.name ?? "Untitled"
        let url = directory.appendingPathComponent(filename, conformingTo: utType)
        try imageData.write(to: url)
        
        return ExportedImageData(
            name: filename,
            data: imageData,
            url: url
        )
    }
}