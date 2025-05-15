//
//  UserListItem.swift
//  AnamelDemo
//
//  Created by Fatimah Alqarni on 06/05/2025.
//

import CloudKit
import SwiftUI

struct UserCard: Identifiable {
    var id: CKRecord.ID
    var title: String
    var image: UIImage?
    var audioURL: URL?
    var createdAt: Date
    var parentListID: CKRecord.ID
}

extension CloudKitManager {
    var publicDatabase: CKDatabase {
        CKContainer.default().publicCloudDatabase
    }

    func saveCard(title: String, image: UIImage?, audioURL: URL?, parentListID: CKRecord.ID) {
        let cardRecord = CKRecord(recordType: "UserCard")
        cardRecord["title"] = title
        cardRecord["createdAt"] = Date()
        cardRecord["parentList"] = CKRecord.Reference(recordID: parentListID, action: .none)

        if let imageData = image?.jpegData(compressionQuality: 0.8) {
            let imageURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
            try? imageData.write(to: imageURL)
            cardRecord["image"] = CKAsset(fileURL: imageURL)
        }

        if let audioURL = audioURL {
            cardRecord["voiceNote"] = CKAsset(fileURL: audioURL)
        }

        publicDatabase.save(cardRecord) { record, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to save card: \(error.localizedDescription)")
                } else {
                    print("✅ Card saved successfully.")
                }
            }
        }
    }

    func fetchCards(for parentListID: CKRecord.ID, completion: @escaping ([UserCard]) -> Void) {
        let reference = CKRecord.Reference(recordID: parentListID, action: .none)
        let predicate = NSPredicate(format: "parentList == %@", reference)
        let query = CKQuery(recordType: "UserCard", predicate: predicate)

        publicDatabase.perform(query, inZoneWith: nil) { records, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error fetching cards: \(error.localizedDescription)")
                    completion([])
                    return
                }

                let cards = records?.compactMap { record -> UserCard? in
                    let title = record["title"] as? String ?? ""
                    let createdAt = record["createdAt"] as? Date ?? Date()
                    let parentListRef = record["parentList"] as? CKRecord.Reference
                    let parentListID = parentListRef?.recordID ?? CKRecord.ID(recordName: "")

                    var image: UIImage? = nil
                    if let asset = record["image"] as? CKAsset,
                       let fileURL = asset.fileURL,
                       let data = try? Data(contentsOf: fileURL) {
                        image = UIImage(data: data)
                    }

                    var audioURL: URL? = nil
                    if let asset = record["voiceNote"] as? CKAsset {
                        audioURL = asset.fileURL
                    }

                    return UserCard(id: record.recordID, title: title, image: image, audioURL: audioURL, createdAt: createdAt, parentListID: parentListID)
                } ?? []

                completion(cards)
            }
        }
    }
    
    
    func updateCard(recordID: CKRecord.ID, newTitle: String, newImage: UIImage?, newAudioURL: URL?) {
        publicDatabase.fetch(withRecordID: recordID) { record, error in
            guard let record = record, error == nil else {
                print("❌ Error fetching record: \(error?.localizedDescription ?? "")")
                return
            }

            record["title"] = newTitle

            if let image = newImage, let imageData = image.jpegData(compressionQuality: 0.8) {
                let imageURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
                try? imageData.write(to: imageURL)
                record["image"] = CKAsset(fileURL: imageURL)
            }

            if let audioURL = newAudioURL {
                record["voiceNote"] = CKAsset(fileURL: audioURL)
            }

            self.publicDatabase.save(record) { _, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Failed to update record: \(error.localizedDescription)")
                    } else {
                        print("✅ Record updated successfully")
                    }
                }
            }
        }
    }

}
