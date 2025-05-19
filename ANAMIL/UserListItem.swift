
import CloudKit
import SwiftUI

struct UserListItem: Identifiable {
    var id: CKRecord.ID
    var title: String
    var color: Color
    var image: UIImage?
    var createdAt: Date
}

class CloudKitManager: ObservableObject {
    @Published var lists: [UserListItem] = []

    let container = CKContainer.default()
    
    let database = CKContainer.default().publicCloudDatabase

    func fetchLists() {
        let query = CKQuery(recordType: "UserList", predicate: NSPredicate(value: true))

        database.perform(query, inZoneWith: nil) { records, error in
            DispatchQueue.main.async {
                let sortedRecords = records?.sorted {
                    let date1 = $0["createdAt"] as? Date ?? Date.distantPast
                    let date2 = $1["createdAt"] as? Date ?? Date.distantPast
                    return date1 < date2
                }

                self.lists = sortedRecords?.compactMap { record in
                    let title = record["title"] as? String ?? ""
                    let colorHex = record["colorHex"] as? String ?? "#0000FF"
                    let color = Color(hex: colorHex)
                    let createdAt = record["createdAt"] as? Date ?? Date.distantPast

                    var image: UIImage? = nil
                    if let asset = record["image"] as? CKAsset,
                       let fileURL = asset.fileURL,
                       let imageData = try? Data(contentsOf: fileURL) {
                        image = UIImage(data: imageData)
                    }

                    return UserListItem(id: record.recordID, title: title, color: color, image: image, createdAt: createdAt)
                } ?? []
            }
        }
    }

    func saveList(title: String, color: Color, image: UIImage?) {
        let record = CKRecord(recordType: "UserList")
        record["title"] = title
        record["colorHex"] = color.toHex()
        record["createdAt"] = Date()

        if let image = image, let url = image.saveToTemporaryLocation() {
            record["image"] = CKAsset(fileURL: url)
        }

        database.save(record) { savedRecord, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error saving record: \(error.localizedDescription)")
                } else if let savedRecord = savedRecord {
                    print("✅ Saved record: \(savedRecord)")
                    // ✅ Manually insert instead of refetching everything
                    let title = savedRecord["title"] as? String ?? ""
                    let colorHex = savedRecord["colorHex"] as? String ?? "#0000FF"
                    let color = Color(hex: colorHex)
                    let createdAt = savedRecord["createdAt"] as? Date ?? Date()

                    var imageResult: UIImage? = nil
                    if let asset = savedRecord["image"] as? CKAsset,
                       let fileURL = asset.fileURL,
                       let imageData = try? Data(contentsOf: fileURL) {
                        imageResult = UIImage(data: imageData)
                    }

                    let newItem = UserListItem(
                        id: savedRecord.recordID,
                        title: title,
                        color: color,
                        image: imageResult,
                        createdAt: createdAt
                    )

                    self.lists.append(newItem)
                    // Optional: Sort after inserting
                    self.lists.sort { $0.createdAt < $1.createdAt }
                }
            }
        }
    }
    
    func updateList(id: CKRecord.ID, title: String, color: Color, image: UIImage?) {
        database.fetch(withRecordID: id) { record, error in
            guard let record = record, error == nil else {
                print("❌ Error fetching record for update: \(error?.localizedDescription ?? "")")
                return
            }

            record["title"] = title
            record["colorHex"] = color.toHex()

            if let image = image, let url = image.saveToTemporaryLocation() {
                record["image"] = CKAsset(fileURL: url)
            }

            self.database.save(record) { savedRecord, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Failed to update: \(error.localizedDescription)")
                    } else if let saved = savedRecord {
                        print("✅ Updated record: \(saved.recordID.recordName)")
                        self.fetchLists()
                    }
                }
            }
        }
    }
    
    func deleteList(id: CKRecord.ID) {
        database.delete(withRecordID: id) { deletedID, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ فشل في الحذف: \(error.localizedDescription)")
                } else {
                    print("🗑️ تم حذف القائمة بنجاح")
                    self.fetchLists()
                }
            }
        }
    }



}

// MARK: - Extensions

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255

        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String? {
        let uiColor = UIColor(self)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        return String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
    }
}


extension UIColor {
    func toHexString() -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
    }
}

extension UIImage {
    func saveToTemporaryLocation() -> URL? {
        let data = self.jpegData(compressionQuality: 0.8)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
        try? data?.write(to: url)
        return url
    }
}
