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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        videoPreviewLayer.frame = self.bounds
        
        guard let connection = videoPreviewLayer.connection,
              connection.isVideoOrientationSupported else { return }
        
        switch UIDevice.current.orientation {
            // Home button on top
        case .portraitUpsideDown:
            print("portraitUpsideDown")
            connection.videoOrientation = .portraitUpsideDown
            
            // Home button on right
        case .landscapeLeft:
            print("landscapeLeft")
            connection.videoOrientation = .landscapeRight
            
            // Home button on left
        case .landscapeRight:
            print("landscapeRight")
            connection.videoOrientation = .landscapeLeft
              
      // Home button at bottom
        case .portrait:
            print("portrait")
            connection.videoOrientation = .portrait
      
        default:
            print("📸 DEBUG: Device orientation is unknown or flat (\(UIDevice.current.orientation.rawValue)). Keeping current video orientation.")
            break
        }
    }
}
