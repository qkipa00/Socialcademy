//
//  PostRow.swift
//  Socialcademy
//
//  Created by Anastasiya Kiptsevich on 09.04.2024.
//

import SwiftUI

struct PostRow: View {
    @ObservedObject var viewModel: PostRowViewModel
    
    @State private var showConfirmationDialog = false
    
    @EnvironmentObject private var factory: ViewModelFactory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                AuthorView(author: viewModel.author)
                Spacer()
                Text(viewModel.timestamp.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
            }
            .foregroundColor(.gray)
            if let imageURL = viewModel.imageURL {
                PostImage(url: imageURL)
            }
            Text(viewModel.title)
                .font(.title3)
                .fontWeight(.semibold)
            Text(viewModel.content)
            HStack {
                FavoriteButton(isFavorite: viewModel.isFavorite, action: {
                    viewModel.favoritePost()
                })
                Spacer()
                if viewModel.canDeletePost {
                    Button(role: .destructive, action: {
                        showConfirmationDialog = true
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .labelStyle(.iconOnly)
        }
        .padding()
        .confirmationDialog("Are you sure you want to delete this post?",
                            isPresented: $showConfirmationDialog, 
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive, action:  {
                viewModel.deletePost()
            })
        }
        .alert("Cannot Delete Post", error: $viewModel.error)
    }
    
}

private extension PostRow {
    struct AuthorView: View {
        let author: User
        
        @EnvironmentObject private var factory: ViewModelFactory
        
        var body: some View {
            NavigationLink {
                PostsList(viewModel: factory.makePostsViewModel(filter: .author(author)))
            } label: {
                HStack {
                    ProfileImage(url: author.imageURL)
                        .frame(width: 32, height: 32)
                    Text(author.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
    }
}

private extension PostRow {
    struct FavoriteButton: View {
        let isFavorite: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                if isFavorite {
                    Label("Remove from Favorites", systemImage: "heart.fill")
                } else {
                    Label("Add to Favorites", systemImage: "heart")
                }
            }
            .foregroundColor(isFavorite ? .red : .gray)
            .animation(.default, value: isFavorite)
        }
    }
}

private extension PostRow {
    struct PostImage: View {
        let url: URL
        
        var body: some View {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } placeholder: {
                Color.clear
            }
        }
    }
}


struct PostRow_Previews: PreviewProvider {
    static var previews: some View {
            PostRow(viewModel: PostRowViewModel(post: Post.testPost, deleteAction: {}, favoriteAction: {}))
                .environmentObject(ViewModelFactory.preview)
                .previewLayout(.sizeThatFits)
    }
}
