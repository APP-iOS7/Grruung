//
//  GRCharacter.swift
//  Grruung
//
//  Created by mwpark on 5/1/25.
//

import SwiftUICore

struct GRCharacter: Identifiable, Hashable {
    let id: UUID = UUID()
    var species: String
    var name: String
    var imageName: String
    var birthDate: Date
    
    var characterUUID: UUID {
        return id
    }
    
    static func == (lhs: GRCharacter, rhs: GRCharacter) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    init(species: String, name: String, imageName: String, birthDate: Date = Date()) {
        self.species = species
        self.name = name
        self.imageName = imageName
        self.birthDate = birthDate
    }
}
