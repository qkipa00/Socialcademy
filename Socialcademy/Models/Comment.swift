//
//  Comment.swift
//  Socialcademy
//
//  Created by Anastasiya Kiptsevich on 14.05.2024.
//

import Foundation

struct Comment: Identifiable, Equatable, Codable {
    var content: String
    var author: User
    var timestamp = Date()
    var id = UUID()
}

extension Comment {
    static let testComment = Comment(content: "Lorem ipsum dolor set amet.", author: User.testUser)
}
