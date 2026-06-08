import SwiftUI
import UIKit

struct ResultView: View {
    @Binding var imageData: Data?

    private let detector = ObjectDetectorUtils()
    
    // Configurable target string
    @State private var targetLabel: String = "bowl"
    @State private var croppedImage: UIImage? = nil
    @State private var errorMessage: String? = nil
    
    // Keep track of the matched raw object data to draw the box overlay
    @State private var matchedObject: DetectedObject? = nil

    var body: some View {
        VStack {
            Spacer()
            
            if let originalData = imageData, let originalUiImage = UIImage(data: originalData), let croppedUiImage = croppedImage {
                
                // Side-by-side comparison layout
                HStack(spacing: 16) {
                    
                    // LEFT: Original image with the bounding box overlayed
                    VStack {
                        Text("Original Box")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        GeometryReader { geo in
                            ZStack(alignment: .topLeading) {
                                Image(uiImage: originalUiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .clipped()
                                
                                // Draw the box overlay over the original image if available
                                if let obj = matchedObject {
                                    let rect = convertBoundingBox(obj.boundingBox, in: geo.size)
                                    
                                    Rectangle()
                                        .stroke(Color.yellow, lineWidth: 2)
                                        .background(Color.yellow.opacity(0.15))
                                        .frame(width: rect.width, height: rect.height)
                                        .position(x: rect.midX, y: rect.midY)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: 250) // Restrict size safely inside the HStack
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // RIGHT: The clean cropped result image
                    VStack {
                        Text("Padded Crop")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Image(uiImage: croppedUiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 250)
                            .frame(maxWidth: .infinity, maxHeight: .infinity) // Fill height alignment
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                Text("Isolated '\(targetLabel)'")
                    .font(.headline)
                    .padding(.top, 24)
                    
            } else if let error = errorMessage {
                // Graceful fallback UI if the target object isn't found
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text(error)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
            } else {
                ProgressView("Analyzing framework...")
            }
            
            Spacer()
        }
        .navigationTitle("Comparison View")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setupDetectorPipeline()
        }
    }

    // MARK: - Core Graphics Pixel Cropping Pipeline
    
    private func setupDetectorPipeline() {
        _ = detector.setUpVision()
        
        detector.onDetections = { objects in
            // Find the first matching object tag
            guard let matched = objects.first(where: { $0.label.lowercased() == targetLabel.lowercased() }) else {
                self.errorMessage = "Could not find a '\(targetLabel)' in this picture."
                return
            }
            
            // Save metadata state for the UI box overlay loop
            self.matchedObject = matched
            
            // Extract and slice the original asset directly
            if let data = imageData, let originalUiImage = UIImage(data: data) {
                if let cropped = cropTargetObject(from: originalUiImage, boundingBox: matched.boundingBox) {
                    self.croppedImage = cropped
                } else {
                    self.errorMessage = "Error slicing the image composition."
                }
            }
        }

        // Trigger object detection on data initialization
        if let data = imageData {
            detector.detectObjects(imageData: data)
        }
    }

    private func cropTargetObject(from image: UIImage, boundingBox: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        
        // 1. Apply padding to the normalized Vision bounding box first
        let paddingFactor: CGFloat = 0.15
        let padX = boundingBox.width * paddingFactor
        let padY = boundingBox.height * paddingFactor
        
        let paddedBox = CGRect(
            x: boundingBox.origin.x - padX,
            y: boundingBox.origin.y - padY,
            width: boundingBox.width + (padX * 2),
            height: boundingBox.height + (padY * 2)
        )
        
        // 2. Adjust normalized coordinates based on the raw CGImage orientation
        // This translates Vision coordinates (always bottom-left) to match the internal sensor orientation
        var normalizedCropRect = CGRect.zero
        
        switch image.imageOrientation {
        case .left:
            normalizedCropRect = CGRect(
                x: paddedBox.origin.y,
                y: paddedBox.origin.x,
                width: paddedBox.height,
                height: paddedBox.width
            )
        case .right:
            normalizedCropRect = CGRect(
                x: 1.0 - paddedBox.origin.y - paddedBox.height,
                y: 1.0 - paddedBox.origin.x - paddedBox.width,
                width: paddedBox.height,
                height: paddedBox.width
            )
        case .down:
            normalizedCropRect = CGRect(
                x: 1.0 - paddedBox.origin.x - paddedBox.width,
                y: paddedBox.origin.y,
                width: paddedBox.width,
                height: paddedBox.height
            )
        case .up: // Standard portrait/matching setup
            normalizedCropRect = CGRect(
                x: paddedBox.origin.x,
                y: 1.0 - paddedBox.origin.y - paddedBox.height,
                width: paddedBox.width,
                height: paddedBox.height
            )
        @unknown default:
            normalizedCropRect = CGRect(
                x: paddedBox.origin.x,
                y: 1.0 - paddedBox.origin.y - paddedBox.height,
                width: paddedBox.width,
                height: paddedBox.height
            )
        }
        
        // 3. Denormalize coordinates to raw pixel scale
        let rawCropRect = CGRect(
            x: normalizedCropRect.origin.x * width,
            y: normalizedCropRect.origin.y * height,
            width: normalizedCropRect.size.width * width,
            height: normalizedCropRect.size.height * height
        )
        
        // 4. Safety First: Clamp to actual pixel bounds
        let imageRect = CGRect(x: 0, y: 0, width: width, height: height)
        let safeCropRect = rawCropRect.intersection(imageRect)
        
        guard !safeCropRect.isNull && safeCropRect.width > 0 && safeCropRect.height > 0 else { return nil }
        
        // 5. Crop the raw image pixels and package it back with its original metadata orientation
        guard let croppedCgImage = cgImage.cropping(to: safeCropRect) else { return nil }
        
        return UIImage(cgImage: croppedCgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    // MARK: - Screen Bounding Box Converter
    private func convertBoundingBox(_ boundingBox: CGRect, in size: CGSize) -> CGRect {
        let w = boundingBox.width * size.width
        let h = boundingBox.height * size.height
        let x = boundingBox.minX * size.width
        let y = (1 - boundingBox.minY - boundingBox.height) * size.height
        return CGRect(x: x, y: y, width: w, height: h)
    }
}
