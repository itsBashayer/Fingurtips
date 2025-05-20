import SwiftUI
import PhotosUI
import CloudKit

struct AddCardView: View {
    var categoryColor: Color
    var categoryID: CKRecord.ID

    @State private var listName: String = ""
    @State private var selectedColor: Color
    @State private var showImagePicker = false
    @State private var selectedUIImage: UIImage?
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @Environment(\.dismiss) private var dismiss
    @State private var showAlert = false // Alert state

    @ObservedObject private var recorder = VoiceRecorderManager()

    init(categoryColor: Color, categoryID: CKRecord.ID) {
        self.categoryColor = categoryColor
        self.categoryID = categoryID
        _selectedColor = State(initialValue: categoryColor)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let isPad = geo.size.width > 600

                ZStack {
                    Image("onboarding")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 20) {
                            HStack {
                                Text("Card Name")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .padding(.top, 30)
                                Spacer()
                            }

                            TextField("Card Name", text: $listName)
                                .padding()
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(Color.blue22, lineWidth: 1.5)
                                        .background(RoundedRectangle(cornerRadius: 30).fill(.white))
                                )
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal)

                            HStack {
                                Text("Attach Image")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Spacer()
                            }

                            Button(action: {
                                showImagePicker = true
                            }) {
                                Image("Upload")
                                    .resizable()
                                    .frame(width: 35, height: 30)
                                    .padding()
                                    .frame(width: 52, height: 52)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(15)
                            }

                            if let uiImage = selectedUIImage {
                                CardPreviewView(
                                    image: Image(uiImage: uiImage),
                                    title: listName.isEmpty ? "No Name" : listName,
                                    frameColor: selectedColor.opacity(0.5),
                                    strokeColor: selectedColor
                                )
                                .onTapGesture {
                                    recorder.isPlaying ? recorder.stopPlayback() : recorder.playRecording()
                                }
                            }

                            HStack {
                                Text("Please record your voice")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Spacer()
                            }

                            HStack(spacing: 20) {
                                Button(action: {
                                    recorder.stopRecording()
                                    recorder.stopPlayback()
                                    recorder.micLevel = 0

                                    let fileManager = FileManager.default
                                    if fileManager.fileExists(atPath: recorder.recordingUrl.path) {
                                        try? fileManager.removeItem(at: recorder.recordingUrl)
                                    }
                                }) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .foregroundColor(.white)
                                        .frame(width: 37, height: 37)
                                        .font(.system(size: 24, weight: .bold))
                                        .background(Circle().fill(Color.blue22).shadow(radius: 2))
                                }

                                Button(action: {
                                    recorder.isRecording ? recorder.stopRecording() : recorder.startRecording()
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.blue22)
                                            .frame(width: 90, height: 90)
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 70.83, height: 70.83)
                                        if recorder.isRecording {
                                            WaveformView(micLevel: recorder.micLevel)
                                                .frame(width: 60, height: 40)
                                        } else {
                                            Image(systemName: "mic.fill")
                                                .foregroundColor(Color.blue22)
                                                .font(.system(size: 24))
                                        }
                                    }
                                }

                                Button(action: {
                                    recorder.isPlaying ? recorder.stopPlayback() : recorder.playRecording()
                                }) {
                                    Image(systemName: recorder.isPlaying ? "pause.fill" : "play.fill")
                                        .frame(width: 37, height: 37)
                                        .foregroundColor(.white)
                                        .font(.system(size: 24, weight: .bold))
                                        .background(Circle().fill(Color.blue22).shadow(radius: 2))
                                }
                            }

                            Button(action: {
                                // Validation for image selection
                                if selectedUIImage == nil {
                                    showAlert = true
                                    return
                                }

                                let fileManager = FileManager.default
                                let hasAudio = fileManager.fileExists(atPath: recorder.recordingUrl.path)
                                cloudKitManager.saveCard(
                                    title: listName,
                                    image: selectedUIImage,
                                    audioURL: (hasAudio && !recorder.isRecording && !recorder.isPlaying) ? recorder.recordingUrl : nil,
                                    parentListID: categoryID
                                )
                                dismiss()
                            }) {
                                Text("Save Card")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, minHeight: 47.34)
                                    .background(Color.blue22)
                                    .foregroundColor(.white)
                                    .cornerRadius(34.83)
                            }
                            .padding(.horizontal)
                            .alert(isPresented: $showAlert) {
                                Alert(title: Text("Error"), message: Text("Please select an image before saving."), dismissButton: .default(Text("OK")))
                            }

                            Button(action: {
                                dismiss()
                            }) {
                                Text("Cancel")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, minHeight: 47.34)
                                    .background(Color.white)
                                    .foregroundColor(.blue22)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 34.83)
                                            .stroke(Color.blue, lineWidth: 1.62)
                                    )
                                    .cornerRadius(34.83)
                            }

                            Spacer(minLength: 80)
                        }
                        .sheet(isPresented: $showImagePicker) {
                            ImagePicker(image: $selectedUIImage) // Ensure this matches the correct name
                        }
                        .padding()
                        .frame(minHeight: geo.size.height)
                    }
                }
            }
        }
    }
}

struct CardPreviewView1: View {
    var image: Image
    var title: String
    var frameColor: Color
    var strokeColor: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                frameColor
                    .frame(width: 133.94, height: 138.69)
                    .cornerRadius(21.79)

                image
                    .resizable()
                    .frame(width: 133.94, height: 138.69)
                    .cornerRadius(21.79)
            }

            Text(title)
                .font(.system(size: 21.78))
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .frame(width: 168.78, height: 210.16)
        .background(Color.white.opacity(0.8))
        .cornerRadius(21.78)
        .overlay(
            RoundedRectangle(cornerRadius: 21.78)
                .stroke(strokeColor, lineWidth: 3.27)
        )
    }
}

// MARK: - Image Picker
struct ImagePicker1: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: ImagePicker1

        init(_ parent: ImagePicker1) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
                return
            }

            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    self.parent.image = image as? UIImage
                }
            }
        }
    }
}
