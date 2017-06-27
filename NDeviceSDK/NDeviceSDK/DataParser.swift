//
//  DataParser.swift
//  NDeviceSDK
//
//  Created by Aram Moon on 2017. 6. 26..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation

let PACKET_START: UInt8 = 0xc0
let PACKET_END: UInt8 = 0xc1
let PACKET_DLE: UInt8 = 0x7d
let PACKET_MAX_LEN = 32000


class DataParser {
    
    private var packetData = [UInt8]()
    private var IsEscape = false
    var deviceDelegate: DeviceDelegate?
    //MARK: Pen Data [UInt8], length
    func parseData(_ data: [UInt8]) {
        for d in data {
            if d == PACKET_START{
                packetData.removeAll()
                IsEscape = false
            }else if d == PACKET_END{
                parseDataPacket(packetData)
                IsEscape = false
                
            }else if d == PACKET_DLE{
                IsEscape = true
                
            }else if IsEscape {
                packetData.append(d ^ 0x20)
                IsEscape = false
                
            }else{
                packetData.append(d)
            }
        }
    }
    
    // Complet Packet [CMD, (error), length, Data]
    func parseDataPacket(_ packet: [UInt8]) {
        let data: [UInt8] = packet
        guard let cmd = CMD(rawValue: data[0]) else{
            N.Log("CMD Error")
            return
        }
        var packetDataLength = Int(toUInt16(data[1],data[2]))
        var pos: Int = 3
        switch cmd {
        case .RES_VersionInfo:
//            error
            let errorCode : UInt8 = data[1]
            packetDataLength = Int(toUInt16(data[2],data[3]))
            pos += 1
            if errorCode != 0 {
                return
            }
            
            if (packetData.count < (packetDataLength + 4)) {
                return
            }
            
            let len = RES_VerionInfo.length
            let penInfo = RES_VerionInfo.init(Array(data[pos..<pos+len]))
            N.Log("PenInfo", penInfo)
            let msg = DeviceMessage.init(.Autorize, data: nil)
            deviceDelegate?.deviceMessage(msg)
        case .RES_PairingEvent:
            guard packetDataLength !=  RES_PairingInfo.length else {
                N.Log("Not match data length", cmd)
                return
            }
            let len = RES_PairingInfo.length
            let res = RES_PairingInfo.init(Array(data[pos..<pos+len]))
            N.Log("Paring Not Use Hear", res)
//            let msg = DeviceMessage.init(.Pairing, data: res)
//            deviceDelegate?.deviceMessage(msg)
        case .RES_Contents:
            // Error
            let errorCode : UInt8 = data[1]
            packetDataLength = Int(toUInt16(data[2],data[3]))
            pos += 1
            if errorCode != 0{
                N.Log("Error", cmd)
                return
            }
            let len = packetDataLength
            let res = RES_RevisionContents.init(Array(data[pos..<pos+len]))
            N.Log("RES_Contents", res)
            let msg = DeviceMessage.init(.Contents, data: res)
            deviceDelegate?.deviceMessage(msg)
        case .RES_EVENT_POWER_OFF:
            let msg = DeviceMessage.init(.PowerOff, data: nil)
            deviceDelegate?.deviceMessage(msg)
        default:
            N.Log("Not Defined CMD", cmd)
        }
    }
    
}
