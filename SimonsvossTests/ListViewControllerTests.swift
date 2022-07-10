@testable import Simonsvoss
import XCTest
import UIKit

final class ListViewControllerTests: XCTestCase {

    func test_loadItemsActions_requestItemsFromLoader() {
        let (sut, loader) = makeSUT()

        XCTAssertEqual(loader.loadCallCount, 0, "Expected no loading requests before view is loaded")

        sut.loadViewIfNeeded()
        XCTAssertEqual(loader.loadCallCount, 1, "Expected a loading request once view is loaded")

        sut.simulateUserInitiatedResourceReload()
        XCTAssertEqual(loader.loadCallCount, 2, "Expected another loading request once user initiates a reload")

        sut.simulateUserInitiatedResourceReload()
        XCTAssertEqual(loader.loadCallCount, 3, "Expected yet another loading request once user initiates another reload")
    }
    
    func test_loadItemsActions_isVisibleWhileLoadingItems() {
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once view is loaded")
        
        loader.completeItemsLoading(at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once loading completes successfuly")
        
        sut.simulateUserInitiatedResourceReload()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once user initiates a reload")
        
        loader.completeItemsWithError(at: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once user initiated loading completes with error")
    }
    
    func test_loadItemsCompletion_rendersSuccessfullyloadedItems() {
        let id1 = UUID()
        let building1 = makeBuilding(id: id1, shortCut: "a shortCut", name: "a name", description: "a description")
        let lock1 = makeLock(id: UUID(), buildingId: id1, type: "a type", name: "a name", description: "a description", serialNumber: "a serial number", floor: "a floor", roomNumber: "a room number")
        let group1 = makeGroup(id: UUID(), name: "a name", description: "a description")
        let media1 = makeMedia(id: UUID(), groupId: UUID(), type: "a type", owner: "an owner", description: "a description", serialNumber: "a serial number")
        
        let id2 = UUID()
        let building2 = makeBuilding(id: id2, shortCut: "another shortCut", name: "another name", description: "another description")
        let lock2 = makeLock(id: UUID(), buildingId: id2, type: "another type", name: "another name", description: "another description", serialNumber: "another serial number", floor: "another floor", roomNumber: "another room number")
        let group2 = makeGroup(id: UUID(), name: "another name", description: "another description")
        let media2 = makeMedia(id: UUID(), groupId: UUID(), type: "another type", owner: "an owner", description: "another description", serialNumber: "another serial number")
        
        let item1 = Item(buildings: [building1], locks: [lock1], groups: [group1], media: [media1])
        let item2 = Item(buildings: [building1, building2], locks: [lock1, lock2], groups: [group1, group2], media: [media1, media2])
        
        let itemViewModel1 = ItemViewModel(lockName: lock1.name, buildingShortcut: building1.shortCut, floor: lock1.floor, roomNumber: lock1.roomNumber)
        let itemViewModel2 = ItemViewModel(lockName: lock2.name, buildingShortcut: building2.shortCut, floor: lock2.floor, roomNumber: lock2.roomNumber)
        
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        assertThat(sut, isRendering: [])
        
        loader.completeItemsLoading(with: item1, at: 0)
        assertThat(sut, isRendering: [itemViewModel1])
        
        sut.simulateUserInitiatedResourceReload()
        loader.completeItemsLoading(with: item2, at: 1)
        assertThat(sut, isRendering: [itemViewModel1, itemViewModel2])
    }
    
    func test_loadItemsCompletion_doesNotAlertCurrentRenderingStateOnError() {
        let id1 = UUID()
        let building1 = makeBuilding(id: id1, shortCut: "a shortCut", name: "a name", description: "a description")
        let lock1 = makeLock(id: UUID(), buildingId: id1, type: "a type", name: "a name", description: "a description", serialNumber: "a serial number", floor: "a floor", roomNumber: "a room number")
        let group1 = makeGroup(id: UUID(), name: "a name", description: "a description")
        let media1 = makeMedia(id: UUID(), groupId: UUID(), type: "a type", owner: "an owner", description: "a description", serialNumber: "a serial number")
        
        let item1 = Item(buildings: [building1], locks: [lock1], groups: [group1], media: [media1])
        
        let itemViewModel1 = ItemViewModel(lockName: lock1.name, buildingShortcut: building1.shortCut, floor: lock1.floor, roomNumber: lock1.roomNumber)
        
        
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeItemsLoading(with: item1, at: 0)
        assertThat(sut, isRendering: [itemViewModel1])
        
        sut.simulateUserInitiatedResourceReload()
        loader.completeItemsWithError(at: 1)
        assertThat(sut, isRendering: [itemViewModel1])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: ListViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let viewModel = ListViewModel(loader: loader)
        let sut = ListViewController(viewModel: viewModel)
        trackForMemoryLeacks(loader, file: file, line: line)
        trackForMemoryLeacks(sut, file: file, line: line)
        return (sut, loader)
    }
    
    private func assertThat(_ sut: ListViewController, isRendering items: [ItemViewModel], file: StaticString = #filePath, line: UInt = #line) {
        guard sut.numberOfRenderedResourceViews() == items.count else {
            return XCTFail("Expected \(items.count) items, got \(sut.numberOfRenderedResourceViews()) instead", file: file, line: line)
        }
        
        items.enumerated().forEach { index, item in
            assertThat(sut, hasViewConfiguredFor: item, at: index, file: file, line: line)
        }
    }
    
    private func assertThat(_ sut: ListViewController, hasViewConfiguredFor item: ItemViewModel, at index: Int, file: StaticString = #filePath, line: UInt = #line) {
        let view = sut.view(at: index) as? ItemTableViewCell
        
        guard let cell = view else {
            return XCTFail("Expected \(UITableViewCell.self) instance, got \(String(describing: view)) instead", file: file, line: line)
        }

        XCTAssertEqual(cell.lockNameLabel.text, item.lockName, "Expected lock name text to be \(String(describing: item.lockName)) for item view at index \(index)", file: file, line: line)
                
        XCTAssertEqual(cell.metaLabel.text, "\(item.buildingShortcut) - \(item.floor) - \(item.roomNumber)", "Expected meta items to be \(String(describing: item.buildingShortcut)), \(String(describing: item.floor)) and \(String(describing: item.roomNumber)) for item view at index \(index)", file: file, line: line)
    }

    class LoaderSpy: ItemLoader {
        typealias Result = RemoteLoader.Result

        private var completions = [(Result) -> Void]()

        var loadCallCount: Int {
            return completions.count
        }
        
        func load(completion: @escaping (Result) -> Void) {
            completions.append(completion)
        }
        
        func completeItemsLoading(with item: Item = Item(buildings: [], locks: [], groups: [], media: []), at index: Int = 0) {
            completions[index](.success(item))
        }
        
        func completeItemsWithError(at index: Int = 0) {
            let error = NSError(domain: "an error", code: 0)
            completions[index](.failure(error))
        }
    }
}

private extension UITableViewController {

    func simulateUserInitiatedResourceReload() {
        refreshControl?.simulatePullToRefresh()
    }
    
    var isShowingLoadingIndicator: Bool {
        return refreshControl?.isRefreshing == true
    }
    
    func numberOfRenderedResourceViews() -> Int {
        return tableView.numberOfRows(inSection: resourceSection)
    }
    
    private var resourceSection: Int {
        return 0
    }
    
    func view(at row: Int) -> UITableViewCell? {
        let ds = tableView.dataSource
        let index = IndexPath(row: row, section: resourceSection)
        return ds?.tableView(tableView, cellForRowAt: index)
    }
}

private extension UIRefreshControl {
    func simulatePullToRefresh() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach { (target as NSObject).perform(Selector($0))
            }
        }
    }
}
