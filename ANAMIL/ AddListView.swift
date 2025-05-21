import SwiftUI
import PhotosUI

struct AddListView: View {
    @State private var listName: String = ""
    @State private var selectedColor: Color = .blue
    @State private var showImagePicker: Bool = false
    @State private var selectedUIImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var showColorPicker = false
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @State private var customColor: Color = .blue
    @State private var userColors: [Color] = [
        Color(red: 1.0, green: 0.8, blue: 0.8),
        Color(red: 0.8, green: 1.0, blue: 0.8),
        Color(red: 0.8, green: 0.8, blue: 1.0)
    ]
    @State private var showAlert = false // Alert state
    @State private var alertMessage: String = ""

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
                            Spacer(minLength: 10)

                            // Text aligned left by removing Spacer and default alignment
                            Text("List Name")
                                .font(.title)
                                .fontWeight(.bold)
                                .padding(.top, 20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)

                            TextField("List Name", text: $listName)
                                .padding()
                                .foregroundColor(.navey) //
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(Color.blue22, lineWidth: 1.5)
                                        .background(RoundedRectangle(cornerRadius: 30).fill(.white))
                                )
                                .multilineTextAlignment(.leading)  // Changed from .trailing to .leading
                                .padding(.horizontal)

                            Text("Color")
                                .font(.title)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(userColors.indices, id: \.self) { index in
                                        let color = userColors[index]
                                        Circle()
                                            .fill(color)
                                            .frame(width: 30, height: 30)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.black.opacity(selectedColor == color ? 0.8 : 0), lineWidth: 2)
                                            )
                                            .onTapGesture {
                                                selectedColor = color
                                            }
                                    }

                                    Button(action: {
                                        showColorPicker.toggle()
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.gray)
                                            .font(.title2)
                                    }
                                }
                                .padding(.horizontal)
                            }

                            if showColorPicker {
                                ColorPicker("Choose a color", selection: $customColor)
                                    .padding(.horizontal)
                                    .onChange(of: customColor) { newColor in
                                        userColors.append(newColor)
                                        selectedColor = newColor
                                        showColorPicker = false
                                    }
                            }

                            Text("Upload Image")
                                .font(.title)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)

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
                            .padding(.horizontal)

                            if let uiImage = selectedUIImage {
                                CardPreviewView(
                                    image: Image(uiImage: uiImage),
                                    title: listName.isEmpty ? "بدون اسم" : listName,
                                    frameColor: selectedColor.opacity(0.5),
                                    strokeColor: selectedColor
                                )
                            }

                            Button(action: {
                                if selectedUIImage == nil {
                                    alertMessage = "Please select an image before saving"
                                    showAlert = true
                                    return
                                }
                                if listName.isEmpty {
                                    alertMessage = "Please enter the list name."
                                    showAlert = true
                                    return
                                }
                                if selectedColor == .blue {
                                    alertMessage = "Please select the list color."
                                    showAlert = true
                                    return
                                }

                                cloudKitManager.saveList(title: listName, color: selectedColor, image: selectedUIImage)
                                dismiss()
                            }) {
                                Text("Save Category")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, minHeight: 47.34)
                                    .background(Color.blue22)
                                    .foregroundColor(.white)
                                    .cornerRadius(34.83)
                            }
                            .padding(.horizontal)
                            .alert(isPresented: $showAlert) {
                                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("Ok")))
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
                            .padding(.horizontal)

                            Spacer(minLength: 20)
                        }
                        .sheet(isPresented: $showImagePicker) {
                            ImagePicker(image: $selectedUIImage)
                        }
                        .padding()
                    }
                }
            }
        }
    }
}

// MARK: - Card Preview
struct CardPreviewView: View {
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
                .font(.system(size: 20))
                .fontWeight(.medium)
                .foregroundColor(.navey)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .frame(width: 168.78, height: 210.16)
        .background(Color("CardBGColor"))
        .background(Color.white.opacity(0.8))
        .cornerRadius(21.78)
        .overlay(
            RoundedRectangle(cornerRadius: 21.78)
                .stroke(strokeColor, lineWidth: 3.27)
        )
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
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
        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else {
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
