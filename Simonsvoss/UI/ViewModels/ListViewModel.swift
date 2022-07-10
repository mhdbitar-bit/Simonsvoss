//
//  ListViewModel.swift
//  Simonsvoss
//
//  Created by Mohammad Bitar on 7/10/22.
//

import Foundation
import Combine

final class ListViewModel {
    
    let title = "Items"
    @Published var items: [ItemViewModel] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    
    let loader: RemoteLoader
    
    init(loader: RemoteLoader) {
        self.loader = loader
    }
    
    func loadItems() {
        isLoading = true
        loader.load { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading = false
            
            switch result {
            case let .success(item):
                self.items = self.adapteItemToViewModel(item)
                
            case let .failure(error):
                self.error = error.localizedDescription
            }
        }
    }
    
    /// Transform item into a representable ViewModel
    private func adapteItemToViewModel(_ item: Item) -> [ItemViewModel] {
        let locks = item.locks
        let buildings = item.buildings
        var items: [ItemViewModel] = []
        
        locks.forEach { lock in
            if let building = buildings.first(where: { $0.id == lock.buildingId }) {
                items.append(ItemViewModel(
                    lockName: lock.name,
                    buildingShortcut: building.shortCut,
                    floor: lock.floor,
                    roomNumber: lock.roomNumber
                ))
            }
        }
        return items
    }
}
