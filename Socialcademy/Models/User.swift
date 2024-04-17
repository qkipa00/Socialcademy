//
//  User.swift
//  Socialcademy
//
//  Created by Anastasiya Kiptsevich on 14.04.2024.
//

import Foundation

struct User: Identifiable, Equatable, Codable {
    var id: String
    var name: String
}

extension User {
    static let testUser = User(id: "", name: "Jamie Harris")
}

