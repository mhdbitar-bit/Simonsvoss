@testable import Simonsvoss
import XCTest

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
        let id1 = UUID()
        
        let buildin1 = makeBuilding(id: id1, shortCut: "a shortCut", name: "a name", description: "a description")
        
        let lock1 = makeLock(id: UUID(), buildingId: id1, type: "a type", name: "a name", description: "a description", serialNumber: "a serial number", floor: "a floor", roomNumber: "a room number")
        
        let groupId1 = UUID()
        let group1 = makeGroup(id: groupId1, name: "a name", description: "a description")
        
        let media1 = makeMedia(id: UUID(), groupId: groupId1, type: "a type", owner: "an owner", description: "a description", serialNumber: "a serial number")
        
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
        trackForMemoryLeacks(client, file: file, line: line)
        trackForMemoryLeacks(sut, file: file, line: line)
        return (sut, client)
    }
    
    func expect(_ sut: RemoteLoader, toCompleteWith expectedResult:
                Swift.Result<Item, RemoteLoader.Error>, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for load completion")

        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems.buildings, expectedItems.buildings, file: file, line: line)
                XCTAssertEqual(receivedItems.locks, expectedItems.locks, file: file, line: line)
                XCTAssertEqual(receivedItems.groups, expectedItems.groups, file: file, line: line)
                XCTAssertEqual(receivedItems.media, expectedItems.media, file: file, line: line)
            
            case let (.failure(receivedError), .failure(expectedError)):
                XCTAssertEqual(receivedError as! RemoteLoader.Error, expectedError, file: file, line: line)
                
            default:
                XCTFail("Expected result \(expectedResult) got \(receivedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        
        waitForExpectations(timeout: 0.1)
    }
}
