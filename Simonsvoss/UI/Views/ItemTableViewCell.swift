//
//  ItemTableViewCell.swift
//  Simonsvoss
//
//  Created by Mohammad Bitar on 7/10/22.
//

import UIKit

final class ItemTableViewCell: UITableViewCell {
    @IBOutlet private(set) var lockNameLabel: UILabel!
    @IBOutlet private(set) var metaLabel: UILabel!
    
    static let ID = "ItemTableViewCell"
}
