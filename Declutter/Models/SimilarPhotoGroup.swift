//
//  SimilarPhotoGroup.swift
//  Declutter
//
//  Created by Antigravity on 2025/12/05.
//

import Foundation
import Photos

/// Represents a group of visually similar photos
struct SimilarPhotoGroup: Identifiable, Equatable {
    let id: UUID
    let assets: [PhotoAsset]
    var bestShot: PhotoAsset?
    var selectedForDeletion: Set<String>
    
    init(id: UUID = UUID(), assets: [PhotoAsset], bestShot: PhotoAsset? = nil) {
        self.id = id
        self.assets = assets
        self.bestShot = bestShot
        self.selectedForDeletion = []
        
        // Default behavior: if we have a best shot, select all others for deletion
        if let best = bestShot {
            let others = assets.filter { $0.id != best.id }
            self.selectedForDeletion = Set(others.map { $0.id })
        }
    }
    
    static func == (lhs: SimilarPhotoGroup, rhs: SimilarPhotoGroup) -> Bool {
        lhs.id == rhs.id && lhs.selectedForDeletion == rhs.selectedForDeletion
    }
}
