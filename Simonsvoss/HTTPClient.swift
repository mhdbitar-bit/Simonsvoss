//
//  HTTPClient.swift
//  Simonsvoss
//
//  Created by Mohammad Bitar on 7/9/22.
//

import Foundation

protocol HTTPClient {
    typealias HTTPClientResult = Result<(Data, HTTPURLResponse), Error>
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
