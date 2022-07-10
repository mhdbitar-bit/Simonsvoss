//
//  ListViewController.swift
//  Simonsvoss
//
//  Created by Mohammad Bitar on 7/10/22.
//

import UIKit
import Combine

final class ListViewController: UITableViewController, Alertable {
    
    private var searchController: UISearchController!
    private var viewModel: ListViewModel!
    private var cancellables: Set<AnyCancellable> = []
    private var resultsTableController: ResultsTableController!
    private var isSearchable: Bool = false
    
    private var items = [ItemViewModel]() {
        didSet { tableView.reloadData() }
    }
    
    convenience init(viewModel: ListViewModel) {
        self.init()
        self.viewModel = viewModel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = viewModel.title
        tableView.register(UINib(nibName: ItemTableViewCell.ID, bundle: nil), forCellReuseIdentifier: ItemTableViewCell.ID)
        
        resultsTableController = ResultsTableController()
        
        searchController = UISearchController(searchResultsController: resultsTableController)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search..."
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.delegate = self

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        
        setupRefreshControl()
        bind()
        
        if tableView.numberOfRows(inSection: 0) == 0 {
            refresh()
        }
    }
    
    private func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }
    
    private func setupSearchController() {
        
    }
    
    @objc private func refresh() {
        viewModel.loadItems()
    }
    
    private func bind() {
        bindLoading()
        bindError()
        bindItems()
    }
    
    private func bindLoading() {
        viewModel.$isLoading.sink { [weak self] isLoading in
            if isLoading {
                self?.refreshControl?.beginRefreshing()
            } else {
                self?.refreshControl?.endRefreshing()
            }
        }.store(in: &cancellables)
    }
    
    private func bindItems() {
        viewModel.$items.sink { [weak self] items in
            guard let self = self else { return }
            self.items = items
        }.store(in: &cancellables)
    }
    
    private func bindError() {
        viewModel.$error.sink { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.showAlert(message: error)
            }
        }.store(in: &cancellables)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return ItemCellController(model: items[indexPath.row]).view(tableView)
    }
}

// MARK: - UISearchBarDelegate

extension ListViewController: UISearchBarDelegate {
        
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let searchResults = items
        let text = searchText.lowercased()
        
        let filteredResults = searchResults.filter { item in
            let lockName = item.lockName.lowercased().prefix(text.count)
            let shortCut = item.buildingShortcut.lowercased().prefix(text.count)
            let floor = item.floor.lowercased().prefix(text.count)
            let roomNumber = item.roomNumber.lowercased().prefix(text.count)
            let buildingName = item.buildingName.lowercased().prefix(text.count)
            
            if lockName == text || shortCut == text || floor == text || roomNumber == text || buildingName == text {
                return true
            } else {
                return false
            }
        }
        
        // Apply the filtered results to the search results table.
        if let resultsController = searchController.searchResultsController as? ResultsTableController {
            resultsController.filteredItems = filteredResults
            resultsController.searchText = searchText.lowercased()
            resultsController.tableView.reloadData()
        }
    }
}
