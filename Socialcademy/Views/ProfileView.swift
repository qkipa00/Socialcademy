//
//  ProfileView.swift
//  Socialcademy
//
//  Created by Anastasiya Kiptsevich on 14.04.2024.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    var body: some View {
        Button("Sign Out", action: {
            try! Auth.auth().signOut()
        })
    }
}

#Preview {
    ProfileView()
}
