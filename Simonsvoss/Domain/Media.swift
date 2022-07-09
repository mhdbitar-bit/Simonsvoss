//
//  Media.swift
//  Simonsvoss
//
//  Created by Mohammad Bitar on 7/9/22.
//

import Foundation

struct Media: Equatable {
    let id: UUID
    let groupId: UUID
    let type: String
    let owner: String
    let description: String
    let serialNumber: String
}
