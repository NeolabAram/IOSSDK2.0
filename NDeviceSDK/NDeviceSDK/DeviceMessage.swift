//
//  DeviceMessage.swift
//  NDeviceSDK
//
//  Created by Aram Moon on 2017. 6. 26..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation

/// callback Message in DeviceDelegate
public class DeviceMessage{
    
    /// MessageType
    public var messageType : MessageType!
    
    /// Data
    public var data : Any?
    
    convenience init(_ type: MessageType , data: Any?) {
        self.init()
        messageType = type
        self.data = data
    }
    
}






