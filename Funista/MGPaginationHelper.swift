//
//  MGPaginationHelper.swift
//  Makestagram
//
//  Created by Mahdia Daqiq on 7/11/17.
//  Copyright © 2017 Mahdia Daqiq. All rights reserved.
//

import Foundation

protocol MGKeyed {
    var key: String? { get set }
}

class MGPaginationHelper<T : MGKeyed> {
    enum MGPaginationState {
        case initial
        case ready
        case loading
        case end
    }
    
    let pageSize: UInt
    let serviceMethod: (UInt, String?, @escaping (([T]) -> Void)) -> Void
    var state: MGPaginationState = .initial
    var lastObjectKey: String?
    
    init(pageSize: UInt = 100, serviceMethod: @escaping (UInt, String?, @escaping (([T]) -> Void)) -> Void) {
        self.pageSize = pageSize
        self.serviceMethod = serviceMethod
    }
    
    func paginate(completion: @escaping ([T]) -> Void) {
        switch state {
        case .initial:
            lastObjectKey = nil
            fallthrough
            
        case .ready:
            state = .loading
            serviceMethod(pageSize, lastObjectKey) { [unowned self] (objects: [T]) in
                defer { //issue might be here
                    if let lastObjectKey = objects.last?.key {
                        self.lastObjectKey = lastObjectKey
                    }
                    
                    self.state = objects.count < Int(self.pageSize) ? .end : .ready
                }
                
                guard let _ = self.lastObjectKey else {
                    return completion(objects)
                }
                
                let newObjects = Array(objects.dropFirst())
                completion(newObjects)
            }
            
        case .loading, .end:
            return
        }
    }
    
    func reloadData(completion: @escaping ([T]) -> Void) {
        state = .initial
        
        paginate(completion: completion)
    }
}
