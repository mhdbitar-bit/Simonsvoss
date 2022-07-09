//
//  RemoteLoader.swift
//  Simonsvoss
//
//  Created by Mohammad Bitar on 7/9/22.
//

import Foundation

struct Group: Equatable {
    let id: UUID
    let name: String
    let description: String
}

struct Media: Equatable {
    let id: UUID
    let groupId: UUID
    let type: String
    let owner: String
    let description: String
    let serialNumber: String
}

final class RemoteLoader {
    private let url: URL
    private let client: HTTPClient
    
    enum Error: Swift.Error {
        case connecitivy
        case invalidData
    }

    init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    func load(completion: @escaping (Result<Item, Error>) -> Void) {
        client.get(from: url) { result in
            switch result {
            case let (.success((data, response))):
                if let item = try? ItemMapper.map(data, from: response) {
                    completion(.success(item))
                } else {
                    completion(.failure(.invalidData))
                }
                
            case .failure:
                completion(.failure(.connecitivy))
            }
        }
    }
}
