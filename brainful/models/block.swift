//
//  block.swift
//  brainful
//
//  Created by Aditya STANDARD on 08/02/2025.
//
import SwiftUI


struct Block: Codable, Identifiable, Equatable {
    let luid: String
    let slug: String
    let type: String
    var pinned: Bool
    let created_timestamp: Date?
    let last_edited: Date?

    var entities: [Entity]?
    
    var text: String?

    var id: String { luid }

    static func == (lhs: Block, rhs: Block) -> Bool {
        return lhs.luid == rhs.luid
    }
}
