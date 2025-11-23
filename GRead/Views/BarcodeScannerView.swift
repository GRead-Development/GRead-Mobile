import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    @Binding var isPresented: Bool
    @Binding var scannedCode: String
    let onCodeScanned: (String) -> Void

    @Environment(\.themeColors) var themeColors
    @State private var showManualEntry = false
    @State private var cameraPermissionDenied = false

    var body: some View {
        NavigationView {
            ZStack {
                if cameraPermissionDenied {
                    VStack(spacing: 20) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(themeColors.textSecondary)

                        Text("Camera Access Required")
                            .font(.headline)
                            .foregroundColor(themeColors.textPrimary)

                        Text("Please enable camera access in Settings to scan barcodes")
                            .font(.subheadline)
                            .foregroundColor(themeColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: {
                            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsURL)
                            }
                        }) {
                            Text("Open Settings")
                                .padding()
                                .background(themeColors.primary)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }

                        Button(action: {
                            showManualEntry = true
                        }) {
                            Text("Enter ISBN Manually")
                                .padding()
                                .foregroundColor(themeColors.primary)
                        }
                    }
                } else {
                    BarcodeScannerRepresentable(
                        scannedCode: $scannedCode,
                        onCodeScanned: { code in
                            onCodeScanned(code)
                            isPresented = false
                        },
                        onPermissionDenied: {
                            cameraPermissionDenied = true
                        }
                    )

                    VStack {
                        Spacer()

                        VStack(spacing: 16) {
                            Text("Position the barcode within the frame")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(8)

                            Button(action: {
                                showManualEntry = true
                            }) {
                                HStack {
                                    Image(systemName: "keyboard")
                                    Text("Enter Manually")
                                }
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .foregroundColor(themeColors.primary)
                                .cornerRadius(8)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $showManualEntry) {
                ManualISBNEntryView(
                    isPresented: $showManualEntry,
                    onISBNEntered: { isbn in
                        onCodeScanned(isbn)
                        isPresented = false
                    }
                )
            }
        }
    }
}

// MARK: - Barcode Scanner UIKit Bridge
struct BarcodeScannerRepresentable: UIViewControllerRepresentable {
    @Binding var scannedCode: String
    let onCodeScanned: (String) -> Void
    let onPermissionDenied: () -> Void

    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let controller = BarcodeScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, BarcodeScannerDelegate {
        let parent: BarcodeScannerRepresentable

        init(_ parent: BarcodeScannerRepresentable) {
            self.parent = parent
        }

        func barcodeScanner(_ scanner: BarcodeScannerViewController, didScanBarcode code: String) {
            parent.scannedCode = code
            parent.onCodeScanned(code)
        }

        func barcodeScannerDidFailWithPermission(_ scanner: BarcodeScannerViewController) {
            parent.onPermissionDenied()
        }
    }
}

// MARK: - Barcode Scanner Delegate Protocol
protocol BarcodeScannerDelegate: AnyObject {
    func barcodeScanner(_ scanner: BarcodeScannerViewController, didScanBarcode code: String)
    func barcodeScannerDidFailWithPermission(_ scanner: BarcodeScannerViewController)
}

// MARK: - Barcode Scanner View Controller
class BarcodeScannerViewController: UIViewController {
    weak var delegate: BarcodeScannerDelegate?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasScanned = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hasScanned = false
        startScanning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }

    private func setupCamera() {
        // Request camera permission
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCaptureSession()
                    } else {
                        self?.delegate?.barcodeScannerDidFailWithPermission(self!)
                    }
                }
            }
        case .denied, .restricted:
            delegate?.barcodeScannerDidFailWithPermission(self)
        @unknown default:
            delegate?.barcodeScannerDidFailWithPermission(self)
        }
    }

    private func setupCaptureSession() {
        captureSession = AVCaptureSession()

        guard let captureSession = captureSession else { return }
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }

        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print("Error creating video input: \(error)")
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            print("Could not add video input")
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)

            // Support various barcode formats commonly used for books (EAN-13 for ISBN)
            metadataOutput.metadataObjectTypes = [
                .ean8,
                .ean13,
                .upce,
                .code128,
                .code39,
                .code93,
                .interleaved2of5,
                .itf14
            ]
        } else {
            print("Could not add metadata output")
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.frame = view.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill

        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
        }

        // Add a targeting box overlay
        addTargetingBox()
    }

    private func addTargetingBox() {
        let boxWidth: CGFloat = 280
        let boxHeight: CGFloat = 140

        let boxFrame = CGRect(
            x: (view.bounds.width - boxWidth) / 2,
            y: (view.bounds.height - boxHeight) / 2,
            width: boxWidth,
            height: boxHeight
        )

        let boxLayer = CAShapeLayer()
        boxLayer.frame = boxFrame
        boxLayer.borderColor = UIColor.white.cgColor
        boxLayer.borderWidth = 2
        boxLayer.cornerRadius = 8
        view.layer.addSublayer(boxLayer)

        // Add corner markers
        let cornerLength: CGFloat = 20
        let cornerWidth: CGFloat = 3

        let corners: [(CGPoint, CGPoint)] = [
            // Top-left
            (CGPoint(x: boxFrame.minX, y: boxFrame.minY), CGPoint(x: boxFrame.minX + cornerLength, y: boxFrame.minY)),
            (CGPoint(x: boxFrame.minX, y: boxFrame.minY), CGPoint(x: boxFrame.minX, y: boxFrame.minY + cornerLength)),
            // Top-right
            (CGPoint(x: boxFrame.maxX, y: boxFrame.minY), CGPoint(x: boxFrame.maxX - cornerLength, y: boxFrame.minY)),
            (CGPoint(x: boxFrame.maxX, y: boxFrame.minY), CGPoint(x: boxFrame.maxX, y: boxFrame.minY + cornerLength)),
            // Bottom-left
            (CGPoint(x: boxFrame.minX, y: boxFrame.maxY), CGPoint(x: boxFrame.minX + cornerLength, y: boxFrame.maxY)),
            (CGPoint(x: boxFrame.minX, y: boxFrame.maxY), CGPoint(x: boxFrame.minX, y: boxFrame.maxY - cornerLength)),
            // Bottom-right
            (CGPoint(x: boxFrame.maxX, y: boxFrame.maxY), CGPoint(x: boxFrame.maxX - cornerLength, y: boxFrame.maxY)),
            (CGPoint(x: boxFrame.maxX, y: boxFrame.maxY), CGPoint(x: boxFrame.maxX, y: boxFrame.maxY - cornerLength))
        ]

        for (start, end) in corners {
            let cornerPath = UIBezierPath()
            cornerPath.move(to: start)
            cornerPath.addLine(to: end)

            let cornerLayer = CAShapeLayer()
            cornerLayer.path = cornerPath.cgPath
            cornerLayer.strokeColor = UIColor.systemGreen.cgColor
            cornerLayer.lineWidth = cornerWidth
            cornerLayer.lineCap = .round
            view.layer.addSublayer(cornerLayer)
        }
    }

    private func startScanning() {
        guard let captureSession = captureSession, !captureSession.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
    }

    private func stopScanning() {
        guard let captureSession = captureSession, captureSession.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.stopRunning()
        }
    }
}

// MARK: - Metadata Output Delegate
extension BarcodeScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !hasScanned else { return }

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }

            hasScanned = true
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

            delegate?.barcodeScanner(self, didScanBarcode: stringValue)
        }
    }
}

// MARK: - Manual ISBN Entry View
struct ManualISBNEntryView: View {
    @Binding var isPresented: Bool
    let onISBNEntered: (String) -> Void

    @State private var isbnInput = ""
    @Environment(\.themeColors) var themeColors

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter ISBN manually")
                        .font(.headline)

                    Text("ISBN is usually found on the back cover near the barcode")
                        .font(.caption)
                        .foregroundColor(themeColors.textSecondary)
                }
                .padding(.horizontal)

                TextField("Enter ISBN...", text: $isbnInput)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numbersAndPunctuation)
                    .autocapitalization(.none)
                    .padding(.horizontal)

                Button(action: {
                    let cleanISBN = isbnInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !cleanISBN.isEmpty {
                        onISBNEntered(cleanISBN)
                    }
                }) {
                    Text("Search")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isbnInput.isEmpty ? themeColors.textSecondary : themeColors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(isbnInput.isEmpty)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.vertical)
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
