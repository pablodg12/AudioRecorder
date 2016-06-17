//
//  Contador.swift
//  RecordAndPlay
//
//  Created by Pablo on 6/16/16.
//  Copyright © 2016 Nimble Chapps. All rights reserved.
//

import Foundation

class Counter {
    var count = 0
    func increment() {
        count += 1
    }
    func incrementBy(amount: Int) {
        count += amount
    }
    func reset() {
        count = 0
    }
    func set(amount: Int){
        count = amount
    }
}