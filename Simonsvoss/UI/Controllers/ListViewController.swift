//
//  ListViewController.swift
//  Simonsvoss
//
//  Created by Mohammad Bitar on 7/10/22.
//

import UIKit
import Combine

final class ListViewController: UITableViewController, Alertable {
    
    private var viewModel: ListViewModel!
    private var cancellables: Set<AnyCancellable> = []
    
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
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return ItemCellController(model: items[indexPath.row]).view(tableView)
    }
}
