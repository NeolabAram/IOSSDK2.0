//
//  Util.swift
//  NDeviceSDK
//
//  Created by Aram Moon on 2017. 6. 26..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation


class N {
    
    static var isDebug = true
    
    static func Log(_ items: Any... ){
        
        if(isDebug){
            print(items)
        }
    }
}

extension String{
    func toUInt8Array() -> [UInt8]{
        let array: [UInt8] = Array(self.utf8)
        var data = [UInt8](repeating: 0, count: 16)
        
        for i in 0..<16{
            if(i < array.count){
                data[i] = array[i]
            }
        }
        return data
    }
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

func getMacAddr(fromString data: Any) -> String {
    var macAddrStr: String = String.init(describing: data)
    macAddrStr = macAddrStr.replacingOccurrences(of: "<", with: "")
    macAddrStr = macAddrStr.replacingOccurrences(of: ">", with: "")
    macAddrStr = macAddrStr.replacingOccurrences(of: " ", with: "")
    return macAddrStr
}

func toUInt16(_ data1: UInt8,_ data2 : UInt8)-> UInt16{
    return  UInt16(data1) + UInt16(data2) << 8
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

protocol UInt8Type{}
extension UInt8: UInt8Type{}
extension Array where Element:UInt8Type{
    func toData() -> Data{
        return Data(makeWholePacket(self as! [UInt8]))
    }
}

protocol Request {
    func toUInt8Array() -> [UInt8]
}

extension UInt16{
    func toUInt8Array() -> [UInt8]{
        return [UInt8(self & 0xff), UInt8((self >> 8) & 0xff)]
    }
}

extension UInt32{
    func toUInt8Array() -> [UInt8]{
        return [UInt8(self & 0xff), UInt8((self >> 8) & 0xff), UInt8((self >> 16) & 0xff), UInt8((self >> 24) & 0xff)]
    }
}

extension UInt64{
    func toUInt8Array() -> [UInt8]{
        return [UInt8(self & 0xff), UInt8((self >> 8) & 0xff), UInt8((self >> 16) & 0xff), UInt8((self >> 24) & 0xff)
            , UInt8((self >> 32) & 0xff), UInt8((self >> 40) & 0xff), UInt8((self >> 48) & 0xff), UInt8((self >> 56) & 0xff)]
    }
}
