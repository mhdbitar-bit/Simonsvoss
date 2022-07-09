//
//  Item.swift
//  Simonsvoss
//
//  Created by Mohammad Bitar on 7/9/22.
//

import Foundation

struct Item: Equatable {
    let buildings: [Building]
    let locks: [Lock]
    let groups: [Group]
    let media: [Media]
}
