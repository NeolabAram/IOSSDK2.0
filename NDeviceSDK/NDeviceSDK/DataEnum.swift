//
//  DataEnum.swift
//  NDeviceSDK
//
//  Created by Aram Moon on 2017. 6. 27..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation

/// Callback Data Type
public enum MessageType: Int{
    /// You can use API, after this message.
    case Autorize = 0x00
    //    case Pairing = 0x01
    /// Updated Contents list, If you get this message, update your contents.
    case Contents = 0x02
    /// Device Powner off, disconnect.
    case PowerOff = 0x03
}

/// Bluetooth Status
public enum BTStatus : Int {
    ///
    case None
    ///
    case ScanStart
    ///
    case StopScan
    ///
    case Discover
    ///
    case Connect
    ///
    case Disconnect
}

/// Remote Controller Command
public enum PlayType: UInt8{
    /// This is Use SDK Internal
    case DirectPlay = 0x00
    /// Play and Pause
    case PlayNPause = 0x01
    /// Volume Up
    case VolumeUp = 0x02
    /// Volume Down
    case VolumeDown = 0x03
    /// Volume 0
    case Mute = 0x04
    /// Sleep
    case Sleep = 0x05
    /// Repeat
    case Repeat = 0x06
    /// Up Key
    case Up = 0x07
    /// Down Key
    case Down = 0x08
    /// Left
    case Left = 0x09
    /// Right
    case Right = 0x0a
    /// Return(Back)
    case Return = 0x0b
    /// Previous
    case PreviousSeek = 0x0c
    /// Next
    case NextSeek = 0x0d
    /// Brightness Down
    case BrightnessDown = 0x0e
    /// Brightness Up
    case BrightnessUp = 0x0f
    /// OnScreen Display(Show Icon)
    case OSD = 0x10
    /// None
    case None = 0xff
}


/// Bluetooth Data Header Command
enum CMD: UInt8{
    case REQ_VersionInfo = 0x01
    case REQ_Player = 0x70
    case REQ_SyncContents = 0x72
    
    case RES_VersionInfo = 0x81
    case RES_PairingEvent = 0x71
    case RES_Contents = 0xf2
    case RES_EVENT_POWER_OFF = 0x62
}
