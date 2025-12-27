//
//  AlbumSelectionView.swift
//  Declutter
//
//  Created by Antigravity on 2025/12/05.
//

import SwiftUI
import Photos

struct AlbumSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var albums: [PHAssetCollection] = []
    let onAlbumSelected: (PHAssetCollection) -> Void
    
    private let photoService = PhotoService()
    
    var body: some View {
        NavigationView {
            List(albums, id: \.localIdentifier) { album in
                Button(action: {
                    onAlbumSelected(album)
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                            .foregroundColor(.blue)
                        Text(album.localizedTitle ?? "未命名相簿")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(album.estimatedAssetCount)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("选择相簿")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadAlbums()
            }
        }
    }
    
    private func loadAlbums() {
        self.albums = photoService.fetchUserAlbums()
    }
}
