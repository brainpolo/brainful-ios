//
//  entity.swift
//  brainful
//
//  Created by Aditya STANDARD on 08/02/2025.
//

struct Entity: Codable {
    let id: Int
    let title: String
    let emoji: String
    let color: String

    init?(_ json: [String: Any]) {
        guard let id = json["id"] as? Int,
              let title = json["title"] as? String
        else {
            return nil
        }
        self.id = id
        self.title = title
        self.emoji = (json["emoji"] as? String)?.isEmpty == false ? (json["emoji"] as? String ?? "#") : "#"
        self.color = (json["color"] as? String)?.isEmpty == false ? (json["color"] as? String ?? "#919191") : "#919191"
    }
}
