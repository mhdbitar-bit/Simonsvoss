//
//  HTTPClientSpy.swift
//  SimonsvossTests
//
//  Created by Mohammad Bitar on 7/9/22.
//

@testable import Simonsvoss
import Foundation

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
