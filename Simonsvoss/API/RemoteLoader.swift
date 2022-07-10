//
//  RemoteLoader.swift
//  Simonsvoss
//
//  Created by Mohammad Bitar on 7/9/22.
//

import Foundation

final class RemoteLoader: ItemLoader {
    typealias Result = ItemLoader.Result
    
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

    func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case let (.success((data, response))):
                completion(self.map(data, from: response))
                
            case .failure:
                completion(.failure(Error.connecitivy))
            }
        }
    }
    
    private func map(_ data: Data, from response: HTTPURLResponse) -> Result {
        do {
            return .success(try ItemMapper.map(data, from: response))
        } catch {
            return .failure(Error.invalidData)
        }
    }
}
