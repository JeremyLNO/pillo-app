import SwiftUI
import PhotosUI

/// Camera is device-only (`UIImagePickerController.isSourceTypeAvailable(.camera)` is
/// false in Simulator) — same pattern as QualiScan's document scanner. `PhotosPicker` is
/// always offered too so the flow is fully testable in Simulator via the Photos library.
struct BlisterScanSheet: View {
    let onResult: (BlisterPackScanner.ScanResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var isScanning = false
    @State private var scanFailed = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 48))
                    .foregroundStyle(Palette.primary)

                Text("onboarding.scan.explanation")
                    .font(Typography.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Palette.textSecondary)

                if isScanning {
                    ProgressView()
                }

                if scanFailed {
                    Text("onboarding.scan.notDetected")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                VStack(spacing: 12) {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        PrimaryButton(title: String(localized: "onboarding.scan.takePhoto")) {
                            showingCamera = true
                        }
                    }
                    PhotosPicker(selection: $photosPickerItem, matching: .images) {
                        Text("onboarding.scan.choosePhoto")
                    }
                }
            }
            .padding(24)
            .navigationTitle(Text("onboarding.scan.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            BlisterCameraCaptureView { image in
                process(image: image)
            }
        }
        .onChange(of: photosPickerItem) { _, newItem in
            Task {
                guard let newItem,
                      let data = try? await newItem.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data)
                else { return }
                process(image: uiImage)
            }
        }
    }

    private func process(image: UIImage) {
        guard let cgImage = image.cgImage else {
            scanFailed = true
            return
        }
        isScanning = true
        scanFailed = false
        Task {
            let result = await BlisterPackScanner.scan(cgImage)
            isScanning = false
            if let result {
                onResult(result)
                dismiss()
            } else {
                scanFailed = true
            }
        }
    }
}

private struct BlisterCameraCaptureView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, dismiss: dismiss)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let onCapture: (UIImage) -> Void
        private let dismiss: DismissAction

        init(onCapture: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onCapture = onCapture
            self.dismiss = dismiss
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}
