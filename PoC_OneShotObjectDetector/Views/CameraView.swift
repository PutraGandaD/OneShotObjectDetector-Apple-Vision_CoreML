import SwiftUI

struct CameraView: View {
    @State var camera = Camera()
    @State var didSetupCamera = Bool()
    
    @Binding var imageData: Data?
    @Binding var hasPhoto: Bool
    @Binding var showCamera: Bool
    @Binding var showAccessError: Bool
    
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        ZStack(alignment: .bottom) {
            CameraPreview(camera: $camera)
                .task {
                    if await camera.checkCameraAuthorization() {
                        didSetupCamera = camera.setup()
                    } else {
                        showAccessError = true
                        showCamera = false
                    }
                    
                    if !didSetupCamera {
                        print("Camera setup failed.")
                        showCamera = false
                    }
                }
                .ignoresSafeArea()
            
            cameraControls
        }
        .onChange(of: camera.hasPhoto) { _, newValue in
            if newValue {
                imageData = camera.photoData
                hasPhoto = true
                camera.resetSession()
            }
        }
    }
    
    @ViewBuilder var cameraControls: some View {
        Button {
            camera.capturePhoto()
        } label: {
            ZStack {
                Circle()
                    .stroke(.white, lineWidth: 2)
                    .frame(width: 70)

                Circle()
                    .fill(.white)
                    .frame(width: 60)
            }
        }
        .buttonStyle(CaptureButtonStyle())
    }
}

struct CaptureButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

