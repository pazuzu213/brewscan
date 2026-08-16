import SwiftUI
import AVFoundation

// MARK: - Camera Delegate Protocol
protocol CameraViewDelegate: AnyObject {
    func didCapturePhoto(_ imageData: Data)
    func didFailWithError(_ error: Error)
}

// MARK: - Camera View (UIViewRepresentable)
struct CameraView: UIViewRepresentable {
    weak var delegate: (any CameraViewDelegate)?
    @Binding var isReady: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.coordinator = context.coordinator
        context.coordinator.previewView = view
        context.coordinator.setupCamera()
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {}

    // MARK: - Capture Photo
    func capturePhoto(coordinator: Coordinator) {
        coordinator.capturePhoto()
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        var parent: CameraView
        var captureSession: AVCaptureSession?
        var photoOutput: AVCapturePhotoOutput?
        weak var previewView: CameraPreviewView?

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func setupCamera() {
            let session = AVCaptureSession()
            session.sessionPreset = .photo
            captureSession = session

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                return
            }

            if session.canAddInput(input) {
                session.addInput(input)
            }

            let output = AVCapturePhotoOutput()
            photoOutput = output

            if session.canAddOutput(output) {
                session.addOutput(output)
            }

            DispatchQueue.main.async {
                self.previewView?.configure(with: session)
            }

            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
                DispatchQueue.main.async {
                    self.parent.isReady = true
                }
            }
        }

        func capturePhoto() {
            guard let photoOutput = photoOutput else { return }
            let settings = AVCapturePhotoSettings()
            settings.flashMode = .auto
            photoOutput.capturePhoto(with: settings, delegate: self)
        }

        func photoOutput(_ output: AVCapturePhotoOutput,
                         didFinishProcessingPhoto photo: AVCapturePhoto,
                         error: Error?) {
            if let error = error {
                parent.delegate?.didFailWithError(error)
                return
            }

            guard let data = photo.fileDataRepresentation() else {
                parent.delegate?.didFailWithError(CameraError.noImageData)
                return
            }

            // Compress image for API call
            if let image = UIImage(data: data),
               let compressed = image.jpegData(compressionQuality: 0.7) {
                parent.delegate?.didCapturePhoto(compressed)
            } else {
                parent.delegate?.didCapturePhoto(data)
            }
        }
    }
}

// MARK: - Camera Preview UIView
class CameraPreviewView: UIView {
    var coordinator: CameraView.Coordinator?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    func configure(with session: AVCaptureSession) {
        videoPreviewLayer.session = session
        videoPreviewLayer.videoGravity = .resizeAspectFill
    }
}

// MARK: - Camera Error
enum CameraError: LocalizedError {
    case noImageData
    case cameraUnavailable
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .noImageData:
            return "Failed to capture image data."
        case .cameraUnavailable:
            return "Camera is not available on this device."
        case .permissionDenied:
            return "Camera access denied. Please enable in Settings."
        }
    }
}
