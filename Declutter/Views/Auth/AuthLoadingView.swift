//
//  AuthLoadingView.swift
//  Declutter
//
//  Created by Kiro on 2025-12-06.
//

import SwiftUI

struct AuthLoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("正在登录...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 0.2))
            )
        }
    }
}

#Preview {
    AuthLoadingView()
}
