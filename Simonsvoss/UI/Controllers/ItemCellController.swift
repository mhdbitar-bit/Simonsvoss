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
    
    func view(_ tableView: UITableView, searchText: String = "") -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ItemTableViewCell.ID) as! ItemTableViewCell
        cell.lockNameLabel.text = model.lockName
        cell.shortcutLabel.text = model.buildingShortcut
        cell.floorLabel.text = model.floor
        cell.roomNumberLabel.text = model.roomNumber
        
        handleHighlightEffect(searchText, cell)
        
        return cell
    }
    
    private func handleHighlightEffect(_ searchText: String, _ cell: ItemTableViewCell) {
        if !searchText.isEmpty {
            if let lockNameLabelText = cell.lockNameLabel.text {
                let name = lockNameLabelText.lowercased().prefix(searchText.count)
                
                cell.lockNameLabel.backgroundColor = (name == searchText) ? .systemYellow : .clear
            }
            
            if let shortcutLabelText = cell.shortcutLabel.text {
                let shortCut = shortcutLabelText.lowercased().prefix(searchText.count)
                
                cell.shortcutLabel.backgroundColor = (shortCut == searchText) ? .systemYellow : .clear
            }
            
            if let floorLabelText = cell.floorLabel.text {
                let floor = floorLabelText.lowercased().prefix(searchText.count)
                
                cell.floorLabel.backgroundColor = (floor == searchText) ? .systemYellow : .clear
            }
            
            if let roomNumberLabel = cell.roomNumberLabel.text {
                let room = roomNumberLabel.lowercased().prefix(searchText.count)
                
                cell.roomNumberLabel.backgroundColor = (room == searchText) ? .systemYellow : .clear
            }
        }
    }
}
