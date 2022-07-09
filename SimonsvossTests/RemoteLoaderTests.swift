@testable import Simonsvoss
import XCTest

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

final class RemoteLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let (sut, client) = makeSUT()
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [anyURL()])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let (sut, client) = makeSUT()
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [anyURL(), anyURL()])
    }
    
    func test_load_deliversConnectivityErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(.connecitivy)) {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        }
    }
    
    func test_load_deliversInvalidDataErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 500]
        
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: .failure(.invalidData)) {
                let json = makeItemsJSON([:])
                client.complete(withStatusCode: code, data: json, at: index)
            }
        }
    }
    
    func test_load_deliversInvalidDataErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(.invalidData)) {
            let json = Data("invalid json".utf8)
            client.complete(withStatusCode: 200, data: json)
        }
    }
    
    func test_load_deliversSuccessWithNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()
        
        let item = Item(buildings: [], locks: [], groups: [], media: [])
        
        expect(sut, toCompleteWith: .success(item), when: {
            let emptyListJSON = makeItemsJSON(["buildings": [], "locks": [], "groups": [], "media": []])
            client.complete(withStatusCode: 200, data: emptyListJSON)
        })
    }
    
    // MARK: - Helpers
    
    private func makeSUT(url: URL = anyURL(), file: StaticString = #filePath, line: UInt = #line) -> (sut: RemoteLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteLoader(url: url, client: client)
        return (sut, client)
    }
    func expect(_ sut: RemoteLoader, toCompleteWith expectedResult: Result<Item, RemoteLoader.Error>, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for load completion")

        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems.buildings, expectedItems.buildings, file: file, line: line)
                XCTAssertEqual(receivedItems.locks, expectedItems.locks, file: file, line: line)
                XCTAssertEqual(receivedItems.groups, expectedItems.groups, file: file, line: line)
                XCTAssertEqual(receivedItems.media, expectedItems.media, file: file, line: line)
                
            case let (.failure(receivedError), .failure(expectedError)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
                
            default:
                XCTFail("Expected result \(expectedResult) got \(receivedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        
        waitForExpectations(timeout: 0.1)
    }
    
//    private func makeBuilding(id: UUID, shortCut: String, name: String, description: String) -> Building {
//        return Building(
//            id: id,
//            shortCut: shortCut,
//            name: name,
//            description: description
//        )
//    }
//
//    private func makeLock(id: UUID, buildingId: UUID, type: String, name: String, description: String?, serialNumber: String, floor: String, roomNumber: String) -> Lock {
//        return Lock(
//            id: id,
//            buildingId: buildingId,
//            type: type,
//            name: name,
//            description: description,
//            serialNumber: serialNumber,
//            floor: floor,
//            roomNumber: roomNumber
//        )
//    }
//
//    private func makeGroup(id: UUID, name: String, description: String?) -> Group {
//        return Group(
//            id: id,
//            name: name,
//            description: description
//        )
//    }
//
//    private func makeMedia(id: UUID, groupId: UUID, type: String, owner: String, description: String?, serialNumber: String) -> Media {
//        return Media(
//            id: id,
//            groupId: groupId,
//            type: type,
//            owner: owner,
//            description: description,
//            serialNumber: serialNumber
//        )
//    }
    
    private func makeItem(building: Building, lock: Lock, group: Group, media: Media) -> (model: Item, json: [String: Any]) {
        
        let json: [String: Any] = [
            "buildings": [[
                "id": building.id,
                "shortCut": building.shortCut,
                "name": building.name,
                "description": building.description
            ]],
            "locks": [[
                "id": lock.id,
                "buildingId": lock.buildingId,
                "type": lock.type,
                "name": lock.name,
                "description": lock.description as Any,
                "serialNumber": lock.serialNumber,
                "floor": lock.floor,
                "roomNumber": lock.roomNumber
            ].compactMap { $0 }],
            "groups": [[
                "id": group.id,
                "name": group.name,
                "description": group.description as Any
            ].compactMap { $0 }],
            "media": [[
                "id": media.id,
                "groupId": media.groupId,
                "type": media.type,
                "owner": media.owner,
                "description": media.description as Any,
                "serialNumber": media.serialNumber
            ].compactMap { $0 }]
        ]
        
        let item = Item(buildings: [building], locks: [lock], groups: [group], media: [media])
        
        return (item, json)
    }
    
    class HTTPClientSpy: HTTPClient {
        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            messages[index].completion(.success((data, response)))
        }
    }
    
    private func makeItemsJSON(_ items: [String: Any]) -> Data {
        return try! JSONSerialization.data(withJSONObject: items)
    }
}
