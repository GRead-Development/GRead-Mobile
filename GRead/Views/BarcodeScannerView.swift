import SwiftUI
import AVFoundation
import Vision

struct BarcodeScannerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.themeColors) var themeColors
    @EnvironmentObject var authManager: AuthManager

    @State private var scannedCode: String?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showBookDetails = false
    @State private var foundBook: Book?
    @State private var showImportSuccess = false

    var body: some View {
        NavigationView {
            ZStack {
                // Camera view
                BarcodeScannerCameraView(scannedCode: $scannedCode, isProcessing: $isProcessing)
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    Spacer()

                    // Scanning indicator
                    VStack(spacing: 16) {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            Text("Scanning...")
                                .font(.headline)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                            Text("Point camera at barcode")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding(.bottom, 100)

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                            .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                    }
                }
            }
            .onChange(of: scannedCode) { newValue in
                if let code = newValue, !isProcessing {
                    Logger.debug("Scanned code changed to: \(code), triggering lookup")
                    lookupBook(isbn: code)
                } else if newValue != nil && isProcessing {
                    Logger.debug("Barcode detected but already processing, ignoring")
                }
            }
            .sheet(isPresented: $showBookDetails) {
                if let book = foundBook {
                    BookDetailSheet(book: book, onAdd: {
                        addBookToLibrary(book)
                    })
                }
            }
            .alert("Book Added!", isPresented: $showImportSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("The book has been added to your library.")
            }
        }
    }

    private func lookupBook(isbn: String) {
        Logger.debug("Starting book lookup for ISBN: \(isbn)")
        isProcessing = true
        errorMessage = nil

        Task {
            do {
                // First, try to find the book in GRead database
                Logger.debug("Searching GRead database for ISBN: \(isbn)")
                let book = try await APIManager.shared.searchBookByISBN(isbn: isbn)

                Logger.debug("Book found in GRead database: \(book.title)")
                await MainActor.run {
                    foundBook = book
                    showBookDetails = true
                    isProcessing = false
                }
            } catch {
                Logger.debug("Book not found in GRead database, trying OpenLibrary API")
                // Book not found in database, try to import from external source
                do {
                    let importedBook = try await importBookFromISBN(isbn: isbn)

                    Logger.debug("Book imported from OpenLibrary: \(importedBook.title)")
                    await MainActor.run {
                        foundBook = importedBook
                        showBookDetails = true
                        isProcessing = false
                    }
                } catch {
                    Logger.error("Failed to find book anywhere for ISBN \(isbn): \(error.localizedDescription)")
                    await MainActor.run {
                        errorMessage = "Book not found. Try another barcode."
                        isProcessing = false
                        // Reset after 3 seconds to allow scanning again
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            errorMessage = nil
                            scannedCode = nil
                        }
                    }
                }
            }
        }
    }

    private func importBookFromISBN(isbn: String) async throws -> Book {
        // Try OpenLibrary API
        Logger.debug("Querying OpenLibrary API for ISBN: \(isbn)")
        guard let url = URL(string: "https://openlibrary.org/api/books?bibkeys=ISBN:\(isbn)&format=json&jscmd=data") else {
            Logger.error("Invalid URL for OpenLibrary API")
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        // Log the raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            Logger.debug("OpenLibrary API response: \(responseString)")
        }

        let response = try JSONDecoder().decode([String: OpenLibraryBook].self, from: data)

        guard let bookData = response["ISBN:\(isbn)"] else {
            Logger.warning("No results from OpenLibrary API for ISBN: \(isbn)")
            throw NSError(domain: "BookNotFound", code: 404, userInfo: nil)
        }

        Logger.debug("Found book on OpenLibrary: \(bookData.title), importing to GRead...")
        // Import the book to GRead database
        let importedBook = try await APIManager.shared.importBookFromOpenLibrary(openLibraryBookData: bookData)
        Logger.debug("Successfully imported book with ID: \(importedBook.id)")
        return importedBook
    }

    private func addBookToLibrary(_ book: Book) {
        Logger.debug("Adding book to library: \(book.title) (ID: \(book.id))")
        Task {
            do {
                try await APIManager.shared.addBookToLibrary(
                    bookId: book.id,
                    status: "reading",
                    currentPage: 0
                )

                Logger.debug("Book added to library successfully, refreshing cache")
                // Refresh library cache
                await LibraryManager.shared.loadLibrary()

                await MainActor.run {
                    Logger.debug("Showing success message")
                    showBookDetails = false
                    showImportSuccess = true
                }
            } catch {
                Logger.error("Failed to add book to library: \(error.localizedDescription)")
                await MainActor.run {
                    errorMessage = "Failed to add book to library"
                }
            }
        }
    }
}

// MARK: - Camera View

struct BarcodeScannerCameraView: UIViewRepresentable {
    @Binding var scannedCode: String?
    @Binding var isProcessing: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        let captureSession = AVCaptureSession()
        context.coordinator.captureSession = captureSession

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return view
        }

        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return view
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return view
        }

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(context.coordinator, queue: DispatchQueue(label: "videoQueue"))

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            return view
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer

        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = context.coordinator.previewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(scannedCode: $scannedCode, isProcessing: $isProcessing)
    }

    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        @Binding var scannedCode: String?
        @Binding var isProcessing: Bool
        var captureSession: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer?

        init(scannedCode: Binding<String?>, isProcessing: Binding<Bool>) {
            _scannedCode = scannedCode
            _isProcessing = isProcessing
        }

        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard !isProcessing else { return }
            guard scannedCode == nil else { return }

            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                return
            }

            let request = VNDetectBarcodesRequest { [weak self] request, error in
                if let error = error {
                    Logger.error("Barcode detection error: \(error.localizedDescription)")
                    return
                }

                guard let results = request.results as? [VNBarcodeObservation],
                      let firstBarcode = results.first,
                      let payload = firstBarcode.payloadStringValue else {
                    return
                }

                Logger.debug("Barcode detected - Symbology: \(firstBarcode.symbology.rawValue), Payload: \(payload)")

                // Only process ISBN barcodes (EAN-13 format, which includes ISBN-13)
                if firstBarcode.symbology == .ean13 {
                    Logger.debug("EAN-13 barcode detected: \(payload)")
                    DispatchQueue.main.async {
                        self?.scannedCode = payload
                    }
                } else {
                    Logger.debug("Ignoring non-EAN-13 barcode: \(firstBarcode.symbology.rawValue)")
                }
            }

            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            do {
                try handler.perform([request])
            } catch {
                Logger.error("Failed to perform barcode detection: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Book Detail Sheet

struct BookDetailSheet: View {
    let book: Book
    let onAdd: () -> Void

    @Environment(\.dismiss) var dismiss
    @Environment(\.themeColors) var themeColors

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Book cover
                    if let coverUrl = book.coverUrl, let url = URL(string: coverUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Image(systemName: "book.fill")
                                .font(.system(size: 100))
                                .foregroundColor(themeColors.textSecondary)
                        }
                        .frame(height: 300)
                        .cornerRadius(12)
                    }

                    // Book info
                    VStack(alignment: .leading, spacing: 12) {
                        Text(book.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeColors.textPrimary)

                        if let author = book.author {
                            Text("by \(author)")
                                .font(.subheadline)
                                .foregroundColor(themeColors.textSecondary)
                        }

                        if let description = book.description {
                            Text(description)
                                .font(.body)
                                .foregroundColor(themeColors.textPrimary)
                                .lineLimit(5)
                        }

                        HStack(spacing: 20) {
                            if let pages = book.totalPages {
                                Label("\(pages) pages", systemImage: "book.pages")
                                    .font(.caption)
                                    .foregroundColor(themeColors.textSecondary)
                            }

                            if let isbn = book.isbn {
                                Label("ISBN: \(isbn)", systemImage: "barcode")
                                    .font(.caption)
                                    .foregroundColor(themeColors.textSecondary)
                            }
                        }
                    }
                    .padding()

                    // Add button
                    Button(action: onAdd) {
                        Label("Add to Library", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(themeColors.primary)
                            .cornerRadius(12)
                    }
                    .padding()
                }
            }
            .navigationTitle("Book Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

