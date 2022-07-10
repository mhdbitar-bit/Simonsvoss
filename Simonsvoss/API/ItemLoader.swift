//
//  ItemLoader.swift
//  Simonsvoss
//
//  Created by Mohammad Bitar on 7/10/22.
//

import Foundation

protocol ItemLoader {
    typealias Result = Swift.Result<Item, Error>
    
    func load(completion: @escaping (Result) -> Void)
}
