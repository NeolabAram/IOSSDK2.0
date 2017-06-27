//
//  PenProtocol.swift
//  NISDK3
//
//  Created by Aram Moon on 2017. 6. 7..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation
import CoreBluetooth

public protocol PenDelegate : class {
    /// Pen Data, UpDown, PageID
    func penData(_ type : DotType, _ data: Any?)
    /// Pen Status
    func penMessage(_ msg: PenMessage)
    /// Pen Bluetooth Status
    func penBluetooth(_ status: PenStatus, _ data: Any?)
}

let PACKET_START: UInt8 = 0xc0
let PACKET_END: UInt8 = 0xc1
let PACKET_DLE: UInt8 = 0x7d
let PACKET_MAX_LEN = 32000

// Only USE Protocol V2
enum CMD : UInt8 {
    case VERSION_INFO = 0x01
    case COMPARE_PWD = 0x02
    case CHANGE_PWD = 0x03
    case PEN_STATE = 0x04
    case SET_PEN_STATE = 0x05
    case SET_NOTE_LIST = 0x11
    case REQ1_OFFLINE_NOTE_LIST = 0x21
    case REQ2_OFFLINE_PAGE_LIST = 0x22
    case REQ1_OFFLINE_DATA = 0x23
    case REQ2_OFFLINE_DATA = 0x24
    case REQ_DEL_OFFLINE_DATA = 0x25
    case REQ1_FW_FILE = 0x31
    case RES2_FW_FILE = 0xb2
    
    case EVENT_BATT_ALARM = 0x61
    case EVENT_POWER_OFF = 0x62
    case EVENT_PEN_UPDOWN = 0x63
    case EVENT_PEN_NEWID = 0x64
    /// Full Dot Data
    case EVENT_PEN_DOTCODE = 0x65
    case EVENT_PEN_DOTCODE2 = 0x66
    case EVENT_PEN_DOTCODE3 = 0x67
    case RES_VERSION_INFO = 0x81
    case RES_COMPARE_PWD = 0x82
    case RES_CHANGE_PWD = 0x83
    case RES_PEN_STATE = 0x84
    case RES_SET_PEN_STATE = 0x85
    case RES_SET_NOTE_LIST = 0x91
    case RES1_OFFLINE_NOTE_LIST = 0xa1
    case RES2_OFFLINE_PAGE_LIST = 0xa2
    case RES1_OFFLINE_DATA_INFO = 0xa3
    case RES2_OFFLINE_DATA = 0xa4
    case RES_DEL_OFFLINE_DATA = 0xa5
    case RES1_FW_FILE = 0xb1
    case REQ2_FW_FILE = 0x32
}

public enum OnOff: UInt8{
    case Off = 0
    case On = 1
    case Ignore = 9
    
    func rawValueV1()->UInt8{
        switch self {
        case .Ignore:
            return 0
        case .On:
            return 1
        case .Off:
            return 2
        }
    }
    
    static func value(ProtoColV1 rawvalue: UInt8) -> OnOff{
        if rawvalue == 1{
            return .On
        } else if rawvalue == 2{
            return .Off
        }
        return .Ignore
    }
}
