//
//  DeviceProtocol.swift
//  NDeviceSDK
//
//  Created by Aram Moon on 2017. 6. 26..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation
import CoreBluetooth

/// Device Callback Delegate
public protocol DeviceDelegate : class {
    
    /// device Message
    /// Message have Type and Data
    func deviceMessage(_ msg: DeviceMessage)
    
    /// Bluetooth Status
    func bluetoothStatus(_ status: BTStatus, _ peripheral: CBPeripheral?)
}





