//
//  Log.swift
//  NISDK3
//
//  Created by Aram Moon on 2017. 6. 7..
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

extension UInt8 {
    func hexString() -> String {
        return String(format: " 0x%02hhx", self)
    }
}

extension Data {
    func hexString() -> String {
        var i = -1
        return map {
            i += 1
            if i%4 == 0 {
                return String(format: " %02hhx", $0)
            }else{
                return String(format: "%02hhx", $0)
            }}.joined()
    }
}
