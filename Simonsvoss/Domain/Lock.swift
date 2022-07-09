//
//  Lock.swift
//  Simonsvoss
//
//  Created by Mohammad Bitar on 7/9/22.
//

import Foundation

struct Lock: Equatable {
    let id: UUID
    let buildingId: UUID
    let type: String
    let name: String
    let description: String
    let serialNumber: String
    let floor: String
    let roomNumber: String
}
