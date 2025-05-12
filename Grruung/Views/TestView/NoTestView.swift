//
//  TestView.swift
//  Grruung
//
//  Created by NoelMacMini on 5/1/25.
//

import SwiftUI

struct NoTestView: View {
    var body: some View {
        NavigationStack {
            NavigationLink(destination: CharacterDetailView(characterUUID: "1234")) { // 임시 더미 characterUUID
                Text("Go to Character Detail")
            }
        }
    }
}

#Preview {
    NoTestView()
}
