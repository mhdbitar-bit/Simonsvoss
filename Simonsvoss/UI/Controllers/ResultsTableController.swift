//
//  ResultsTableController.swift
//  Simonsvoss
//
//  Created by Mohammad Bitar on 7/10/22.
//

import UIKit

final class ResultsTableController: UITableViewController {
    
    var filteredItems = [ItemViewModel]()
    var searchText: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: ItemTableViewCell.ID, bundle: nil), forCellReuseIdentifier: ItemTableViewCell.ID)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return ItemCellController(model: filteredItems[indexPath.row]).view(tableView, searchText: searchText)
    }
}
