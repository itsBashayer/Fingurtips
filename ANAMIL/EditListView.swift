import SwiftUI
import PhotosUI
import CloudKit

struct EditListView: View {
    @State private var listName: String
    @State private var selectedColor: Color
    @State private var selectedUIImage: UIImage?
    private var isCloudItem: Bool
    @EnvironmentObject var cloudKitManager: CloudKitManager
    private var recordID: CKRecord.ID?
    @Binding var card: StaticCard

    @State private var showImagePicker: Bool = false
    @Environment(\.dismiss) private var dismiss

    @State private var showColorPicker = false
    @State private var customColor: Color = .blue
    @State private var userColors: [Color] = [
        Color(red: 1.0, green: 0.8, blue: 0.8),
        Color(red: 0.8, green: 1.0, blue: 0.8),
        Color(red: 0.8, green: 0.8, blue: 1.0)
    ]
    private var initialFrameColor: Color?

    init(
        initialName: String? = nil,
        initialImage: UIImage? = nil,
        initialColor: Color? = nil,
        initialFrameColor: Color? = nil,
        isCloudItem: Bool = false,
        recordID: CKRecord.ID? = nil,
        card: Binding<StaticCard> = .constant(
            StaticCard(title: "", imageName: "", frameColor: .clear, strokeColor: .clear, iconName: "", imageTopPadding: 0, recordID: CKRecord.ID(recordName: "default"), categoryID: CKRecord.ID(recordName: "default-category"))
        )
    ) {
        if isCloudItem && recordID == nil {
            fatalError("❌ You must provide a recordID when isCloudItem is true.")
        }

        _listName = State(initialValue: initialName ?? "")
        _selectedUIImage = State(initialValue: initialImage)
        _selectedColor = State(initialValue: initialColor ?? .blue)
        self.initialFrameColor = initialFrameColor
        self.isCloudItem = isCloudItem
        self.recordID = recordID
        self._card = card
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
                                Text("List Name")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .padding(.top, 30)
                                Spacer()
                            }

                            TextField("List Name", text: $listName)
                                .padding()
                                .foregroundColor(.navey)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(Color.blue22, lineWidth: 1.5)
                                        .background(RoundedRectangle(cornerRadius: 30).fill(.white))
                                )
                                .multilineTextAlignment(.leading) // Left alignment
                                .padding(.horizontal)

                            HStack {
                                Text("Color")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Spacer()
                            }

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
                                ColorPicker("Select a Color", selection: $customColor)
                                    .padding(.horizontal)
                                    .onChange(of: customColor) { newColor in
                                        userColors.append(newColor)
                                        selectedColor = newColor
                                        showColorPicker = false
                                    }
                            }

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
                            }

                            Button(action: {
                                if isCloudItem {
                                    if let recordID = recordID {
                                        cloudKitManager.updateList(id: recordID, title: listName, color: selectedColor, image: selectedUIImage)
                                    } else {
                                        cloudKitManager.saveList(title: listName, color: selectedColor, image: selectedUIImage)
                                    }
                                } else {
                                    card.title = listName
                                    card.strokeColor = selectedColor
                                    card.frameColor = selectedColor
                                    card.customImage = selectedUIImage
                                    UserDefaults.standard.set(listName, forKey: "title-category-\(card.recordID.recordName)")
                                    let colorHex = selectedColor.toHex()
                                    UserDefaults.standard.set(colorHex, forKey: "color-category-\(card.categoryID.recordName)")
                                    UserDefaults.standard.set(colorHex, forKey: "frame-color-category-\(card.recordID.recordName)")
                                    if let image = selectedUIImage, let imageData = image.pngData() {
                                        UserDefaults.standard.set(imageData, forKey: "image-\(card.recordID.recordName)")
                                    }
                                }
                                dismiss()
                            }) {
                                Text("Edit Category")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, minHeight: 47.34)
                                    .background(Color.blue22)
                                    .foregroundColor(.white)
                                    .cornerRadius(34.83)
                            }
                            .padding(.horizontal)

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

                            if isCloudItem, let recordID = recordID {
                                Button(action: {
                                    cloudKitManager.deleteList(id: recordID)
                                    dismiss()
                                }) {
                                    Text("Delete")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity, minHeight: 47.34)
                                        .background(Color.white)
                                        .foregroundColor(.red)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 34.83)
                                                .stroke(Color.red, lineWidth: 1.62)
                                        )
                                        .cornerRadius(34.83)
                                }
                            }
                            Spacer(minLength: 80)
                        }
                        .sheet(isPresented: $showImagePicker) {
                            ImagePicker(image: $selectedUIImage)
                        }
                        .padding()
                        .frame(minHeight: geo.size.height)
                    }
                }
            }
        }
    }
}
