//
//  ItemCellController.swift
//  Simonsvoss
//
//  Created by Mohammad Bitar on 7/10/22.
//

import UIKit

final class ItemCellController {
    private let model: ItemViewModel
    
    init(model: ItemViewModel) {
        self.model = model
    }
    
    func view(_ tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ItemTableViewCell.ID) as! ItemTableViewCell
        cell.lockNameLabel.text = model.lockName
        cell.metaLabel.text = model.buildingShortcut + " - " + model.floor + " - " + model.roomNumber
        return cell
    }
}