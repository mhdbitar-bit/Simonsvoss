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
    
    func test_load_deliversSuccessWithItemsOn200HTTPResponseWithJSONItems() {
        let (sut, client) = makeSUT()
        
        let buildin1 = makeBuilding(id: UUID(), shortCut: "a shortCut", name: "a name", description: "a description")
        
        let lock1 = makeLock(id: UUID(), buildingId: UUID(), type: "a type", name: "a name", description: "a description", serialNumber: "a serial number", floor: "a floor", roomNumber: "a room number")
        
        let group1 = makeGroup(id: UUID(), name: "a name", description: "a description")
        
        let media1 = makeMedia(id: UUID(), groupId: UUID(), type: "a type", owner: "an owner", description: "a description", serialNumber: "a serial number")
        
        let item = makeItem(building: buildin1, lock: lock1, group: group1, media: media1)
        
        expect(sut, toCompleteWith: .success(item.model), when: {
            let json = makeItemsJSON(item.json)
            client.complete(withStatusCode: 200, data: json)
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
}
