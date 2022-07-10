//
//  MainQueueDispatchDecorator.swift
//  Simonsvoss
//
//  Created by Mohammad Bitar on 7/10/22.
//

import Foundation

final class MainQueueDispatchDecorator<T> {
    private let decoratee: T
    
    init(decoratee: T) {
        self.decoratee = decoratee
    }
    
    func dispatch(completion: @escaping () -> Void) {
        if Thread.isMainThread {
            completion()
        } else {
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}

extension MainQueueDispatchDecorator: ItemLoader where T == ItemLoader {
    
    func load(completion: @escaping (ItemLoader.Result) -> Void) {
        decoratee.load { [weak self] result in
            self?.dispatch {
                completion(result)
            }
        }
    }
}
