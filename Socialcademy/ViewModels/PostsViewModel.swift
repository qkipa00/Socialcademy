//
//  PostsViewModel.swift
//  Socialcademy
//
//  Created by Anastasiya Kiptsevich on 10.04.2024.
//

import Foundation

@MainActor
class PostsViewModel: ObservableObject {
    @Published var posts = [Post.testPost]
    
    
    func makeCreateAction() -> NewPostForm.CreateAction {
        return { [weak self] post in
            try await PostsRepository.create(post)
            self?.posts.insert(post, at: 0)
        }
    }
}
