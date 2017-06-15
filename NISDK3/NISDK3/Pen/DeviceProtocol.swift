//
//  PenProtocol.swift
//  NISDK3
//
//  Created by Aram Moon on 2017. 6. 7..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation
import CoreBluetooth

public protocol DeviceDelegate : class {
    /// Pen Data, UpDown, PageID
    func dataDot(_ type : DotType, _ data: Any)
    /// Pen Status
    func deviceMessage(_ msg: PenMessage)
    /// Bluetooth Event
    func deviceService(_ status: PenStatus, device: NPen?)
}

let PACKET_START: UInt8 = 0xc0
let PACKET_END: UInt8 = 0xc1
let PACKET_DLE: UInt8 = 0x7d
let PACKET_MAX_LEN = 32000


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
    case REQ2_FW_FILE = 0x32
    
    case EVENT_BATT_ALARM = 0x61
    case EVENT_POWER_OFF = 0x62
    case EVENT_PEN_UPDOWN = 0x63
    case EVENT_PEN_NEWID = 0x64
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
    case RES2_FW_FILE = 0xb2
}

public enum DotType{
    case UpDown
    case PIdChange
    case Type1
    case Type2
    case Type3
}

//MARK: - from device -
/// xtilt (0~180), ytilt (0~180)
/// full dotData
///
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

public struct CHANGEDID2_DATA {
    var owner_id: UInt32 = 0
    var note_id: UInt32 = 0
    var page_id: UInt32 = 0
    
    let cmd: CMD = CMD.EVENT_PEN_NEWID //0x64
    static let length = 12
    init(_ d : [UInt8]){
        guard d.count == Int(CHANGEDID2_DATA.length) else {
            return
        }
        owner_id = toUInt32(d, at: 0)
        note_id = toUInt32(d, at: 4)
        page_id = toUInt32(d, at: 8)
    }
}

public enum UpNDown : UInt8{
    case Down = 0
    case Up = 1
}
/// time millisecond tick form 1970.1.1
/// upDown 0: Down, 1: Up
/// pentipType 0: Normal, 1: Eraser
public struct COMM_PENUP_DATA {
    var time: UInt64 = 0
    public var upDown: UpNDown = UpNDown.Down
    var pentipType: UInt8 = 0
    var penColor: UInt32 = 0
    
    let cmd: CMD = CMD.EVENT_PEN_UPDOWN // 0x63
    static let length = 14
    init(_ d : [UInt8]){
        guard d.count == Int(COMM_PENUP_DATA.length) else {
            return
        }
        upDown = UpNDown.init(rawValue: d[0])!
        time = toUInt64(d, at: 1)
        pentipType = d[9]
        penColor = toUInt32(d, at: 10)
    }
}

enum PowerOffReason: UInt8 {
    case TimeOut = 0
    case LowBattery = 1
    case Update = 2
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

struct RequestOfflineFileListStruct {
    var status: UInt8 = 0
}
struct OfflineFileListStruct {
    var status: UInt8 = 0
    var sectionOwnerId: UInt32 = 0
    var noteCount: UInt8 = 0
    var noteId: [UInt32] = [UInt32](repeating: 0, count: 10)
}
struct RequestDelOfflineFileStruct {
    var sectionOwnerId: UInt32 = 0
    var noteId: UInt64 = 0
}
struct RequestOfflineFileStruct {
    var sectionOwnerId: UInt32 = 0
    var noteCount: UInt8 = 0
    var noteId: [UInt32] = [UInt32](repeating: 0, count: 10)
}
struct OfflineFileListInfoStruct {
    var fileCount: UInt32 = 0
    var fileSize: UInt32 = 0
}
struct OFFLINE_FILE_INFO_DATA {
    var type: UInt8 = 0
    var file_size: UInt32 = 0
    var packet_count: UInt16 = 0
    var packet_size: UInt16 = 0
    var slice_count: UInt16 = 0
    var slice_size: UInt16 = 0
}
struct OFFLINE_FILE_DATA {
    var index: UInt16 = 0
    var slice_index: UInt8 = 0
    var data: UInt8 = 0
}
struct OfflineFileAckStruct {
    var type: UInt8 = 0
    var index: UInt8 = 0
}
struct OfflineFileStatusStruct {
    var status: UInt8 = 0
}
struct OffLineDataFileHeaderStruct {
    var abVersion: [UInt8] = [UInt8](repeating: 0, count: 5)
    var isActive: UInt8 = 0
    var nOwnerId: UInt32 = 0
    var nNoteId: UInt32 = 0
    var nPageId: UInt32 = 0
    var nSubId: UInt32 = 0
    var nNumOfStrokes: UInt32 = 0
    var cbDataSize: UInt32 = 0
    //header 크기를 제외한 값
    var abReserved: [UInt8] = [UInt8](repeating: 0, count: 33)
    var nCheckSum: UInt8 = 0
}
struct OffLineDataStrokeHeaderStruct {
    var nStrokeStartTime: UInt64 = 0
    var nStrokeEndTime: UInt64 = 0
    var nDotCount: UInt32 = 0
    var cbDotStructSize: UInt8 = 0
#if HAS_LINE_COLOR
    var nLineColor: UInt32 = 0
#endif
    var nCheckSum: UInt8 = 0
}
struct OffLineDataDotStruct {
    var nTimeDelta: UInt8 = 0
    var x: UInt16 = 0
    var y: UInt16 = 0
    var fx: UInt8 = 0
    var fy: UInt8 = 0
    var force: UInt8 = 0
}
struct UpdateFileInfoStruct {
    var filePath: [UInt8] = [UInt8](repeating: 0, count: 52)
    var fileSize: UInt32 = 0
    var packetCount: UInt16 = 0
    var packetSize: UInt16 = 0
}
struct RequestUpdateFileStruct {
    var index: UInt16 = 0
}
struct UpdateFileDataStruct {
    var index: UInt16 = 0
    var fileData: [UInt8] = [UInt8](repeating: 0, count: 112)
}
struct UpdateFileStatusStruct {
    var status: UInt16 = 0
}
struct PenStateStruct {
    var version: UInt8 = 0
    var penStatus: UInt8 = 0
    var timezoneOffset: Int32 = 0
    var timeTick: UInt64 = 0
    var pressureMax: UInt8 = 0
    var battLevel: UInt8 = 0
    var memoryUsed: UInt8 = 0
    var colorState: UInt32 = 0
    var usePenTipOnOff: UInt8 = 0
    var useAccelerator: UInt8 = 0
    var useHover: UInt8 = 0
    var beepOnOff: UInt8 = 0
    var autoPwrOffTime: UInt16 = 0
    var penPressure: UInt16 = 0
    var reserved: [UInt8] = [UInt8](repeating: 0, count: 11)
}
struct SetPenStateStruct {
    var timezoneOffset: UInt32 = 0
    var timeTick: UInt64 = 0
    var colorState: UInt32 = 0
    var usePenTipOnOff: UInt8 = 0
    var useAccelerator: UInt8 = 0
    var useHover: UInt8 = 0
    var beepOnOff: UInt8 = 0
    var autoPwrOnTime: UInt16 = 0
    var penPressure: UInt16 = 0
    var reserved: [UInt8] = [UInt8](repeating: 0, count: 16)
}
struct SetNoteIdListStruct {
    var type: UInt8 = 0
    var count: UInt8 = 0
    var params: [UInt32] = [UInt32](repeating: 0, count: 16)
}
struct ReadyExchangeDataStruct {
    var ready: UInt8 = 0
}
struct ReadyExchangeDataRequestStruct {
    var ready: UInt8 = 0
}
struct PenPasswordRequestStruct {
    var retryCount: UInt8 = 0
    var resetCount: UInt8 = 0
}
struct PenPasswordResponseStruct {
    var password: [UInt8] = [UInt8](repeating: 0, count: 16)
}
struct PenPasswordChangeRequestStruct {
    var prevPassword: [UInt8] = [UInt8](repeating: 0, count: 16)
    var newPassword: [UInt8] = [UInt8](repeating: 0, count: 16)
}
struct PenPasswordChangeResponseStruct {
    var passwordState: UInt8 = 0
}

//MARK: - TO Pen -
struct SetVersionInfoStruct {
    var cmd: UInt8 = 0x01
    var length: UInt16 = 34
    var connectionCode: [UInt8] = [UInt8](repeating: 0, count: 16)
    var appType: [UInt8] = [0x10, 0x01] // iOS [0x10, 0x01], AOS[0x11,0x01],SDK[0x12,0x11]
    var appVer: [UInt8] = [UInt8](repeating: 0, count: 16)
}
struct SetPenPasswordStruct {
    var cmd: UInt8 = 0x02
    var length: UInt16 = 16
    var password: [UInt8] = [UInt8](repeating: 0, count: 16)
}
struct SetChangePenPasswordStruct {
    var cmd: UInt8 = 0x03
    var length: UInt16 = 33
    var usePwd: UInt8 = 1
    var oldPassword: [UInt8] = [UInt8](repeating: 0, count: 16)
    var newPassword: [UInt8] = [UInt8](repeating: 0, count: 16)
}
struct SetRequestPenStateStruct {
    var cmd: UInt8 = 0x04
    var length: UInt16 = 0
}
struct PenState2Struct {
    var lock: UInt8 = 0
    var maxRetryCnt: UInt8 = 0
    var retryCnt: UInt8 = 0
    var timeTick: UInt64 = 0
    var autoPwrOffTime: UInt16 = 0
    var maxPressure: UInt16 = 0
    var memoryUsed: UInt8 = 0
    var usePenCapOnOff: UInt8 = 0
    var usePenTipOnOff: UInt8 = 0
    //auto power on
    var beepOnOff: UInt8 = 0
    var useHover: UInt8 = 0
    var battLevel: UInt8 = 0
    var offlineOnOff: UInt8 = 0
    var penPressure: UInt8 = 0
    var usbMode: UInt8 = 0
    //0: disk, 1:bulk
    var downSampling: UInt8 = 0
}
struct SetPenState2Struct {
    var cmd: UInt8 = 0
    var length: UInt16 = 0
    var timeTick: UInt64 = 0
    var autoPwrOffTime: UInt16 = 0
    var usePenCapOnOff: UInt8 = 0
    var usePenTipOnOff: UInt8 = 0
    //auto power on
    var beepOnOff: UInt8 = 0
    var useHover: UInt8 = 0
    var offlineOnOff: UInt8 = 0
    var colorType: UInt8 = 0
    var colorState: UInt32 = 0
    var penPressure: UInt8 = 0
}
struct SetNoteIdList2Struct {
    var cmd: UInt8 = 0
    var length: UInt16 = 0
    var count: UInt16 = 0
}
struct SetRequestOfflineFileListStruct {
    var cmd: UInt8 = CMD.REQ1_OFFLINE_NOTE_LIST.rawValue
    var length: UInt16 = 4
    var sectionOwnerId: UInt32 = 0xffffffff
    
    func toUInt8Array() -> [UInt8]{
        var data = [UInt8]()
        data.append(cmd)
        data.append(contentsOf: length.toUInt8Array())
        data.append(contentsOf: sectionOwnerId.toUInt8Array())
        return data
    }
}
struct SetRequestOfflinePageListStruct {
    var cmd: UInt8 = 0
    var length: UInt16 = 0
    var sectionOwnerId: UInt32 = 0
    var noteId: UInt32 = 0
}
struct SetRequestOfflineDataStruct {
    var cmd: UInt8 = 0
    var length: UInt16 = 0
    var transOption: UInt8 = 0
    var dataZipOption: UInt8 = 0
    var sectionOwnerId: UInt32 = 0
    var noteId: UInt32 = 0
    var pageCnt: UInt32 = 0
}
struct OffLineData2HeaderStruct {
    var nSectionOwnerId: UInt32 = 0
    var nNoteId: UInt32 = 0
    var nNumOfStrokes: UInt32 = 0
}
struct OffLineData2StrokeHeaderStruct {
    var nPageId: UInt32 = 0
    var nStrokeStartTime: UInt64 = 0
    var nStrokeEndTime: UInt64 = 0
    var penTipType: UInt8 = 0
#if HAS_LINE_COLOR
    var nLineColor: UInt32 = 0
#endif
    var nDotCount: UInt16 = 0
}
struct OffLineData2DotStruct {
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
}
struct Response2OffLineData {
    var cmd: UInt8 = 0
    var errorCode: UInt8 = 0
    var length: UInt16 = 0
    var packetId: UInt16 = 0
    var transOption: UInt8 = 0
}
struct SetRequestDelOfflineDataStruct {
    var cmd: UInt8 = 0
    var length: UInt16 = 0
    var sectionOwnerId: UInt32 = 0
    var noteCnt: UInt8 = 0
}
struct SetRequestFWUpdateStruct {
    var cmd: UInt8 = 0
    var length: UInt16 = 0
    var deviceName: [UInt8] = [UInt8](repeating: 0, count: 16)
    var fwVer: [UInt8] = [UInt8](repeating: 0, count: 16)
    var fileSize: UInt32 = 0
    var packetSize: UInt32 = 0
    var dataZipOpt: UInt8 = 0
    var nCheckSum: UInt8 = 0
}
struct SetRequest2FWUpdateStruct {
    var sof: UInt8 = 0
    var cmd: UInt8 = 0
    var error: UInt8 = 0
    var length: UInt16 = 0
    var transContinue: UInt8 = 0
    var fileOffset: UInt32 = 0
    var nChecksum: UInt8 = 0
    var sizeBeforeZip: UInt16 = 0
    var sizeAfterZip: UInt16 = 0
    var eof: UInt8 = 0
}
enum RequestPenStateType : Int{
    case PenCapOff = 3
    case AutoPowerOn = 4
    case BeepOnOff = 5
    case HoverOnOff = 6
    case OfflineSave = 7
    case PenPresure = 9
    case USBMode = 10
    case DownSampling = 11
}
