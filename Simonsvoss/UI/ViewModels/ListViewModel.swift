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
    @Published var categories: [ItemViewModel] = []
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
            case let .success(items):
                // TODO handle items here
                
            case let .failure(error):
                // TODO handle errors here
            }
        }
    }
}
