import SwiftUI
import AVFoundation

struct ScannerView: View {
    @State private var isScanning = false
    @State private var isLoading = false
    @State private var cameraReady = false
    @State private var scanResult: ScanResult?
    @State private var showResult = false
    @State private var showPermissionAlert = false
    @State private var errorMessage: String?
    @State private var pulseAnimation = false
    @State private var rotationAngle = 0.0
    @State private var captureTrigger = 0
    @State private var cameraPermissionStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var scanPhase: Int = 0
    @State private var stepVisible: [Bool] = [false, false, false, false]

    private let cameraDelegate = ScannerCameraDelegate()

    var body: some View {
        ZStack {
            Color(hex: "#1A0F0A")
                .ignoresSafeArea()

            // Full screen camera or placeholder
            cameraOrPlaceholderView

            // Dark overlay with circular cutout
            if !isLoading {
                scannerOverlay
            }

            // Loading overlay
            if isLoading {
                loadingOverlay
            }

            // Bottom controls
            if !isLoading {
                bottomControls
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            checkCameraPermission()
            startPulseAnimation()
        }
        .alert("Camera Access Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("PodScan needs camera access to identify your coffee pods. Please enable it in Settings.")
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        }
        .sheet(isPresented: $showResult) {
            if let result = scanResult {
                ScanResultView(result: result, onRetry: {
                    showResult = false
                })
            }
        }
    }

    // MARK: - Camera or Placeholder

    @ViewBuilder
    private var cameraOrPlaceholderView: some View {
        if cameraPermissionStatus == .authorized {
            CameraContainerView(
                isReady: $cameraReady,
                captureTrigger: $captureTrigger,
                cameraDelegate: cameraDelegate
            )
            .ignoresSafeArea()
        } else {
            ZStack {
                Color(hex: "#1A0F0A")
                    .ignoresSafeArea()
                VStack(spacing: 20) {
                    Image(systemName: "camera.slash")
                        .font(.system(size: 60))
                        .foregroundColor(Color(hex: "#B0A090"))

                    Text("Camera not available")
                        .foregroundColor(Color(hex: "#B0A090"))
                        .font(.headline)

                    Text(cameraPermissionStatus == .notDetermined
                         ? "Camera access is needed to scan pods."
                         : "Camera access was denied. Enable it to scan pods.")
                        .foregroundColor(Color(hex: "#B0A090").opacity(0.7))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Button(action: requestOrOpenCameraPermission) {
                        HStack(spacing: 8) {
                            Image(systemName: cameraPermissionStatus == .notDetermined ? "camera" : "gear")
                            Text(cameraPermissionStatus == .notDetermined ? "Enable Camera" : "Open Settings")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "#1A0F0A"))
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#C8860A"))
                        .cornerRadius(24)
                    }
                    .padding(.top, 8)
                }
            }
        }
    }

    // MARK: - Scanner Overlay

    private var scannerOverlay: some View {
        GeometryReader { geo in
            let isIPad = UIDevice.current.userInterfaceIdiom == .pad
            let rawSize = min(geo.size.width, geo.size.height) * 0.72
            let circleSize: CGFloat = isIPad ? min(rawSize, 380) : rawSize
            let circleX = geo.size.width / 2
            let circleY = isIPad ? geo.size.height * 0.38 : geo.size.height * 0.42

            ZStack {
                // Dark overlay
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .mask(
                        Rectangle()
                            .overlay(
                                Circle()
                                    .frame(width: circleSize, height: circleSize)
                                    .position(x: circleX, y: circleY)
                                    .blendMode(.destinationOut)
                            )
                    )

                // Pulsing ring
                Circle()
                    .stroke(
                        Color(hex: "#C8860A").opacity(pulseAnimation ? 0.3 : 0.8),
                        lineWidth: pulseAnimation ? 1 : 3
                    )
                    .frame(
                        width: pulseAnimation ? circleSize + 30 : circleSize + 4,
                        height: pulseAnimation ? circleSize + 30 : circleSize + 4
                    )
                    .position(x: circleX, y: circleY)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )

                // Inner border ring
                Circle()
                    .stroke(Color(hex: "#C8860A"), lineWidth: 2)
                    .frame(width: circleSize, height: circleSize)
                    .position(x: circleX, y: circleY)

                // Corner accent marks
                scannerCornerMarks(circleSize: circleSize, center: CGPoint(x: circleX, y: circleY))

                // (instruction text moved to bottomControls to avoid overlap)
            }
        }
    }

    @ViewBuilder
    private func scannerCornerMarks(circleSize: CGFloat, center: CGPoint) -> some View {
        ForEach([0, 90, 180, 270], id: \.self) { angle in
            cornerMark()
                .rotationEffect(.degrees(Double(angle)))
                .position(
                    x: center.x + (circleSize / 2) * cos(Double(angle - 45) * .pi / 180),
                    y: center.y + (circleSize / 2) * sin(Double(angle - 45) * .pi / 180)
                )
        }
    }

    private func cornerMark() -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 20))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 20, y: 0))
        }
        .stroke(Color(hex: "#C8860A"), lineWidth: 3)
        .frame(width: 20, height: 20)
    }

    // MARK: - Loading Overlay

    private let scanSteps: [(icon: String, label: String, detail: String)] = [
        ("camera.shutter.button.fill", "Capturing image",       "Processing your photo"),
        ("cpu",                        "Analyzing with AI",      "GPT-4 Vision identifying your pod"),
        ("magnifyingglass",            "Searching pod database", "Matching against known pods"),
        ("sparkles",                   "Reviewing results",      "Preparing your scan result"),
    ]

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.92)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Spinning coffee icon
                ZStack {
                    Circle()
                        .stroke(Color(hex: "#C8860A").opacity(0.2), lineWidth: 2)
                        .frame(width: 64, height: 64)
                    Circle()
                        .trim(from: 0, to: 0.65)
                        .stroke(
                            Color(hex: "#C8860A"),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(rotationAngle))
                        .animation(.linear(duration: 0.9).repeatForever(autoreverses: false), value: rotationAngle)
                    Text("☕").font(.system(size: 26))
                }

                // Step list
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(0..<scanSteps.count, id: \.self) { i in
                        let step = scanSteps[i]
                        let isDone    = i < scanPhase
                        let isActive  = i == scanPhase
                        let isPending = i > scanPhase

                        HStack(spacing: 14) {
                            // Step icon / checkmark
                            ZStack {
                                Circle()
                                    .fill(isDone
                                          ? Color(hex: "#C8860A")
                                          : isActive
                                            ? Color(hex: "#C8860A").opacity(0.15)
                                            : Color.white.opacity(0.05))
                                    .frame(width: 36, height: 36)

                                if isDone {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: step.icon)
                                        .font(.system(size: 15))
                                        .foregroundColor(
                                            isActive ? Color(hex: "#C8860A") : Color.white.opacity(0.25)
                                        )
                                }
                            }
                            .scaleEffect(isActive ? 1.1 : 1.0)
                            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: scanPhase)

                            // Labels
                            VStack(alignment: .leading, spacing: 2) {
                                Text(step.label)
                                    .font(.system(size: 15, weight: isActive ? .semibold : .regular))
                                    .foregroundColor(
                                        isDone ? Color(hex: "#C8860A")
                                        : isActive ? .white
                                        : Color.white.opacity(0.3)
                                    )

                                if isActive {
                                    Text(step.detail)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "#B0A090"))
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .animation(.easeInOut(duration: 0.3), value: scanPhase)

                            Spacer()

                            // Active pulse dot
                            if isActive {
                                Circle()
                                    .fill(Color(hex: "#C8860A"))
                                    .frame(width: 7, height: 7)
                                    .opacity(pulseAnimation ? 0.2 : 1.0)
                                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: pulseAnimation)
                            }
                        }
                        .opacity(stepVisible[i] ? 1 : 0)
                        .offset(x: stepVisible[i] ? 0 : -20)
                        .animation(.spring(response: 0.4, dampingFraction: 0.75).delay(Double(i) * 0.12), value: stepVisible[i])
                    }
                }
                .padding(.horizontal, 32)
            }
        }
        .onAppear {
            rotationAngle = 360
            // Stagger steps sliding in
            for i in 0..<scanSteps.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.12) {
                    withAnimation { stepVisible[i] = true }
                }
            }
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack {
            Spacer()

            VStack(spacing: 20) {
                // Instruction text (kept here, above button, to prevent overlap with overlay)
                VStack(spacing: 6) {
                    Text("Point at any coffee pod")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    Text("Tap the button to scan")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#B0A090"))
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(Color.red.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Capture button
                Button(action: takePicture) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 72, height: 72)

                        Circle()
                            .stroke(Color(hex: "#C8860A"), lineWidth: 3)
                            .frame(width: 84, height: 84)

                        Image(systemName: "camera.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(hex: "#1A0F0A"))
                    }
                }
                .disabled(isLoading || !cameraReady)
                .opacity((isLoading || !cameraReady) ? 0.5 : 1.0)

                Text(cameraReady ? "Scan Pod" : "Initializing camera...")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#B0A090"))
            }
            .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 72 : 48)
        }
        .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 600 : .infinity)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        cameraPermissionStatus = status
        switch status {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
                    if !granted { self.showPermissionAlert = true }
                }
            }
        case .denied, .restricted:
            // Don't auto-show alert — placeholder now has a button
            break
        @unknown default:
            break
        }
    }

    private func requestOrOpenCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
                }
            }
        case .denied, .restricted:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        default:
            break
        }
    }

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
    }

    private func takePicture() {
        errorMessage = nil
        cameraDelegate.onPhotoCapture = { imageData in
            DispatchQueue.main.async {
                scanPhase = 0
                stepVisible = [false, false, false, false]
                isLoading = true
            }
            Task {
                await identifyPod(imageData: imageData)
            }
        }
        cameraDelegate.onError = { error in
            DispatchQueue.main.async {
                errorMessage = error.localizedDescription
            }
        }
        captureTrigger += 1
    }

    private func advancePhase(to phase: Int) {
        withAnimation(.easeInOut(duration: 0.35)) {
            scanPhase = phase
        }
    }

    private func identifyPod(imageData: Data) async {
        do {
            // Step 0: Capturing (already shown) → Step 1: Analyzing
            await MainActor.run { advancePhase(to: 1) }

            let result = try await OpenAIService.shared.identifyPod(imageData: imageData)

            // Step 2: Searching database
            await MainActor.run { advancePhase(to: 2) }
            try? await Task.sleep(nanoseconds: 400_000_000) // brief pause so user sees the step

            let db = PodDatabase.shared
            var matchedPod: Pod?
            if let podName = result.podName {
                matchedPod = db.allPods().first {
                    $0.name.lowercased() == podName.lowercased()
                }
                if matchedPod == nil {
                    matchedPod = db.allPods().first {
                        $0.name.lowercased().contains(podName.lowercased()) ||
                        podName.lowercased().contains($0.name.lowercased())
                    }
                }
            }

            // Step 3: Reviewing results
            await MainActor.run { advancePhase(to: 3) }
            try? await Task.sleep(nanoseconds: 500_000_000) // brief pause so user sees the final step

            await MainActor.run {
                isLoading = false
                scanResult = ScanResult(
                    identificationResult: result,
                    matchedPod: matchedPod,
                    imageData: imageData
                )
                showResult = true
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Scan Result Model

struct ScanResult {
    let identificationResult: PodIdentificationResult
    let matchedPod: Pod?
    let imageData: Data
}

// MARK: - Camera Container View (bridges coordinator)

struct CameraContainerView: UIViewRepresentable {
    @Binding var isReady: Bool
    @Binding var captureTrigger: Int
    let cameraDelegate: ScannerCameraDelegate

    func makeCoordinator() -> CameraView.Coordinator {
        let cameraView = CameraView(delegate: cameraDelegate, isReady: $isReady, captureTrigger: $captureTrigger)
        return CameraView.Coordinator(cameraView)
    }

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.coordinator = context.coordinator
        context.coordinator.previewView = view
        context.coordinator.setupCamera()
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        context.coordinator.parent = CameraView(
            delegate: cameraDelegate,
            isReady: $isReady,
            captureTrigger: $captureTrigger
        )
        context.coordinator.capturePhotoIfNeeded(captureTrigger)
    }
}

// MARK: - Scanner Camera Delegate

class ScannerCameraDelegate: CameraViewDelegate {
    var onPhotoCapture: ((Data) -> Void)?
    var onError: ((Error) -> Void)?

    func didCapturePhoto(_ imageData: Data) {
        onPhotoCapture?(imageData)
    }

    func didFailWithError(_ error: Error) {
        onError?(error)
    }
}
