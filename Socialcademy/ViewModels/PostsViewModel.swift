//
//  PostsViewModel.swift
//  Socialcademy
//
//  Created by Anastasiya Kiptsevich on 10.04.2024.
//

import Foundation

@MainActor
class PostsViewModel: ObservableObject {
    @Published var posts: Loadable<[Post]> = .loading
    
    private let postsRepository: PostsRepositoryProtocol
    
    init(postsRepository: PostsRepositoryProtocol = PostsRepository()) {
        self.postsRepository = postsRepository
    }
    
    func makeCreateAction() -> NewPostForm.CreateAction {
        return { [weak self] post in
            try await self?.postsRepository.create(post)
            self?.posts.value?.insert(post, at: 0)
        }
    }
    
    func fetchPosts() {
        Task {
            do {
                posts = .loaded(try await postsRepository.fetchPosts())
            } catch {
                print("[PostsViewModel Cannot fetch posts: \(error)")
                posts = .error(error)
            }
        }
    }
    
    func makePostRowViewModel(for post: Post) -> PostRowViewModel {
        return PostRowViewModel(
            post: post,
            deleteAction: { [weak self] in
                try await self?.postsRepository.delete(post)
                self?.posts.value?.removeAll { $0.id == post.id }
            },
            favoriteAction: { [weak self] in
                let newValue = !post.isFavorite
                try await newValue ? self?.postsRepository.favorite(post) : self?.postsRepository.unfavorite(post)
                guard let i = self?.posts.value?.firstIndex(of: post) else { return }
                self?.posts.value?[i].isFavorite = newValue
            }
        )
    }
}
