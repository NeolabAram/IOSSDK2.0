//
//  ResponseStruct.swift
//  NISDK3
//
//  Created by Aram Moon on 2017. 6. 16..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation

//MARK: ErrorCode
enum ErrorCode: UInt8{
    case Success = 0
    case fail = 1
    case NoPermission = 2
}

//MARK: Dot Data
public enum DotType{
    case UpDown
    case PIdChange
    case Type1 /// full dotData
    case Type2
    case Type3
}
/// xtilt (0~180), ytilt (0~180)
/// full dotData
public struct DotStruct1 {
    var diff_time: UInt8 = 0
    var force: UInt16 = 0
    var x: UInt16 = 0
    var y: UInt16 = 0
    var f_x: UInt8 = 0
    var f_y: UInt8 = 0
    var xtilt: UInt8 = 0
    var ytilt: UInt8 = 0
    var twist: UInt16 = 0
    
    let cmd: CMD = CMD.EVENT_PEN_DOTCODE
    static let length = 13
    init(_ d : [UInt8]){
        guard d.count == Int(DotStruct1.length) else {
            return
        }
        diff_time = d[0]
        force = toUInt16(d[1], d[2])
        x = toUInt16(d[3], d[4])
        y = toUInt16(d[5], d[6])
        f_x = d[7]
        f_y = d[8]
        xtilt = d[9]
        ytilt = d[10]
        twist = toUInt16(d[11], d[12])
    }
    
    init(){
        
    }
}

/// low speed, not force
public struct DotStruct2 {
    var diff_time: UInt8 = 0
    var x: UInt16 = 0
    var y: UInt16 = 0
    var f_x: UInt8 = 0
    var f_y: UInt8 = 0
    
    let cmd: CMD = CMD.EVENT_PEN_DOTCODE2
    static let length = 7
    init(_ d : [UInt8]){
        guard d.count == Int(DotStruct2.length) else {
            return
        }
        diff_time = d[0]
        x = toUInt16(d[1], d[2])
        y = toUInt16(d[3], d[4])
        f_x = d[5]
        f_y = d[6]
    }
}

/// section 0, low speed, not force
public struct DotStruct3 {
    var diff_time: UInt8 = 0
    var x: UInt8 = 0
    var y: UInt8 = 0
    var f_x: UInt8 = 0
    var f_y: UInt8 = 0
    
    let cmd: CMD = CMD.EVENT_PEN_DOTCODE3
    static let length = 7
    init(_ d : [UInt8]){
        guard d.count == Int(DotStruct3.length) else {
            return
        }
        diff_time = d[0]
        x = d[1]
        y = d[2]
        f_x = d[3]
        f_y = d[4]
    }
}

public enum UpNDown : UInt8{
    case Down = 0
    case Up = 1
}

public enum PenTipType: UInt8{
    case Normal = 0
    case Eraser = 1
}
/// time millisecond tick form 1970.1.1
/// upDown 0: Down, 1: Up
/// pentipType 0: Normal, 1: Eraser
public struct PenUpDown {
    var time: UInt64 = 0
    public var upDown: UpNDown = UpNDown.Down
    var pentipType: PenTipType = PenTipType.Normal
    var penColor: UIColor = UIColor.black
    
    let cmd: CMD = CMD.EVENT_PEN_UPDOWN // 0x63
    static let length = 14
    init(_ d : [UInt8]){
        guard d.count == Int(PenUpDown.length) else {
            return
        }
        upDown = UpNDown(rawValue: d[0]) ?? UpNDown.Down
        time = toUInt64(d, at: 1)
        pentipType = PenTipType(rawValue: d[9]) ?? PenTipType.Normal
        penColor = toUInt32(d, at: 10).toUIColor()
    }
    init(){
        
    }
}
public struct PageNewId {
    var owner_id: UInt32 = 0
    var note_id: UInt32 = 0
    var page_id: UInt32 = 0
    
    let cmd: CMD = CMD.EVENT_PEN_NEWID //0x64
    static let length = 12
    init(_ d : [UInt8]){
        guard d.count == Int(PageNewId.length) else {
            return
        }
        owner_id = toUInt32(d, at: 0)
        note_id = toUInt32(d, at: 4)
        page_id = toUInt32(d, at: 8)
    }
}


//MARK: PowerOff
enum PowerOffReason: UInt8 {
    case TimeOut = 0
    case LowBattery = 1
    case Update = 2 // Firmware update
    case PowerButton = 3
    case PenCapOff = 4
    case Error = 5
    case USBIn = 6
    case PassordError = 7
    case None = 8
}

struct POWER_OFF {
    var reason = PowerOffReason.None
    let cmd: CMD = CMD.EVENT_POWER_OFF
    static let length = 1
    init(_ d : UInt8){
        guard reason == PowerOffReason.init(rawValue: d) else {
            return
        }
    }
}

/// level : 0 ~ 100
struct BatterAlarm {
    var level: UInt8 = 0
    let cmd: CMD = CMD.EVENT_BATT_ALARM
    static let length = 1
    init(_ d : UInt8){
        level = d
    }
}


//MARK: - Offline -
struct OfflineInfo{
    var strokeCount: UInt32 = 0
    var dataSize: UInt32 = 0 // UnCompressed strokeData + DotData
    var isZip: UInt8 = 0
    
    static let length = 9
    init(_ d : [UInt8]){
        guard d.count == Int(OfflineInfo.length) else {
            return
        }
        strokeCount = toUInt32(d, at: 0)
        dataSize = toUInt32(d, at: 4)
        isZip = d[8]
    }
}
enum OfflineTransPosition: UInt8{
    case Start = 0
    case Middle = 1
    case End = 2
}

///OfflineData Header
struct OffLineData {
    var packetId: UInt16 = 0
    var isZip: UInt8 = 0
    var sizeBeforeZip: UInt16 = 0
    var sizeAfterZip: UInt16 = 0
    var trasPosition: OfflineTransPosition = OfflineTransPosition.Start
    var nSectionOwnerId: UInt32 = 0
    var nNoteId: UInt32 = 0
    var nNumOfStrokes: UInt16 = 0
    
    static let length = 18
    init(_ d : [UInt8]){
        guard d.count == Int(OffLineData.length) else {
            return
        }
        packetId = toUInt16(d[0], d[1])
        isZip = d[2]
        sizeBeforeZip = toUInt16(d[3], d[4])
        sizeAfterZip = toUInt16(d[5], d[6])
        trasPosition = OfflineTransPosition(rawValue: d[7]) ?? OfflineTransPosition.Start
        nSectionOwnerId = toUInt32(d, at: 8)
        nNoteId = toUInt32(d, at: 12)
        nNumOfStrokes = toUInt16(d[16], d[17])
    }
    
    var strokeArray: [OffLineStroke] = []
}

///OfflineData Stroke
struct OffLineStroke {
    var nPageId: UInt32 = 0
    var downTime: UInt64 = 0
    var upTime: UInt64 = 0
    var penTipType: UInt8 = 0
    var penTipColor: UInt32 = 0
    var dotCount: UInt16 = 0
    var dotArray: [OffLineDot] = []
    
    static let length = 27
    init(_ d : [UInt8]){
        guard d.count == Int(OffLineStroke.length) else {
            return
        }
        nPageId = toUInt32(d, at: 0)
        downTime = toUInt64(d, at: 4)
        upTime = toUInt64(d, at: 12)
        penTipType = d[20]
        penTipColor = toUInt32(d, at: 21)
        dotCount = toUInt16(d[25], d[26])
    }
}

//OfflineData Dot
struct OffLineDot{
    var nTimeDelta: UInt8 = 0
    var force: UInt16 = 0
    var x: UInt16 = 0
    var y: UInt16 = 0
    var fx: UInt8 = 0
    var fy: UInt8 = 0
    var xtilt: UInt8 = 0
    var ytilt: UInt8 = 0
    var twist: UInt16 = 0
    var reserved: [UInt8] = [UInt8](repeating: 0, count: 2)
    var nCheckSum: UInt8 = 0
    
    var CalCheckSum: UInt8 = 0
    static let length = 16
    init(_ d : [UInt8]){
        guard d.count == Int(OffLineDot.length) else {
            return
        }
        nTimeDelta = d[0]
        force = toUInt16(d[1], d[2])
        x = toUInt16(d[3], d[4])
        y = toUInt16(d[5], d[6])
        fx = d[7]
        fy = d[8]
        xtilt = d[9]
        ytilt = d[10]
        twist = toUInt16(d[11], d[12])
        reserved = [d[13],d[14]]
        nCheckSum = d[15]
        
        var ch: UInt = 0
        for i in 0..<d.count-1{
            ch += UInt(d[i])
        }
        CalCheckSum = UInt8(ch & 0xff)
        
    }
}

//MARK: Firmware Update

//MARK: PenVersionInfo and PenSettingInfo
enum DeviceType: UInt16{
    case Pen = 0x0001
    case Eraser = 0x0002
    case Player = 0x0003
}
struct PenVerionInfo{
    var deviceName: String = ""
    var firmwareVerion: String = ""
    var protocolVer: String = ""
    var subName: String = ""
    var deviceType : DeviceType = DeviceType.Pen
    var mac: String = ""
    
    static let length = 64
    init(_ d : [UInt8]){
        guard d.count == Int(PenVerionInfo.length) else {
            return
        }
        deviceName = toString(Array(d[0..<16]))
        firmwareVerion = toString(Array(d[16..<32]))
        protocolVer = toString(Array(d[32..<40]))
        subName = toString(Array(d[40..<56]))
        let m = toUInt16(d[56], d[57])
        deviceType = DeviceType.init(rawValue: m) ?? .Pen
        mac = toString(Array(d[58..<64]))
    }
}


struct PenStateStruct {
    //Version1
    var version: UInt8 = 0
    var penStatus: UInt8 = 0
    var timezoneOffset: UInt32 = 0
//    var timeTick: UInt64 = 0
    var pressureMax: UInt8 = 0
//    var battLevel: UInt8 = 0
//    var memoryUsed: UInt8 = 0
    var colorState: UIColor = UIColor.black
//    var usePenTipOnOff: UInt8 = 0
    var useAccelerator: OnOff = OnOff.On
//    var useHover: UInt8 = 0
//    var beepOnOff: UInt8 = 0
//    var autoPwrOffTime: UInt16 = 0
//    var penPressure: UInt16 = 0
//    var reserved: [UInt8] = [UInt8](repeating: 0, count: 11)
    
    //Version2
    var lock: Lock = Lock.UnLock
    var maxRetryCnt: UInt8 = 0
    var retryCnt: UInt8 = 0
    var timeTick: UInt64 = 0
    var autoPwrOffTime: UInt16 = 0
    var maxPressure: UInt16 = 0
    var memoryUsed: UInt8 = 0
    var usePenCapOnOff: OnOff = OnOff.Ignore
    var usePenTipOnOff: OnOff = OnOff.Ignore
    var beepOnOff: OnOff = OnOff.Ignore
    var useHover: OnOff = OnOff.Ignore
    var charging : OnOff = OnOff.Off
    var battLevel: UInt8 = 0
    var offlineOnOff: OnOff = OnOff.On
    var penPressure: UInt8 = 0
    var usbMode: USBMode = USBMode.Bulk
    var downSampling: OnOff = OnOff.On
    var localName: String = ""
    var reserved: [UInt8] = [UInt8](repeating: 0, count: 23)

    static let length = 64
    init(){
        
    }
    init(_ d: [UInt8], _ v: Version){
        guard d.count == Int(PenVerionInfo.length) else {
            return
        }
        lock = Lock.init(rawValue: d[0]) ?? .UnLock
        maxRetryCnt = d[1]
        retryCnt = d[2]
        timeTick = toUInt64(d, at: 3)
        autoPwrOffTime = toUInt16(d[11], d[12])
        maxPressure = toUInt16(d[13], d[14])
        memoryUsed = d[15]
        usePenCapOnOff = OnOff(rawValue: d[16]) ?? .Ignore
        usePenTipOnOff = OnOff(rawValue: d[17]) ?? .Ignore
        beepOnOff = OnOff(rawValue: d[18]) ?? .Ignore
        useHover = OnOff(rawValue: d[19]) ?? .Ignore
        charging = OnOff(rawValue: (d[20] >> 7)) ?? .Ignore
        battLevel = d[20] & 0x7f
        offlineOnOff = OnOff(rawValue: d[21]) ?? .Ignore
        penPressure = d[22]
        usbMode = USBMode.init(rawValue: d[23]) ?? .Bulk
        downSampling = OnOff(rawValue: d[24]) ?? .Ignore
        localName = toString(Array(d[25..<41]))
        reserved = Array(d[41..<64])
    }
    
    enum Version: UInt8{
        case Version1 = 1
        case Version2 = 2
    }
    enum Lock: UInt8{
        case UnLock = 0
        case Lock = 1
    }
    
    enum Sensitive: UInt8{
        case Max = 0
        case LV1 = 1
        case LV2 = 2
        case LV3 = 3
        //Min
        case LV4 = 4
    }
    
    enum USBMode: UInt8{
        case Disk = 0
        case Bulk = 1
    }
}

