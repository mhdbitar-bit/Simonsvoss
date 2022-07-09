//
//  RemoteLoader.swift
//  Simonsvoss
//
//  Created by Mohammad Bitar on 7/9/22.
//

import Foundation

struct Item: Equatable {
    let buildings: [Building]
    let locks: [Lock]
    let groups: [Group]
    let media: [Media]
}

struct Building: Equatable {
    let id: UUID
    let shortCut: String
    let name: String
    let description: String
}

struct Lock: Equatable {
    let id: UUID
    let buildingId: UUID
    let type: String
    let name: String
    let description: String
    let serialNumber: String
    let floor: String
    let roomNumber: String
}

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

final class ItemMapper {
    private struct RemoteItem: Decodable {
        private let buildings: [RemoteBuilding]
        private let locks: [RemoteLock]
        private let groups: [RemoteGroup]
        private let media: [RemoteMedia]
        
        var item: Item {
            return Item(
                buildings: buildings.map { $0.item },
                locks: locks.map { $0.item },
                groups: groups.map { $0.item },
                media: media.map { $0.item }
            )
        }
    
        private struct RemoteBuilding: Decodable {
            let id: UUID
            let shortCut: String
            let name: String
            let description: String
            
            var item: Building {
                return Building(
                    id: id,
                    shortCut: shortCut,
                    name: name,
                    description: description
                )
            }
        }
        
        private struct RemoteLock: Decodable {
            let id: UUID
            let buildingId: UUID
            let type: String
            let name: String
            let description: String?
            let serialNumber: String
            let floor: String
            let roomNumber: String
            
            var item: Lock {
                return Lock(
                    id: id,
                    buildingId: buildingId,
                    type: type,
                    name: name,
                    description: description ?? "",
                    serialNumber: serialNumber,
                    floor: floor,
                    roomNumber: roomNumber
                )
            }
        }
        
        private struct RemoteGroup: Decodable {
            let id: UUID
            let name: String
            let description: String?
            
            var item: Group {
                return Group(
                    id: id,
                    name: name,
                    description: description ?? ""
                )
            }
        }

        private struct RemoteMedia: Decodable {
            let id: UUID
            let groupId: UUID
            let type: String
            let owner: String
            let description: String?
            let serialNumber: String
            
            var item: Media {
                return Media(
                    id: id,
                    groupId: groupId,
                    type: type,
                    owner: owner,
                    description: description ?? "",
                    serialNumber: serialNumber
                )
            }
        }
    }
    
    private enum Error: Swift.Error {
        case invalidData
    }
    
    static func map(_ data: Data, from response: HTTPURLResponse) throws -> Item {
        guard response.statusCode == 200, let root = try? JSONDecoder().decode(RemoteItem.self, from: data) else {
            throw Error.invalidData
        }
        
        return root.item
    }
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
