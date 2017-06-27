//
//  CMD.swift
//  NISDK3
//
//  Created by Aram Moon on 2017. 6. 8..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation

public class PenMessage{
    
    public var messageType : PenMessageType!
    public var data : Any?
    
    convenience init(_ penMessageType: PenMessageType , data: Any?) {
        self.init()
        messageType = penMessageType
        self.data = data
    }
    
}
