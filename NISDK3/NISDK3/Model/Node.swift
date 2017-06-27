//
//  Node.swift
//  NISDK3
//
//  Created by Aram Moon on 2017. 6. 7..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation

class Node {
    var x: Float = 0.0
    var y: Float = 0.0
    var pressure: Float = 0.0
    var timeDiff: UInt8 = 0
    
    init(pointX x: Float, poinY y: Float, pressure: Float) {
        self.x = x
        self.y = y
        self.pressure = pressure
    }
}
