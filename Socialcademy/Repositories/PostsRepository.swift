//
//  PostsRepository.swift
//  Socialcademy
//
//  Created by Anastasiya Kiptsevich on 10.04.2024.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

protocol PostsRepositoryProtocol {
    var user: User { get }
    func fetchAllPosts() async throws -> [Post]
    func fetchFavoritePosts() async throws -> [Post]
    func fetchPosts(by author: User) async throws -> [Post]
    func create(_ post: Post) async throws
    func delete(_ post: Post) async throws
    func favorite(_ post: Post) async throws
    func unfavorite(_ post: Post) async throws
}

extension PostsRepositoryProtocol {
    func canDelete(_ post: Post) -> Bool {
        post.author.id == user.id
    }
}

#if DEBUG
struct PostsRepositoryStub: PostsRepositoryProtocol {
    let user = User.testUser
    let state: Loadable<[Post]>
    
    func fetchAllPosts() async throws -> [Post] {
        return try await state.simulate()
    }
    
    func fetchFavoritePosts() async throws -> [Post] {
        return try await state.simulate()
    }
    
    func fetchPosts(by author: User) async throws -> [Post] {
        return try await state.simulate()
    }
    
    func create(_ post: Post) async throws {}
    
    func delete(_ post: Post) async throws {}
    
    func favorite(_ post: Post) async throws {}
    
    func unfavorite(_ post: Post) async throws {}
}
#endif


struct PostsRepository: PostsRepositoryProtocol {
    let user: User
    let postsReference = Firestore.firestore().collection("posts_v3")
    let favoritesReference = Firestore.firestore().collection("favorites")
    
    func fetchAllPosts() async throws -> [Post] {
        return try await fetchPosts(from: postsReference)
    }
    
    func fetchPosts(by author: User) async throws -> [Post] {
        return try await fetchPosts(from: postsReference.whereField("author.id", isEqualTo: author.id))
    }
    
    func fetchFavoritePosts() async throws -> [Post] {
        let favorites = try await fetchFavorites()
        guard !favorites.isEmpty else { return [] }
        return try await postsReference
            .whereField("id", in: favorites.map(\.uuidString))
            .order(by: "timestamp", descending: true)
            .getDocuments(as: Post.self)
            .map { post in
                post.setting(\.isFavorite, to: true)
            }
    }
    
    func create(_ post: Post) async throws {
        var post = post
        if let imageFileURL = post.imageURL {
            post.imageURL = try await StorageFile
                .with(namespace: "posts", identifier: post.id.uuidString)
                .putFile(from: imageFileURL)
                .getDownloadURL()
        }
        let document = postsReference.document(post.id.uuidString)
        try await document.setData(from: post)
    }
    
    func delete(_ post: Post) async throws {
        precondition(canDelete(post))
        let document = postsReference.document(post.id.uuidString)
        try await document.delete()
        let image = post.imageURL.map(StorageFile.atURL(_:))
        try await image?.delete()
    }
    
    func favorite(_ post: Post) async throws {
        let favorite = Favorite(postID: post.id, userID: user.id)
        let document = favoritesReference.document(favorite.id)
        try await document.setData(from: favorite)
    }
    
    func unfavorite(_ post: Post) async throws {
        let favorite = Favorite(postID: post.id, userID: user.id)
        let document = favoritesReference.document(favorite.id)
        try await document.delete()
    }
}


private extension PostsRepository {
    func fetchPosts(from query: Query) async throws -> [Post] {
        let (posts, favorites) = try await (
            query.order(by: "timestamp", descending: true).getDocuments(as: Post.self),
            fetchFavorites()
        )
        return posts.map { post in
            post.setting(\.isFavorite, to: favorites.contains(post.id))
        }
    }
    
    func fetchFavorites() async throws -> [Post.ID] {
        return try await favoritesReference
            .whereField("userID", isEqualTo: user.id)
            .getDocuments(as: Favorite.self)
            .map(\.postID)
    }
    
    struct Favorite: Identifiable, Codable {
        let postID: Post.ID
        let userID: User.ID
        var id: String {
            postID.uuidString + "-" + userID
        }
    }
}

private extension Post {
    func setting<T>(_ property: WritableKeyPath<Post, T>, to newValue: T) -> Post {
        var post = self
        post[keyPath: property] = newValue
        return post
    }
}


private extension DocumentReference {
    func setData<T: Encodable>(from value: T) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            // Method only throws if there’s an encoding error, which indicates a problem with our model.
            // We handled this with a force try, while all other errors are passed to the completion handler.
            try! setData(from: value) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume()
            }
        }
    }
}


private extension Query {
    func getDocuments<T: Decodable>(as type: T.Type) async throws -> [T] {
        let snapshot = try await getDocuments()
        return snapshot.documents.compactMap { document in
            try! document.data(as: type)
        }
    }
}

