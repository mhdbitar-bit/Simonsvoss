//
//  SharedHelpers.swift
//  SimonsvossTests
//
//  Created by Mohammad Bitar on 7/9/22.
//

import Foundation

func anyURL() -> URL {
    return URL(string: "http://any-url.com")!
}

func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 0)
}

func anyData() -> Data {
    Data("any data".utf8)
}

func anyHTTPURLResponse() -> HTTPURLResponse {
    HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
}

func nonHTTPURLResponse() -> URLResponse {
    URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
}

func makeBuilding(id: UUID, shortCut: String, name: String, description: String) -> Building {
    return Building(
        id: id,
        shortCut: shortCut,
        name: name,
        description: description
    )
}

func makeLock(id: UUID, buildingId: UUID, type: String, name: String, description: String, serialNumber: String, floor: String, roomNumber: String) -> Lock {
    return Lock(
        id: id,
        buildingId: buildingId,
        type: type,
        name: name,
        description: description,
        serialNumber: serialNumber,
        floor: floor,
        roomNumber: roomNumber
    )
}

func makeGroup(id: UUID, name: String, description: String) -> Group {
    return Group(
        id: id,
        name: name,
        description: description
    )
}

func makeMedia(id: UUID, groupId: UUID, type: String, owner: String, description: String, serialNumber: String) -> Media {
    return Media(
        id: id,
        groupId: groupId,
        type: type,
        owner: owner,
        description: description,
        serialNumber: serialNumber
    )
}

func makeItem(building: Building, lock: Lock, group: Group, media: Media) -> (model: Item, json: [String: Any]) {
    
    let json = [
        "buildings": [
            [
                "id": building.id.uuidString,
                "shortCut": building.shortCut,
                "name": building.name,
                "description": building.description
            ]
        ],
        "locks": [
            [
                "id": lock.id.uuidString,
                "buildingId": lock.buildingId.uuidString,
                "type": lock.type,
                "name": lock.name,
                "description": lock.description,
                "serialNumber": lock.serialNumber,
                "floor": lock.floor,
                "roomNumber": lock.roomNumber
            ]
        ],
        "groups": [
            [
                "id": group.id.uuidString,
                "name": group.name,
                "description": group.description
            ]
        ],
        "media": [
            [
                "id": media.id.uuidString,
                "groupId": media.groupId.uuidString,
                "type": media.type,
                "owner": media.owner,
                "description": media.description,
                "serialNumber": media.serialNumber
            ]
        ]
    ]
    
    let item = Item(buildings: [building], locks: [lock], groups: [group], media: [media])
    
    return (item, json)
}

func makeItemsJSON(_ items: [String: Any]) -> Data {
    return try! JSONSerialization.data(withJSONObject: items)
}
