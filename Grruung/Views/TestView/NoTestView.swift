//
//  TestView.swift
//  Grruung
//
//  Created by NoelMacMini on 5/1/25.
//

import SwiftUI

struct NoTestView: View {
    
    let charUUID: String = "CF6NXxcH5HgGjzVE0nVE"
    
    var body: some View {
        NavigationStack {
            NavigationLink(destination: CharacterDetailView(characterUUID: charUUID)) { // 임시 더미 characterUUID
                Text("Go to Character Detail")
            }
            
            NavigationLink(destination: WriteStoryView(currentMode: .create, characterUUID: charUUID)) {
                Text("Go to WriteStory Create")
            }
        }
    }
}

#Preview {
    NoTestView()
}
