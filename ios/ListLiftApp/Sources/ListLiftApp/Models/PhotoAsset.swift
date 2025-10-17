import Foundation
import SwiftUI

struct PhotoAsset: Identifiable, Codable, Equatable {
    var id: UUID
    var originalURL: URL?
    var cleanedURL: URL?
    var thumbnailData: Data?
    var metadata: PhotoMetadata

    init(id: UUID = UUID(), originalURL: URL? = nil, cleanedURL: URL? = nil, thumbnailData: Data? = nil, metadata: PhotoMetadata = PhotoMetadata()) {
        self.id = id
        self.originalURL = originalURL
        self.cleanedURL = cleanedURL
        self.thumbnailData = thumbnailData
        self.metadata = metadata
    }
}

struct PhotoMetadata: Codable, Equatable {
    var captureDate: Date?
    var iso: Double?
    var shutterSpeed: Double?
    var exposureBias: Double?
    var backgroundConfidence: Double

    init(captureDate: Date? = nil, iso: Double? = nil, shutterSpeed: Double? = nil, exposureBias: Double? = nil, backgroundConfidence: Double = 0) {
        self.captureDate = captureDate
        self.iso = iso
        self.shutterSpeed = shutterSpeed
        self.exposureBias = exposureBias
        self.backgroundConfidence = backgroundConfidence
    }
}
