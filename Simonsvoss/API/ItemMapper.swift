//
//  ItemMapper.swift
//  Simonsvoss
//
//  Created by Mohammad Bitar on 7/9/22.
//

import Foundation

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
    
    private static var OK_200: Int { 200 }
    
    static func map(_ data: Data, from response: HTTPURLResponse) throws -> Item {
        guard response.statusCode == OK_200, let root = try? JSONDecoder().decode(RemoteItem.self, from: data) else {
            throw Error.invalidData
        }
        
        return root.item
    }
}
