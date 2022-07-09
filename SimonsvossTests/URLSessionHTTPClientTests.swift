@testable import Simonsvoss
import XCTest

typealias HTTPClientResult = Result<(Data, HTTPURLResponse), Error>

class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        completion(.failure(NSError(domain: "any", code: 0)))
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    
    func test_getFromURL_performsGETRequestWithURL() {
        URLProtocolStub.startInterceptingRequests()
        
        let url = URL(string: "http://any-url.com")!
        let sut = URLSessionHTTPClient(session: .shared)
        
        let exp = expectation(description: "Wait for request")
        
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
        }
        
        sut.get(from: url) { _ in
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        
        URLProtocolStub.stopInterceptingRequests()
    }
}
