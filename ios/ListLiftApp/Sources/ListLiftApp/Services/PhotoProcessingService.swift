import Foundation
import PhotosUI
import CoreImage
import Vision
import UIKit

actor PhotoProcessingService {
    private let context = CIContext()

    func removeBackground(from imageData: Data) async throws -> (Data, Double) {
        let request = try await segmentationRequest(for: imageData)
        guard let observation = request.results?.first else {
            throw PhotoProcessingError.maskFailed
        }

        guard let ciImage = CIImage(data: imageData) else {
            throw PhotoProcessingError.maskFailed
        }
        let maskImage = CIImage(cvPixelBuffer: observation.pixelBuffer)
        let background = CIImage(color: .init(red: 1, green: 1, blue: 1, alpha: 0)).cropped(to: ciImage.extent)

        guard let composite = CIFilter(name: "CIBlendWithMask", parameters: [
            kCIInputImageKey: ciImage,
            kCIInputBackgroundImageKey: background,
            kCIInputMaskImageKey: maskImage
        ])?.outputImage else {
            throw PhotoProcessingError.compositeFailed
        }

        let cleanedData = try render(image: composite)
        return (cleanedData, 0.9)
    }

    func autoEnhance(imageData: Data) async throws -> Data {
        guard let ciImage = CIImage(data: imageData) else { throw PhotoProcessingError.renderFailed }
        let filters = ciImage.autoAdjustmentFilters()
        let output = filters.reduce(ciImage) { current, filter in
            filter.setValue(current, forKey: kCIInputImageKey)
            return filter.outputImage ?? current
        }
        return try render(image: output)
    }

    func autoCropToSquare(imageData: Data) async throws -> Data {
        guard let ciImage = CIImage(data: imageData) else { throw PhotoProcessingError.renderFailed }
        let extent = ciImage.extent
        let length = min(extent.width, extent.height)
        let squareRect = CGRect(
            x: extent.midX - length / 2,
            y: extent.midY - length / 2,
            width: length,
            height: length
        )
        let cropped = ciImage.cropped(to: squareRect)
        return try render(image: cropped)
    }

    private func segmentationRequest(for data: Data) async throws -> VNGenerateForegroundInstanceMaskRequest {
        let request = VNGenerateForegroundInstanceMaskRequest()
        request.qualityLevel = .balanced
        let handler = VNImageRequestHandler(data: data, options: [:])
        try handler.perform([request])
        return request
    }

    private func render(image: CIImage) throws -> Data {
        guard let cgImage = context.createCGImage(image, from: image.extent) else {
            throw PhotoProcessingError.renderFailed
        }
        let uiImage = UIImage(cgImage: cgImage)
        guard let data = uiImage.jpegData(compressionQuality: 0.9) else {
            throw PhotoProcessingError.renderFailed
        }
        return data
    }

    enum PhotoProcessingError: Error {
        case maskFailed
        case compositeFailed
        case renderFailed
    }
}
