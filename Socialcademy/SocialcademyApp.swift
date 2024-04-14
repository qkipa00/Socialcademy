//
//  SocialcademyApp.swift
//  Socialcademy
//
//  Created by Anastasiya Kiptsevich on 09.04.2024.
//

import SwiftUI
import Firebase

@main
struct SocialcademyApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            AuthView()
        }
    }
}
