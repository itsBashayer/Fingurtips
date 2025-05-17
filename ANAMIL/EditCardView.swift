

import SwiftUI
import PhotosUI
import CloudKit

struct EditCardView: View {
    @Binding var card: StaticCard
    var categoryColor: Color
    var recordID: CKRecord.ID? = nil

    @State private var listName: String = ""
    @State private var selectedColor: Color
    @State private var showImagePicker: Bool = false
    @State private var selectedUIImage: UIImage?

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var recorder = VoiceRecorderManager()
    @EnvironmentObject var cloudKitManager: CloudKitManager

    init(categoryColor: Color, initialName: String? = nil, initialImage: UIImage? = nil, recordID: CKRecord.ID? = nil) {
        self._card = .constant(
            StaticCard(title: "", imageName: "", frameColor: categoryColor, strokeColor: categoryColor, iconName: "", imageTopPadding: 0, recordID: CKRecord.ID(recordName: "dummy"), categoryID: recordID ?? CKRecord.ID(recordName: "dummy"))
        )
        self.categoryColor = categoryColor
        self.recordID = recordID
        _selectedColor = State(initialValue: categoryColor)
        _listName = State(initialValue: initialName ?? "")
        _selectedUIImage = State(initialValue: initialImage)
    }

    init(card: Binding<StaticCard>) {
        self._card = card
        self.categoryColor = card.wrappedValue.strokeColor
        _selectedColor = State(initialValue: card.wrappedValue.strokeColor)
        _listName = State(initialValue: card.wrappedValue.title)
        let key = card.wrappedValue.recordID.recordName
        if let imagePath = UserDefaults.standard.string(forKey: "imagePath-\(key)"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: imagePath)),
           let uiImage = UIImage(data: data) {
            _selectedUIImage = State(initialValue: uiImage)
            
        } else {
            _selectedUIImage = State(initialValue: UIImage(named: card.wrappedValue.imageName)) // ❌ fallback
        }

    }

    var body: some View {
        GeometryReader { geo in
            let isPad = geo.size.width > 600
            let buttonWidth = isPad ? 400 : geo.size.width * 0.85

            ZStack {
                Image("onboarding")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        HStack {
                            Spacer()
                            Text("اسم الكرت")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.top, 30)
                        }

                        TextField("اسم الكرت", text: $listName)
                            .padding(.horizontal)
                            .frame(height: 47.65)
                            .frame(maxWidth: buttonWidth)
                            .background(
                                RoundedRectangle(cornerRadius: 8740.54)
                                    .stroke(Color.blue22, lineWidth: 1.5)
                                    .background(RoundedRectangle(cornerRadius: 8740.54).fill(Color(.white)))
                            )
                            .multilineTextAlignment(.trailing)

                        HStack {
                            Spacer()
                            Text("ارفق الصورة")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.top, 30)
                        }

                        Button {
                            showImagePicker = true
                        } label: {
                            Image("Upload")
                                .resizable()
                                .frame(width: 35, height: 30)
                                .padding()
                                .frame(width: buttonWidth, height: 47.34)
                                .background(Color.blue22.opacity(0.2))
                                .cornerRadius(34.83)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 34.83)
                                        .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                                        .foregroundColor(Color.blue22)
                                )
                        }

                        if let uiImage = selectedUIImage {
                            CardPreviewView2(
                                image: Image(uiImage: uiImage),
                                title: listName.isEmpty ? "بدون اسم" : listName,
                                frameColor: selectedColor.opacity(0.5),
                                strokeColor: selectedColor
                            )
                            .onTapGesture {
                                recorder.isPlaying ? recorder.stopPlayback() : recorder.playRecording()
                            }
                        }

                        HStack {
                            Spacer()
                            Text("الرجاء تسجيل صوتك")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.top, 30)
                        }

                        HStack(spacing: 20) {
                            Button {
                                recorder.stopRecording()
                                recorder.stopPlayback()
                                recorder.micLevel = 0
                                let fileManager = FileManager.default
                                if fileManager.fileExists(atPath: recorder.recordingUrl.path) {
                                    try? fileManager.removeItem(at: recorder.recordingUrl)
                                }
                            } label: {
                                Image(systemName: "arrow.counterclockwise")
                                    .foregroundColor(.white)
                                    .frame(width: 37, height: 37)
                                    .font(.system(size: 24, weight: .bold))
                                    .background(Circle().fill(Color.blue22).shadow(radius: 2))
                            }

                            Button {
                                recorder.isRecording ? recorder.stopRecording() : recorder.startRecording()
                            } label: {
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

                            Button {
                                recorder.isPlaying ? recorder.stopPlayback() : recorder.playRecording()
                            } label: {
                                Image(systemName: recorder.isPlaying ? "pause.fill" : "play.fill")
                                    .frame(width: 37, height: 37)
                                    .foregroundColor(.white)
                                    .font(.system(size: 24, weight: .bold))
                                    .background(Circle().fill(Color.blue22).shadow(radius: 2))
                            }
                        }
                        .padding(.horizontal)

                        Button {
                            card.title = listName
                            card.strokeColor = selectedColor

                            let key = card.recordID.recordName
                            UserDefaults.standard.set(listName, forKey: "title-\(key)")

                            if let image = selectedUIImage, let imageData = image.pngData() {
                                let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(key).jpg")
                                try? imageData.write(to: url)
                                UserDefaults.standard.set(url.path, forKey: "imagePath-\(key)")
                                card.customImage = image
                            }

                            let audioURL = recorder.recordingUrl
                            if FileManager.default.fileExists(atPath: audioURL.path) {
                                let audioDest = FileManager.default.temporaryDirectory.appendingPathComponent("\(key).m4a")
                                try? FileManager.default.removeItem(at: audioDest)
                                try? FileManager.default.copyItem(at: audioURL, to: audioDest)
                                UserDefaults.standard.set(audioDest.path, forKey: "audioPath-\(key)")
                                card.audioURL = audioDest
                            }

                            if let recordID = recordID {
                                cloudKitManager.updateCard(
                                    recordID: recordID,
                                    newTitle: listName,
                                    newImage: selectedUIImage,
                                    newAudioURL: recorder.recordingUrl
                                )
                            }

                            dismiss()
                        } label: {
                            Text("تعديل البطاقة")
                                .font(.headline)
                                .frame(width: buttonWidth, height: 47.34)
                                .background(Color.blue22)
                                .foregroundColor(.white)
                                .cornerRadius(34.83)
                        }

                        Button {
                            dismiss()
                        } label: {
                            Text("إلغاء")
                                .font(.headline)
                                .frame(width: buttonWidth, height: 47.34)
                                .background(Color.white)
                                .foregroundColor(.blue22)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 34.83)
                                        .stroke(Color.blue, lineWidth: 1.62)
                                )
                                .cornerRadius(34.83)
                        }

                        if let recordID = recordID {
                            Button {
                                cloudKitManager.publicDatabase.delete(withRecordID: recordID) { _, error in
                                    DispatchQueue.main.async {
                                        if let error = error {
                                            print("❌ فشل في الحذف: \(error.localizedDescription)")
                                        } else {
                                            print("🗑️ تم حذف البطاقة بنجاح")
                                            dismiss()
                                        }
                                    }
                                }
                            } label: {
                                Text("حذف")
                                    .font(.headline)
                                    .frame(width: buttonWidth, height: 47.34)
                                    .background(Color.white)
                                    .foregroundColor(.red)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 34.83)
                                            .stroke(Color.red, lineWidth: 1.62)
                                    )
                                    .cornerRadius(34.83)
                            }
                        }

                        Spacer()
                    }
                    .sheet(isPresented: $showImagePicker) {
                        ImagePicker1(image: $selectedUIImage)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

struct CardPreviewView2: View {
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
