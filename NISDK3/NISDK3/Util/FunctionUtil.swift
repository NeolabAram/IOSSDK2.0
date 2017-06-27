//
//  FunctionUtil.swift
//  NISDK3
//
//  Created by Aram Moon on 2017. 6. 16..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation

func toUInt16(_ data1: UInt8,_ data2 : UInt8)-> UInt16{
    return  UInt16(data1) + UInt16(data2) << 8
}

func toUInt32(_ data: [UInt8], at : Int) -> UInt32{
    let value: UInt32 = UInt32(data[at]) + UInt32(data[at+1]) << 8 + UInt32(data[at+2]) << 16 + UInt32(data[at+3]) << 24
    return value
}

func toUInt64(_ data: [UInt8], at : Int) -> UInt64{
    let value: UInt64 = UInt64(data[at]) + UInt64(data[at+1]) << 8 + UInt64(data[at+2]) << 16 + UInt64(data[at+3]) << 24
        + UInt64(data[at+4]) << 32 + UInt64(data[at+5]) << 40 + UInt64(data[at+6]) << 48 + UInt64(data[at+7]) << 56
    return value
}

func toSectionOwner(_ section : UInt8, _ owner:UInt32) -> UInt32{
    let sectionOwner: UInt32 = (UInt32(section) << 24) | owner
    return sectionOwner
}

func toSetionOwner(_ sectionOwner: UInt32) -> (section: UInt8, owner: UInt32){
    let section: UInt8 = UInt8(sectionOwner >> 24)
    let owner : UInt32 = sectionOwner & 0x00ffffff
    return (section,owner)
}

func toString(_ data: [UInt8]) -> String{
    var validdata = [UInt8]()
    for m in data{
        if m != 0{
            validdata.append(m)
        }
    }
    if let result = String(data: Data(validdata), encoding: .utf8) {
        return result
    }else{
        return ""
    }
}

func makeWholePacket(_ data: [UInt8]) -> [UInt8]{
    var wholePacketData = [UInt8]()
    wholePacketData.append(PACKET_START)
    for i in 0..<data.count {
        let int_data = data[i]
        if (int_data == PACKET_START) || (int_data == PACKET_END) || (int_data == PACKET_DLE) {
            wholePacketData.append(PACKET_DLE)
            wholePacketData.append(int_data ^ 0x20)
        }
        else {
            wholePacketData.append(int_data)
        }
    }
    wholePacketData.append(PACKET_END)
    return wholePacketData
}

func toHexString(data: [UInt8]) -> String{
    var result = "["
    for d in data{
        result += d.hexString()
        result += ", "
    }
    return result
}
