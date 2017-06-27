//
//  DataStructure.swift
//  NDeviceSDK
//
//  Created by Aram Moon on 2017. 6. 27..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation

//MARK: - Response Structure
struct RES_VerionInfo{
    var deviceName: String = ""
    var firmwareVerion: String = ""
    var protocolVer: String = ""
    var subName: String = ""
    var deviceType : UInt16 = 0
    var mac: String = ""
    
    static let length = 64
    init(_ d : [UInt8]){
        guard d.count == Int(RES_VerionInfo.length) else {
            return
        }
        deviceName = toString(Array(d[0..<16]))
        firmwareVerion = toString(Array(d[16..<32]))
        protocolVer = toString(Array(d[32..<40]))
        subName = toString(Array(d[40..<56]))
        deviceType = toUInt16(d[56], d[57])
        mac = toString(Array(d[58..<64]))
    }
}

struct RES_PairingInfo {
    var address = ""
    
    static let length = 5
    
    init(_ d: [UInt8]){
        guard d.count == Int(RES_PairingInfo.length) else {
            return
        }
        
        address = String.init(data: Data(d), encoding: .utf8) ?? ""
        
    }
}

struct RES_RevisionContents{
    var updateCount: UInt16 = 0
    var contentsId = [UInt16]()
    var contentsRevision = [UInt16]()
    
    init(_ d: [UInt8]){
        updateCount = toUInt16(d[0], d[1])
        let count = (d.count - 2)/4
        for i in 0..<count{
            let id = toUInt16(d[i*4+2], d[i*4+3])
            let rev = toUInt16(d[i*4+3], d[i*4+4])
            self.contentsId.append(id)
            self.contentsRevision.append(rev)
        }
    }
}

//MARK: - Request Structure -
struct REQ_VersionInfo: Request{
    var cmd: UInt8 = CMD.REQ_VersionInfo.rawValue //0x01
    var length: UInt16 = 34
    var connectionCode: [UInt8] = [UInt8](repeating: 0, count: 16)
    var appType: [UInt8] = [0x00, 0x03] // Player [0x00, 0x03]
    var appVer: [UInt8] = [UInt8](repeating: 0, count: 16)
    
    func toUInt8Array() -> [UInt8]{
        var data = [UInt8]()
        data.append(cmd)
        data.append(contentsOf: length.toUInt8Array())
        data.append(contentsOf: connectionCode)
        data.append(contentsOf: appType)
        if let ver = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)?.toUInt8Array() {
            data.append(contentsOf: ver)
        }else{
            data.append(contentsOf: appVer)
        }
        return data
    }
}

struct REQ_Player: Request {
    private let cmd: UInt8 = CMD.REQ_Player.rawValue//0x70
    let length: UInt16 = 9
    var playType :PlayType = PlayType.None
    var playData: UInt64 = 0
    
    func toUInt8Array() -> [UInt8] {
        var data = [UInt8]()
        data.append(cmd)
        data.append(contentsOf: length.toUInt8Array())
        data.append(playType.rawValue)
        data.append(contentsOf: playData.toUInt8Array())
        return data
    }
}

struct REQ_SyncContents: Request {
    private let cmd: UInt8 = CMD.REQ_SyncContents.rawValue//0x72
    private let length: UInt16 = 1
    
    func toUInt8Array() -> [UInt8] {
        var data = [UInt8]()
        data.append(cmd)
        data.append(contentsOf: length.toUInt8Array())
        data.append(0x00)
        return data
    }
}
