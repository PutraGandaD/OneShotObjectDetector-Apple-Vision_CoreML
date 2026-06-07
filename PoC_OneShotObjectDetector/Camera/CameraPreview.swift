/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Provides the capture preview.
 
 Most of the code in this file taken from Apple Developer Documentation here (with some modification bymyself) =
 https://developer.apple.com/documentation/vision/locating-and-displaying-recognized-text
*/

import AVFoundation
import SwiftUI

struct CameraPreview: UIViewRepresentable {
    @Binding var camera: Camera

    func makeUIView(context: Context) -> some UIView {
        let view = PreviewView()

        view.videoPreviewLayer.session = camera.session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill

        return view
    }

    /// No implementation needed.
    func updateUIView(_ uiView: UIViewType, context: Context) { }
}

class PreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as? AVCaptureVideoPreviewLayer ?? AVCaptureVideoPreviewLayer()
    }
    
    // Automatically called when the device rotates and the view is resized
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Ensure we have a valid connection and it supports orientation
        guard let connection = videoPreviewLayer.connection,
              connection.isVideoOrientationSupported else { return }
        
        // Get the current window scene's orientation (iOS 13+)
        if let windowScene = self.window?.windowScene {
            connection.videoOrientation = videoOrientation(from: windowScene.interfaceOrientation)
        }
    }
    
    // Helper to map UIInterfaceOrientation to AVCaptureVideoOrientation
    private func videoOrientation(from interfaceOrientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        switch interfaceOrientation {
        case .portrait: return .portrait
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        case .portraitUpsideDown: return .portraitUpsideDown
        default: return .portrait
        }
    }
}
