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
    
    private var items = [ItemViewModel]() {
        didSet { tableView.reloadData() }
    }
    
    convenience init(viewModel: ListViewModel) {
        self.init()
        self.viewModel = viewModel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultsTableController = ResultsTableController()
        tableView.register(UINib(nibName: ItemTableViewCell.ID, bundle: nil), forCellReuseIdentifier: ItemTableViewCell.ID)
        
        setupSearchController()
        setupNavigationController()
        setupRefreshControl()
        bind()
        
        if tableView.numberOfRows(inSection: 0) == 0 {
            refresh()
        }
    }
    
    private func setupNavigationController() {
        navigationItem.title = viewModel.title
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    
    private func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }
    
    private func setupSearchController() {
        searchController = UISearchController(searchResultsController: resultsTableController)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search..."
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.delegate = self
    }
    
    @objc private func refresh() {
        viewModel.loadItems()
    }
}

// MARK: - Binded functions

extension ListViewController {
    
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
}

// MARK: - UITableView

extension ListViewController {
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
        let filteredResults = findMatches(items, searchText.lowercased())
        reloadFilteredItems(filteredResults, searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
    }
    
    private func findMatches(_ searchResults: [ItemViewModel], _ text: String) -> [ItemViewModel] {
        return searchResults.filter { item in
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
    }
    
    private func reloadFilteredItems(_ filteredResults: [ItemViewModel], _ searchText: String) {
        if let resultsController = searchController.searchResultsController as? ResultsTableController {
            resultsController.filteredItems = filteredResults
            resultsController.searchText = searchText.lowercased()
            resultsController.tableView.reloadData()
        }
    }
}
