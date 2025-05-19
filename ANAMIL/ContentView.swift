//
//  ContentView.swift
//  ANAMIL
//
//  Created by BASHAER AZIZ on 29/10/1446 AH.
//   .padding(.top, geo.size.height > 800 ? 400 : 20)



import SwiftUI
import CloudKit
import LocalAuthentication

struct StaticCard: Identifiable {
    let id = UUID()
    var title: String
    var imageName: String
    var customImage: UIImage? = nil
    var audioURL: URL? = nil
    var frameColor: Color
    var strokeColor: Color
    var iconName: String
    var imageTopPadding: CGFloat
    var recordID: CKRecord.ID
    var categoryID: CKRecord.ID
}

enum CategoryIDs {
    static let feelings = CKRecord.ID(recordName: "category-feelings")
    static let food = CKRecord.ID(recordName: "category-food")
    static let games = CKRecord.ID(recordName: "category-games")
    static let clothes = CKRecord.ID(recordName: "category-clothes")
    static let pain = CKRecord.ID(recordName: "category-pain")
}

struct ContentView: View {
    @State private var showAddListSheet = false
    @State private var isEditing = false
    @StateObject private var cloudKitManager = CloudKitManager()
    @State private var staticCards: [StaticCard] = []
    @State private var authPassed = false ///h
    @State private var loadedTitle: String = ""
    @State private var loadedColor: Color = .purple1
    @State private var loadedImage: UIImage?
    
    //start Face ID authentication logic
        private func authenticateWithFaceID(completion: @escaping (Bool) -> Void) {
            let context = LAContext()
            var error: NSError?

            
            // ✅ This line allows Face ID with passcode fallback
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                let reason = "الرجاء التحقق باستخدام Face ID أو كلمة المرور لإضافة قائمة جديدة"

                context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                    DispatchQueue.main.async {
                        completion(success)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }//end

 
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let isPad = geo.size.width > 600
                let columns = [GridItem(.adaptive(minimum: isPad ? 220 : 160), spacing: 20)]
                let cardWidth = isPad ? 220.0 : 160.0

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .trailing, spacing: 16) {
                            
                            HStack {
                                Spacer()
                                Button(action: {
                                    authenticateWithFaceID { success in
                                        if success {
                                            isEditing.toggle()
                                        }
                                    }
                                }) {
                                    Text(isEditing ? "تم" : "تعديل")
                                        .frame(width: 63, height: 26.42)
                                        .font(.system(size: 14.85, weight: .bold))
                                        .foregroundColor(.darkBlue1)
                                        .background(Color.white)
                                        .cornerRadius(25.52)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 30)
                            //   .padding(.top, geo.size.height > 800 ? 400 : 20)

                            
                            VStack(alignment: .trailing, spacing: 8) {
                                Text("قوائم طفلك ")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.black)

                                Text("لا تنسى تفعيل الأشعارات!")
                                    .font(.system(size: 18))
                                    .foregroundColor(.black)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)

                        
                            LazyVGrid(columns: columns, spacing: 28) {
                                ForEach($staticCards) { $card in
                                    NavigationLink(destination: destinationView(for: card).environmentObject(cloudKitManager)) {
                                        CardButtonView(card: $card, isEditing: $isEditing, cardWidth: cardWidth)
                                    }
                                }

                                ForEach(cloudKitManager.lists) { list in
                                    NavigationLink(
                                        destination: CategoryView(categoryID: list.id, categoryColor: list.color, categoryTitle: list.title)
                                            .environmentObject(cloudKitManager)) {
                                        VStack(spacing: 8) {
                                            ZStack(alignment: .topTrailing) {
                                                RoundedRectangle(cornerRadius: 21.79)
                                                    .fill(list.color)
                                                    .frame(width: cardWidth * 0.9, height: cardWidth * 0.9)

                                                if let uiImage = list.image {
                                                    Image(uiImage: uiImage)
                                                        .resizable()
                                                        .frame(width: cardWidth * 0.9, height: cardWidth * 0.9)
                                                        .cornerRadius(21.79)
                                                } else {
                                                    Image(systemName: "photo")
                                                        .resizable()
                                                        .frame(width: 40, height: 40)
                                                        .foregroundColor(.gray)
                                                        .padding(.top, 40)
                                                }

                                                if isEditing {
                                                    NavigationLink(destination: EditListView(
                                                        initialName: list.title,
                                                        initialImage: list.image,
                                                        initialColor: list.color,
                                                        isCloudItem: true,
                                                        recordID: list.id
                                                    ).environmentObject(cloudKitManager)) {
                                                        ZStack {
                                                            Circle()
                                                                .fill(Color.blue.opacity(0.2))
                                                                .frame(width: 36, height: 36)

                                                            Image(systemName: "pencil")
                                                                .resizable()
                                                                .scaledToFit()
                                                                .frame(width: 16, height: 16)
                                                                .foregroundColor(.blue)
                                                                .padding(10)
                                                        }
                                                        .padding(.trailing, -5)
                                                    }
                                                }
                                            }

                                            Text(list.title)
                                                .font(.system(size: 21.78))
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.center)
                                                .frame(maxWidth: .infinity, alignment: .center)
                                        }
                                        .padding()
                                        .frame(width: cardWidth, height: cardWidth * 1.5)
                                        .cornerRadius(21.78)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 21.78)
                                                .stroke(list.color, lineWidth: 3.27)
                                        )
                                    }
                                }

                                
                                Button(action: {
                                    authenticateWithFaceID { success in
                                        if success {
                                            authPassed = true
                                        }
                                    }
                                }) {
                                    CardButtonView(card: .constant(
                                        StaticCard(
                                            title: "إضافة قائمة",
                                            imageName: "Plus Sign",
                                            frameColor: .blue1,
                                            strokeColor: .darkBlue,
                                            iconName: "Adding Icon",
                                            imageTopPadding: 10,
                                            recordID: CKRecord.ID(recordName: "إضافة قائمة"),
                                            categoryID: CKRecord.ID(recordName: "إضافة قائمة")
                                        )
                                    ), isEditing: $isEditing, cardWidth: cardWidth)
                                }
                                .fullScreenCover(isPresented: $authPassed) {
                                    AddListView().environmentObject(cloudKitManager)
                                }
                            }

                            Spacer(minLength: 100)
                        }
                        .padding()
                        .frame(minHeight: geo.size.height)
                    }
                    .background(
                        Image("onboarding")
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                    )
                }
            }
            .onAppear {
                cloudKitManager.fetchLists()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    loadedTitle = UserDefaults.standard.string(forKey: "title-\(CategoryIDs.feelings.recordName)") ?? "المشاعر"
                    loadedColor = Color(hex: UserDefaults.standard.string(forKey: "color-category-feelings") ?? "#0000FF")
                    if let imageData = UserDefaults.standard.data(forKey: "image-\(CategoryIDs.feelings.recordName)"),
                       let image = UIImage(data: imageData) {
                        loadedImage = image
                    }
                    self.staticCards = loadStaticCards()
                }
            }
        }
    }


    private func loadStaticCards() -> [StaticCard] {
        func loadTitle(for id: CKRecord.ID, defaultTitle: String) -> String {
            UserDefaults.standard.string(forKey: "title-category-\(id.recordName)") ?? defaultTitle
        }
        func loadImage(for id: CKRecord.ID) -> UIImage? {
            if let data = UserDefaults.standard.data(forKey: "image-\(id.recordName)") {
                return UIImage(data: data)
            }
            return nil
        }
        func loadStrokeColor(for id: CKRecord.ID, defaultColor: Color) -> Color {
            UserDefaults.standard.string(forKey: "color-category-\(id.recordName)").map(Color.init(hex:)) ?? defaultColor
        }
        func loadFrameColor(for id: CKRecord.ID, defaultColor: Color) -> Color {
            UserDefaults.standard.string(forKey: "frame-color-category-\(id.recordName)").map(Color.init(hex:)) ?? defaultColor
        }

        return [
            StaticCard(title: loadTitle(for: CategoryIDs.feelings, defaultTitle: "المشاعر"), imageName: "Feelings", customImage: loadImage(for: CategoryIDs.feelings), frameColor: loadFrameColor(for: CategoryIDs.feelings, defaultColor: .purple1), strokeColor: loadStrokeColor(for: CategoryIDs.feelings, defaultColor: .purple1), iconName: "Heart Icon", imageTopPadding: 32, recordID: CategoryIDs.feelings, categoryID: CategoryIDs.feelings),
            
            StaticCard(title: loadTitle(for: CategoryIDs.food, defaultTitle: "الأكل"), imageName: "Food", customImage: loadImage(for: CategoryIDs.food), frameColor: loadFrameColor(for: CategoryIDs.food, defaultColor: .yelow1), strokeColor: loadStrokeColor(for: CategoryIDs.food, defaultColor: .darkYellow), iconName: "Food Icon", imageTopPadding: 10, recordID: CategoryIDs.food, categoryID: CategoryIDs.food),
            
            StaticCard(title: loadTitle(for: CategoryIDs.games, defaultTitle: "الألعاب"), imageName: "Games1", customImage: loadImage(for: CategoryIDs.games), frameColor: loadFrameColor(for: CategoryIDs.games, defaultColor: .lavender), strokeColor: loadStrokeColor(for: CategoryIDs.games, defaultColor: .darkLavender), iconName: "Game Icon", imageTopPadding: 20, recordID: CategoryIDs.games, categoryID: CategoryIDs.games),
            
            StaticCard(title: loadTitle(for: CategoryIDs.clothes, defaultTitle: "الملابس"), imageName: "Cloth", customImage: loadImage(for: CategoryIDs.clothes), frameColor: loadFrameColor(for: CategoryIDs.clothes, defaultColor: .green1), strokeColor: loadStrokeColor(for: CategoryIDs.clothes, defaultColor: .darkGreen), iconName: "Cloth Icon", imageTopPadding: 20, recordID: CategoryIDs.clothes, categoryID: CategoryIDs.clothes),
            
            StaticCard(title: loadTitle(for: CategoryIDs.pain, defaultTitle: "ايش يعورني؟"), imageName: "Pain", customImage: loadImage(for: CategoryIDs.pain), frameColor: loadFrameColor(for: CategoryIDs.pain, defaultColor: .red1), strokeColor: loadStrokeColor(for: CategoryIDs.pain, defaultColor: .darkOrange), iconName: "Pain Icon", imageTopPadding: 32, recordID: CategoryIDs.pain, categoryID: CategoryIDs.pain)
        ]
    }

    @ViewBuilder
    func destinationView(for card: StaticCard) -> some View {
        switch card.recordID.recordName {
        case "category-clothes": ClothesView(categoryID: card.recordID)
        case "category-food": FoodView(categoryID: card.recordID)
        case "category-feelings": FeelingsView(categoryID: card.recordID)
        case "category-games": GamesView(categoryID: card.recordID)
        case "category-pain": PainView(categoryID: card.recordID)
        default: Text("قائمة غير معروفة")
        }
    }
}

struct CardButtonView: View {
    @Binding var card: StaticCard
    @Binding var isEditing: Bool
    var cardWidth: CGFloat

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topLeading) {

                card.frameColor.opacity(0.5) // new
                    .frame(width: cardWidth * 0.9, height: cardWidth * 0.9) // 🌸
                    .cornerRadius(21.79)

                if let customImage = card.customImage {
                    Image(uiImage: customImage)
                        .resizable()
                        .frame(width: cardWidth * 0.9, height: cardWidth * 0.9)// 🌸
                        .cornerRadius(21.79)
                } else {
                    Image(card.imageName)
                        .resizable()
                        .frame(width: cardWidth * 0.9, height: cardWidth * 0.9)// 🌸
                        .cornerRadius(21.79)

                }

                Image(card.iconName)
                    .resizable()
                    .renderingMode(.template) //New
                    .foregroundColor(card.frameColor) // new
                    .frame(width: 20, height: 20)
                    .padding(14)

                if isEditing && card.title != "إضافة قائمة" {
                    NavigationLink(destination: EditListView(
                        initialName: card.title,
                        initialImage: card.customImage ?? UIImage(named: card.imageName) ?? UIImage(),
                        initialColor: card.strokeColor,
                        initialFrameColor: card.frameColor,
                        isCloudItem: false,
                        recordID: nil,
                        card: $card
                    )) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 36, height: 36)
                            Image(systemName: "pencil")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .foregroundColor(.blue)
                        }
                        .padding(.leading, cardWidth - 54) // 🌸
                    }
                }
            }

            Text(card.title)
                .font(.system(size: 21.78))
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .frame(width: cardWidth, height: cardWidth * 1.5)
        .background(Color.white.opacity(0.8))
        .cornerRadius(21.78)
        .overlay(
            RoundedRectangle(cornerRadius: 21.78)
                .stroke(card.strokeColor, lineWidth: 3.27)
        )
    }
}




#Preview {
    ContentView()
}
