//
//  RequestStruct.swift
//  NISDK3
//
//  Created by Aram Moon on 2017. 6. 16..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation

//MARK: - Mixed Data Request and Response -
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

struct SetPenStateStruct {
    var timezoneOffset: UInt32 = 0
    var timeTick: UInt64 = UInt64(Date().timeIntervalSince1970 * 1000)
    var colorState: UInt32 = 0
    var usePenTipOnOff: UInt8 = 0
    var useAccelerator: UInt8 = 0
    var useHover: UInt8 = 0
    var beepOnOff: UInt8 = 0
    var autoPwrOnTime: UInt16 = 0
    var penPressure: UInt16 = 0xffff
    var reserved: [UInt8] = [UInt8](repeating: 0, count: 16)
    
    func toUInt8Array() -> [UInt8]{
        var data = [UInt8]()
        data.append(contentsOf: timezoneOffset.toUInt8Array())
        data.append(contentsOf: timeTick.toUInt8Array())
        data.append(contentsOf: colorState.toUInt8Array())
        data.append(usePenTipOnOff)
        data.append(useAccelerator)
        data.append(useHover)
        data.append(beepOnOff)
        data.append(contentsOf:  autoPwrOnTime.toUInt8Array())
        data.append(contentsOf:  penPressure.toUInt8Array())
        data.append(contentsOf:reserved)
        return data
    }
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

struct Response2OffLineData {
    var cmd: UInt8 = 0
    var errorCode: UInt8 = 0
    var length: UInt16 = 0
    var packetId: UInt16 = 0
    var transOption: UInt8 = 0
}

//MARK: - TO Pen Protocol 2.0 -
protocol Request {
    func toUInt8Array() -> [UInt8]
}

struct REQ{
    struct VersionInfo: Request{
        var cmd: UInt8 = CMD.VERSION_INFO.rawValue
        var length: UInt16 = 34
        var connectionCode: [UInt8] = [UInt8](repeating: 0, count: 16)
        var appType: [UInt8] = [0x10, 0x01] // iOS [0x10, 0x01], AOS[0x11,0x01],SDK[0x12,0x11]
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
    struct PenPassword:  Request{
        var cmd: UInt8 = CMD.RES_COMPARE_PWD.rawValue //0x02
        var length: UInt16 = 16
        var password: [UInt8] = [UInt8](repeating: 0, count: 16)
        
        init(_ pinNumber : String) {
            password = pinNumber.toUInt8Array()
        }
        
        func toUInt8Array() -> [UInt8]{
            var data = [UInt8]()
            data.append(cmd)
            data.append(contentsOf: length.toUInt8Array())
            data.append(contentsOf: password)
            return data
        }
    }
    struct ChangePenPassword: Request {
        var cmd: UInt8 = CMD.CHANGE_PWD.rawValue //0x03
        var length: UInt16 = 33
        var usePwd: UInt8 = 1
        var oldPassword: [UInt8] = [UInt8](repeating: 0, count: 16)
        var newPassword: [UInt8] = [UInt8](repeating: 0, count: 16)
        
        init(_ curNumber: String, to pinNumber: String){
            oldPassword = curNumber.toUInt8Array()
            newPassword = pinNumber.toUInt8Array()
        }
        
        func toUInt8Array() -> [UInt8] {
            var data = [UInt8]()
            data.append(cmd)
            data.append(contentsOf: length.toUInt8Array())
            data.append(usePwd)
            data.append(contentsOf: oldPassword)
            data.append(contentsOf: newPassword)
            return data
        }
    }
    struct PenSettingInfo: Request {
        var cmd: UInt8 = CMD.PEN_STATE.rawValue//0x04
        var length: UInt16 = 0
        
        func toUInt8Array() -> [UInt8] {
            var data = [UInt8]()
            data.append(cmd)
            data.append(contentsOf: length.toUInt8Array())
            return data
        }
    }
    struct UsingNoteAll: Request{
        let cmd: UInt8 = CMD.SET_NOTE_LIST.rawValue
        let length: UInt16 = 2
        let count: UInt16 = 0xffff
        func toUInt8Array() -> [UInt8] {
            var data = [UInt8]()
            data.append(cmd)
            data.append(contentsOf: length.toUInt8Array())
            data.append(contentsOf: count.toUInt8Array())
            return data
        }
    }
    struct UsingNote : Request {
        var cmd: UInt8 = CMD.SET_NOTE_LIST.rawValue
        var length: UInt16 = 0
        var count: UInt16 = 0
        var sectionOwnerNoteList : [UInt8] = []
        
        init(SectionOwnerNoteList list :[(UInt8,UInt32,UInt32)]){
            count = UInt16(list.count)
            length = 2 + 8 * count
            for (section, owner, note) in list{
                let sctionOwner = toSectionOwner(section, owner)
                sectionOwnerNoteList.append(contentsOf: sctionOwner.toUInt8Array())
                sectionOwnerNoteList.append(contentsOf: note.toUInt8Array())
            }
        }
        
        func toUInt8Array() -> [UInt8] {
            var data = [UInt8]()
            data.append(cmd)
            data.append(contentsOf: length.toUInt8Array())
            data.append(contentsOf: count.toUInt8Array())
            data.append(contentsOf: sectionOwnerNoteList)
            return data
        }
    }
    struct OfflineNoteList : Request{
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
    struct OfflinePageList: Request {
        var cmd: UInt8 = CMD.REQ2_OFFLINE_PAGE_LIST.rawValue // 0x22
        var length: UInt16 = 8
        var sectionOwnerId: UInt32 = 0
        var noteId: UInt32 = 0
        
        init(_ section : UInt8, _ owner: UInt32, _  note: UInt32){
            sectionOwnerId = toSectionOwner(section, owner)
            noteId = note
        }
        
        func toUInt8Array() -> [UInt8]{
            var data = [UInt8]()
            data.append(cmd)
            data.append(contentsOf: length.toUInt8Array())
            data.append(contentsOf: sectionOwnerId.toUInt8Array())
            data.append(contentsOf: noteId.toUInt8Array())
            return data
        }
        
    }
    enum OfflineTransOption: UInt8{
        case NotNextTransfer = 0
        case NextAndDelete = 1
        case NextAndReserve = 2
    }
    enum OfflineCompress: UInt8{
        case None = 0
        case Compress = 1
    }
    
    struct OfflineData: Request {
        var cmd: UInt8 = CMD.REQ1_OFFLINE_DATA.rawValue// 0x23
        var length: UInt16 = 0
        var transOption: OfflineTransOption = OfflineTransOption.NextAndDelete
        var dataZipOption: OfflineCompress = OfflineCompress.Compress
        var sectionOwnerId: UInt32 = 0
        var noteId: UInt32 = 0
        var pageCnt: UInt32 = 0
        var pageListArray: [UInt8] = []
        init(_ section: UInt8,_ owner: UInt32,_ note: UInt32,_ pageList: [UInt32]?){
            sectionOwnerId = toSectionOwner(section, owner)
            noteId = note
            if let pages = pageList{
                pageCnt = UInt32(pages.count)
                length = 14 + 4 * UInt16(pageCnt)
                for page in pages{
                    pageListArray.append(contentsOf: page.toUInt8Array())
                }
            }else{
                pageCnt = 0
                length = 14
            }
        }
        
        func toUInt8Array() -> [UInt8] {
            var data = [UInt8]()
            data.append(cmd)
            data.append(contentsOf: length.toUInt8Array())
            data.append(transOption.rawValue)
            data.append(dataZipOption.rawValue)
            data.append(contentsOf: sectionOwnerId.toUInt8Array())
            data.append(contentsOf: noteId.toUInt8Array())
            data.append(contentsOf: pageCnt.toUInt8Array())
            data.append(contentsOf: pageListArray)
            return data
        }
    }
    
    enum OfflineAckTransOP: UInt8{
        case Stop = 0
        case Continue = 1
    }
    
    struct OfflineDataAck: Request {
        let cmd: UInt8 = CMD.RES2_OFFLINE_DATA.rawValue // 0xA4
        var error: ErrorCode = ErrorCode.Success
        let length: UInt16 = 3
        var packetId: UInt16 = 0
        var transOp: OfflineAckTransOP = OfflineAckTransOP.Continue
        
        init(_ packetId: UInt16,_ errCode: ErrorCode, _ transOption: OfflineAckTransOP){
            self.packetId = packetId
            error = errCode
            transOp = transOption
        }
        
        func toUInt8Array() -> [UInt8]{
            var data = [UInt8]()
            data.append(cmd)
            data.append(error.rawValue)
            data.append(contentsOf: length.toUInt8Array())
            data.append(contentsOf: packetId.toUInt8Array())
            data.append(transOp.rawValue)
            return data
        }
        
    }
    struct DeleteOfflineData: Request {
        var cmd: UInt8 = CMD.REQ_DEL_OFFLINE_DATA.rawValue//0x25
        var length: UInt16 = 0
        var sectionOwnerId: UInt32 = 0
        var noteCnt: UInt8 = 0
        var noteListArray: [UInt8] = []
        
        init(_ section: UInt8,_ owner: UInt32,_ noteList: [UInt32]){
            noteCnt = UInt8(noteList.count)
            length = 5 + (UInt16(noteCnt) * 4)
            sectionOwnerId = toSectionOwner(section, owner)
            for note in noteList{
                self.noteListArray.append(contentsOf: note.toUInt8Array())
            }
        }
        
        func toUInt8Array() -> [UInt8]{
            var data = [UInt8]()
            data.append(cmd)
            data.append(contentsOf: length.toUInt8Array())
            data.append(contentsOf: sectionOwnerId.toUInt8Array())
            data.append(noteCnt)
            data.append(contentsOf: noteListArray)
            return data
        }
    }
    
    struct FWUpdateFirst: Request {
        var cmd: UInt8 = CMD.REQ1_FW_FILE.rawValue // 0x31
        var length: UInt16 = 22
        var deviceName: [UInt8] = [UInt8](repeating: 0, count: 16)
        var fwVer: [UInt8] = [UInt8](repeating: 0, count: 16)
        var fileSize: UInt32 = 0
        var packetSize: UInt32 = 0
        var dataZipOpt: UInt8 = 0
        var nCheckSum: UInt8 = 0
        
        func toUInt8Array() -> [UInt8]{
            var data = [UInt8]()
            data.append(cmd)
            data.append(contentsOf: length.toUInt8Array())
            data.append(contentsOf: deviceName)
            data.append(contentsOf: fwVer)
            data.append(contentsOf: fileSize.toUInt8Array())
            data.append(contentsOf: packetSize.toUInt8Array())
            data.append(dataZipOpt)
            data.append(nCheckSum)
            
            return data
        }
    }
    
    struct FWUpdateSecond: Request {
        var cmd: UInt8 = CMD.RES2_FW_FILE.rawValue// 0xB2
        var error: UInt8 = 0
        var length: UInt16 = 0
        var transContinue: UInt8 = 0
        var fileOffset: UInt32 = 0
        var nChecksum: UInt8 = 0
        var sizeBeforeZip: UInt16 = 0
        var sizeAfterZip: UInt16 = 0
        var fileData: [UInt8] = []
        
        func toUInt8Array() -> [UInt8]{
            var data = [UInt8]()
            data.append(cmd)
            data.append(error)
            data.append(contentsOf: length.toUInt8Array())
            data.append(transContinue)
            data.append(contentsOf: fileOffset.toUInt8Array())
            
            data.append(nChecksum)
            data.append(contentsOf: sizeBeforeZip.toUInt8Array())
            data.append(contentsOf: sizeAfterZip.toUInt8Array())
            data.append(contentsOf: fileData)
            return data
        }
        
    }

    struct PenStatus: Request{
        
        enum SettingType : UInt8{
            case TimeStamp = 1
            case AutoPowerOffTime = 2
            case PenCapOff = 3
            case AutoPowerOn = 4
            case BeepOnOff = 5
            case HoverOnOff = 6
            case OfflineSave = 7
            case PenLEDColor = 8
            case PenPresure = 9
            case USBMode = 10
            case DownSampling = 11
            case LocalName = 12
        }
        
        var cmd: UInt8 = CMD.SET_PEN_STATE.rawValue// 0x05
        var length: UInt16 = 0
        var type: SettingType = SettingType.TimeStamp
        var value = [UInt8]()
        
        init(_ type: SettingType,_ onOff: OnOff ){
            self.type = type
            value = [onOff.rawValue]
            length = 1 + UInt16(value.count)
        }
        
        init(_ type: SettingType,_ mode: PenStateStruct.USBMode ){
            self.type = type
            value = [mode.rawValue]
            length = 1 + UInt16(value.count)
        }
        
        init(_ type: SettingType,_ sensitive: PenStateStruct.Sensitive){
            self.type = type
            value = [sensitive.rawValue]
            length = 1 + UInt16(value.count)
        }
        
        init(_ type:SettingType, _ timestamp: UInt64){
            self.type = type
            value = timestamp.toUInt8Array()
            length = 1 + UInt16(value.count)
        }
        
        init(_ type:SettingType, _ minute: UInt16){
            self.type = type
            value = minute.toUInt8Array()
            length = 1 + UInt16(value.count)
            
        }
        
        init(_ type:SettingType,_ color: UIColor){
            self.type = type
            value.append(0)
            value.append(contentsOf: color.toUInt32().toUInt8Array())
            length = 1 + UInt16(value.count)
        }
        
        init(_ type:SettingType,_ localName: String){
            self.type = type
            let nameArray = localName.toUInt8Array()
            var size: UInt8 = 0
            for m in nameArray{
                if m != 0{
                    size += 1
                }
            }
            value.append(size)
            value.append(contentsOf: nameArray)
            length = 1 + UInt16(value.count)
        }
        
        func toUInt8Array() -> [UInt8]{
            var data = [UInt8]()
            data.append(cmd)
            data.append(contentsOf: length.toUInt8Array())
            data.append(type.rawValue)
            data.append(contentsOf: value)
            return data
        }
    }

}

