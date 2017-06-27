//
//  Pen2CommPasser.swift
//  NISDK3
//
//  Created by Aram Moon on 2017. 6. 8..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation

class Pen2CommParser {
    
    private let SEAL_SECTION_ID = 4
    weak var penDelegate: PenDelegate?
    weak var commManager : PenController!
    private var packetData: [UInt8] = []
    private var IsEscape: Bool = false
    
    //Offline Data
    var offlineTotalDataReceived: Int = 0
    var offlineTotalDataSize: Int = 0
    var cancelOfflineSync = false
    
    //Firmware Updata
    var fwFile: [UInt8] = []
    let UPDATE2_DATA_PACKET_SIZE: UInt32 = 2048
    var cancelFWUpdate = false
    
    init(penCommController manager: PenController) {
        commManager = manager
    }
    
    //MARK: Pen Data [UInt8], length
    func parsePen2Data(_ data: [UInt8], withLength length: Int) {
//        N.Log("Received:length = \(length)",data);
        for i in 0..<length {
            
            if data[i] == PACKET_START{
                
                packetData.removeAll()
                IsEscape = false

            }else if data[i] == PACKET_END{
                
                parsePen2DataPacket(packetData)
                IsEscape = false
                
            }else if data[i] == PACKET_DLE{
                IsEscape = true
                
            }else if IsEscape {
                packetData.append(data[i] ^ 0x20)
                IsEscape = false
                
            }else{
                packetData.append(data[i])
            }
        }
    }

    // Complet Packet [CMD, (error), length, Data]
    func parsePen2DataPacket(_ packet: [UInt8]) {
        let data: [UInt8] = packet
        guard let cmd = CMD(rawValue: data[0]) else{
            N.Log("CMD Error")
            return
        }
        var packetDataLength = Int(toUInt16(data[1],data[2]))
        var pos: Int = 3
        switch cmd {
        case .EVENT_PEN_DOTCODE:
            let len = DotStruct1.length
            let packet_count: Int = packetDataLength / len
            for i in 0..<packet_count {
                if (len * (i + 1)) > packetDataLength {
                }
                let dot = DotStruct1.init(Array(data[pos..<pos+len]))
                pos += len
                penDelegate?.penData(.Type1, dot)
            }
        case .EVENT_PEN_DOTCODE2:
            let len = DotStruct2.length
            let packet_count: Int = packetDataLength / len
            for i in 0..<packet_count {
                if (len * (i + 1)) > packetDataLength {
                }
                let dot = DotStruct2.init(Array(data[pos..<pos+len]))
                pos += len
                penDelegate?.penData(.Type2, dot)
            }
            
        case .EVENT_PEN_DOTCODE3:
            let len = DotStruct3.length
            let packet_count: Int = packetDataLength / len
            for i in 0..<packet_count {
                if (len * (i + 1)) > packetDataLength {
                }
                let dot = DotStruct3.init(Array(data[pos..<pos+len]))
                pos += len
                penDelegate?.penData(.Type3, dot)
            }
        case .EVENT_PEN_UPDOWN:
            let len = PenUpDown.length
            let updownData = PenUpDown.init(Array(data[pos..<pos+len]))
            penDelegate?.penData(.UpDown, updownData)

        case .EVENT_PEN_NEWID:
            let len = PageNewId.length
            let PID = PageNewId.init(Array(data[pos..<pos+len]))
            penDelegate?.penData(.PIdChange, PID)

        case .EVENT_POWER_OFF:
            let powerOff = POWER_OFF.init(data[pos])
            if powerOff.reason == .Update {
                let msg = PenMessage.init(.PEN_FW_UPGRADE_STATUS, data: 100 as AnyObject)
                penDelegate?.penMessage(msg)
            }else{
                let msg = PenMessage.init(.EVENT_POWER_OFF, data: nil)
                penDelegate?.penMessage(msg)
            }
            commManager?.disConnect()

        case .EVENT_BATT_ALARM:
            pos += 1
            let battLevel = BatterAlarm.init(data[pos])
            let msg = PenMessage.init(.EVENT_LOW_BATTERY, data: battLevel as AnyObject)
            penDelegate?.penMessage(msg)

        case .RES1_OFFLINE_DATA_INFO:
            //error code
            pos += 1
            packetDataLength = Int(toUInt16(data[2],data[3]))
            
            N.Log("Res1 offline data info error code : \(data[1]), \((data[1] == 0) ? "Success" : "Fail")")
            if (data[1] != 0) || (packetData.count < (packetDataLength + 4)) {
                N.Log("OfflineFileStatus fail")
                let msg = PenMessage.init(.OFFLINE_DATA_SEND_FAILURE, data: nil)
                penDelegate?.penMessage(msg)
                return
            }
            let offlineInfo = OfflineInfo(Array(data[pos..<pos+OfflineInfo.length]))
            offlineTotalDataReceived = 0
            offlineTotalDataSize = Int(offlineInfo.dataSize)
            let msg = PenMessage.init(.OFFLINE_DATA_SEND_START, data: nil)
            penDelegate?.penMessage(msg)
            N.Log("Res1 offline data info:", offlineInfo)
            
        //TODO: Offline Data
        case .REQ2_OFFLINE_DATA:

            let offlineData = OffLineData(Array(data[pos..<pos+OffLineData.length]))
            pos += OffLineData.length
            N.Log(offlineData)
            
            if offlineData.isZip != 0 {
                let zippedData: [UInt8] = Array(data[pos..<(pos+Int(offlineData.sizeAfterZip))])
                N.Log("ZipSize", zippedData.count)
                let inflater = InflateStream()
                let (penData, error) = inflater.write(bytes: zippedData, flush: true)
                
                if error == nil {
                    // GOOD
                    N.Log("Offline zip file received successfully")
                    parseSDK2OfflinePenData(penData, offlineData)
                    
                    if !cancelOfflineSync {
                        requestOfflineDataAck(offlineData.packetId, .Success, .Continue)
                    }
                    else {
                        requestOfflineDataAck(offlineData.packetId, .Success, .Stop)
                    }
                }
                else {
                    // BAD
                    N.Log("Offline zip file received badly, OfflineFileStatus fail", error ?? "error is empty")
                    //                    notifyOfflineDataStatus(OFFLINE_DATA_RECEIVE_FAIL, percent: 0.0)
                    if !cancelOfflineSync {
                        requestOfflineDataAck(offlineData.packetId, .fail, .Continue)
                    }
                    else {
                        requestOfflineDataAck(offlineData.packetId, .fail, .Stop)
                    }
                }
            }
            else {
                let penData: [UInt8] = Array(data[pos..<(pos+Int(offlineData.sizeBeforeZip))])
                parseSDK2OfflinePenData(penData, offlineData)
                
                if !cancelOfflineSync {
                    offlineTotalDataReceived += Int(offlineData.sizeBeforeZip)
                    requestOfflineDataAck(offlineData.packetId, .Success, .Continue)
                }
                else {
                    requestOfflineDataAck(offlineData.packetId, .Success, .Stop)
                }
            }
            
            if offlineData.trasPosition == .End {
                N.Log("OFFLINE_DATA_RECEIVE_END")
                //                notifyOfflineDataStatus(OFFLINE_DATA_RECEIVE_END, percent: 100.0)
            }
            else {
                let percent = Float(offlineTotalDataReceived * 100) / Float(offlineTotalDataSize)
                //                notifyOfflineDataStatus(OFFLINE_DATA_RECEIVE_PROGRESSING, percent: percent)
                N.Log("OFFLINE_DATA_RECEIVE Percent ", percent)
                
            }
        case .RES1_FW_FILE:
            //error code
            pos += 1
            packetDataLength = Int(toUInt16(data[2],data[3]))
            
            N.Log("Res1 FW File error code: \(data[1]), \((data[1] == 0) ? "Success" : "Fail")")
            if (data[1] != 0) || (packetData.count < (packetDataLength + 4)) {
                return
            }
            var transPermission: UInt8
            
            transPermission = data[pos]
            N.Log("transPermission: \(transPermission)")
            
            
        case .REQ2_FW_FILE:

            var status: UInt8
            var fileOffset: UInt32

            status = data[0]
            pos += 1
            N.Log("status:\(status), \((status != 3) ? "Success" : "Fail")")
            
            fileOffset = toUInt32(data, at: pos)
//            sendUpdateFileData2(at: fileOffset, andStatus: status)
            
        case .RES1_OFFLINE_NOTE_LIST:
            //error code
            pos += 1
            packetDataLength = Int(toUInt16(data[2],data[3]))
            
            N.Log("Res1 offline note list error code : \(data[1]), \((data[1] == 0) ? "Success" : "Fail")")
            if (data[1] != 0) || (packetData.count < (packetDataLength + 4)) {
                return
            }

            var sectionOwnerNoteId = [(UInt8,UInt32,UInt32)]()
            
            let setCount = toUInt16(data[pos], data[pos+1])
            if setCount == 0 {
                DispatchQueue.main.async(execute: {() -> Void in
                    let msg = PenMessage.init(.OFFLINE_DATA_NOTE_LIST, data: nil)
                    self.penDelegate?.penMessage(msg)
                })
                return
            }
            pos += 2
            for _ in 0..<setCount {
                let secOwnerID = toUInt32(data, at: pos)
                var section: UInt8 = 0
                var owner : UInt32 = 0
                (section,owner) = toSetionOwner(secOwnerID)
                
                pos += 4
                
                let noteId: UInt32 = toUInt32(data, at: pos)
                pos += 4
                sectionOwnerNoteId.append((section,owner,noteId))
            }

            if sectionOwnerNoteId.count > 0 {
                N.Log("Getting offline File List finished")
                DispatchQueue.main.async(execute: {() -> Void in
                    let msg = PenMessage.init(.OFFLINE_DATA_NOTE_LIST, data: sectionOwnerNoteId as AnyObject)
                    self.penDelegate?.penMessage(msg)
                })
            }
        case .RES2_OFFLINE_PAGE_LIST:
            //error code
            
            pos += 1
            packetDataLength = Int(toUInt16(data[2],data[3]))
            
            N.Log("Res2 offline page list error code : \(data[1]), \((data[1] == 0) ? "Success" : "Fail")")
            if (data[1] != 0) || (packetData.count < (packetDataLength + 4)) {
                return
            }
            _ = toUInt32(data, at: pos) //secownerID
            pos += 4
            
            _ = toUInt32(data, at: pos) // NoteID
            pos += 4

            let pageCount = toUInt16(data[pos], data[pos+1])
            pos += 2
            
            var pageIdArray = [UInt32]()
            for _ in 0..<pageCount {
                let pageId = toUInt32(data, at: pos)
                pageIdArray.append(pageId)
                pos += 4
            }
            DispatchQueue.main.async(execute: {() -> Void in
                let msg = PenMessage.init(.OFFLINE_DATA_PAGE_LIST, data: pageIdArray as AnyObject)
                self.penDelegate?.penMessage(msg)
            })
        case .RES_SET_NOTE_LIST:
            //error code
            
            pos += 1
            packetDataLength = Int(toUInt16(data[2],data[3]))
            
            N.Log("Res set note list error code : \(data[1]), \((data[1] == 0) ? "Success" : "Fail")")
            if data[1] != 0 {
                return
            }
            else if data[1] == 0 {

            }
        case .RES_DEL_OFFLINE_DATA:
            //error code
            
            pos += 1
            packetDataLength = Int(toUInt16(data[2],data[3]))
            
            N.Log("Res delete offline data error code : \(data[1]), \((data[1] == 0) ? "Success" : "Fail")")
            if (data[1] != 0) || (packetData.count < (packetDataLength + 4)) {
                return
            }

            let noteCount = data[pos]
            //deleted note count
            pos += 1
            if noteCount > 0 {
                for _ in 0..<noteCount {
                    
                    let note_ID = toUInt32(data,at: pos)
                    N.Log("note Id deleted \(note_ID)")
                    pos += 4
                }
            }

        case .RES_SET_PEN_STATE:
            //error code
            pos += 1
            packetDataLength = Int(toUInt16(data[2],data[3]))
            let error = ErrorCode(rawValue: data[1])
            if error != ErrorCode.Success {
                N.Log("Setting fail")
                return
            }

        case .RES_VERSION_INFO:
            //error code
            pos += 1
            packetDataLength = Int(toUInt16(data[2],data[3]))
            if data[1] != 0 {
                return
            }
            
            if (packetData.count < (packetDataLength + 4)) {
                return
            }
            
            let len = PenVerionInfo.length
            let penInfo = PenVerionInfo.init(Array(data[pos..<pos+len]))
            N.Log("PenInfo", penInfo)
            requestPenSettingInfo()
            
        case .RES_COMPARE_PWD:
            var request = PenPasswordRequestStruct()
            //error code
            
            pos += 1
            packetDataLength = Int(toUInt16(data[2],data[3]))
            
            N.Log("Res compare password error code : \(data[1]), \((data[1] == 0) ? "Success" : "Fail")")
            if (data[1] != 0) || (packetData.count < (packetDataLength + 4)) {
                return
            }
            
            var status: UInt8
            var retryCount: UInt8
            var maxCount: UInt8
            
            status = data[pos]
            pos += 1
            
            retryCount = data[pos]
            pos += 1
            
            maxCount = data[pos]
            if status == 1 {
//                setAllNoteIdList2()
            }
            else {
//                penExchangeDataReady = true
//                penCommUpDownDataReady = true
//                penCommIdDataReady = true
//                penCommStrokeDataReady = true
//                parsePenPasswordRequest(UInt8(request), withLength: MemoryLayout<PenPasswordRequestStruct>.size)
            }
        case .RES_CHANGE_PWD:
            var response = PenPasswordChangeResponseStruct()
            //error code
            
            pos += 1
            packetDataLength = Int(toUInt16(data[2],data[3]))
            
            N.Log("Res change password error code : \(data[1]), \((data[1] == 0) ? "Success" : "Fail")")
            if (data[1] != 0) || (packetData.count < (packetDataLength + 4)) {
                return
            }

            var retryCount: UInt8
            var maxCount: UInt8
            
            retryCount = data[pos]
            pos += 1
            
            maxCount = data[pos]
            response.passwordState = data[1]
//            parsePenPasswordChangeResponse(UInt8(response), withLength: MemoryLayout<PenPasswordChangeResponseStruct>.size)

        case .RES_PEN_STATE:

            //error code
            pos += 1
            packetDataLength = Int(toUInt16(data[2],data[3]))
            if data[1] != 0 {
                return
            }
            
            if (packetData.count < (packetDataLength + 4)) {
                return
            }
            
            let len = PenStateStruct.length
            let penState = PenStateStruct.init(Array(data[pos..<pos+len]), .Version2)
            let msg = PenMessage.init(.PEN_STATUS, data: penState as AnyObject)
            penDelegate?.penMessage(msg)

        default:
            N.Log("Not implemented CMD", data[0].hexString(), cmd )
        }
    }

    
    // MARK: - Send data SDK2.0
    func requestVersionInfo() {
        let request = REQ.VersionInfo()
        let data = request.toUInt8Array().toData()
        N.Log("version info 0x01 data", data)
        commManager.writePen2SetData(data)
    }
    
    func requestComparePasswordSDK2(_ pinNumber: String) {
        let request = REQ.PenPassword(pinNumber)
        let data = request.toUInt8Array().toData()
        N.Log("compare password 0x02 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    func requestPasswordSDK2(_ pinNumber: String) {
        requestChangePasswordSDK2From("0000",to: pinNumber)
    }
    
    func requestChangePasswordSDK2From(_ curNumber: String, to pinNumber: String) {
        let request = REQ.ChangePenPassword(curNumber,to: pinNumber)
        let data = request.toUInt8Array().toData()
        
        N.Log("request Password Change 0x03 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    func requestPenSettingInfo() {
        let request = REQ.PenSettingInfo()
        let data = request.toUInt8Array().toData()

        N.Log("Request penState 0x04 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    //MARK: Set PenSetting
    func requestSetPenTime() {
        let timeInMiliseconds: TimeInterval = Date().timeIntervalSince1970 * 1000
        let timeStamp = UInt64(timeInMiliseconds)
        let request = REQ.PenStatus.init(.TimeStamp, timeStamp)
        let data = request.toUInt8Array().toData()
        N.Log("setPenState 0x5 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    func requestSetPenAutoPowerOffTime(_ minute : UInt16) {
        let request = REQ.PenStatus.init(.AutoPowerOffTime, minute)
        let data = request.toUInt8Array().toData()
        N.Log("setPenState 0x5 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    func requestSetPenCapOff(onoff : OnOff) {
        let request = REQ.PenStatus.init(.PenCapOff, onoff)
        let data = request.toUInt8Array().toData()
        N.Log("setPenState 0x5 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    func requestSetPenAutoPowerOn(_ onoff : OnOff) {
        let request = REQ.PenStatus.init(.AutoPowerOn, onoff)
        let data = request.toUInt8Array().toData()
        N.Log("setPenState 0x5 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    func requestSetPenBeep(_ onoff : OnOff) {
        let request = REQ.PenStatus.init(.BeepOnOff, onoff)
        let data = request.toUInt8Array().toData()
        N.Log("setPenState 0x5 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    func requestSetPenHober(_ onoff : OnOff) {
        let request = REQ.PenStatus.init(.HoverOnOff, onoff)
        let data = request.toUInt8Array().toData()
        N.Log("setPenState 0x5 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    func requestSetPenOfflineSave(_ onoff : OnOff) {
        let request = REQ.PenStatus.init(.OfflineSave, onoff)
        let data = request.toUInt8Array().toData()
        N.Log("setPenState 0x5 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    func setPenStatePenLEDColor(_ color: UIColor) {
        let request = REQ.PenStatus.init(.PenLEDColor, color)
        let data = request.toUInt8Array().toData()
        N.Log("setPenState 0x5 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    func requestSetPenUSBMode(_ mode : PenStateStruct.USBMode) {
        let request = REQ.PenStatus.init(.USBMode, mode)
        let data = request.toUInt8Array().toData()
        N.Log("setPenState 0x5 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    func requestSetPenPressure(_ pressure : UInt16){
        
    }

    
    func requestSetPenDownSampling(onoff : OnOff) {
        let request = REQ.PenStatus.init(.DownSampling, onoff)
        let data = request.toUInt8Array().toData()
        N.Log("setPenState 0x5 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    func requestSetPenDownSampling(_ name : String) {
        let request = REQ.PenStatus.init(.LocalName, name)
        let data = request.toUInt8Array().toData()
        N.Log("setPenState 0x5 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    
    /// All Note Using
    func requestUsingAllNote() {
        let data = REQ.UsingNoteAll().toUInt8Array().toData()
        N.Log("set UsingNote All 0x11 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    /// Array(SectionId, OwnerId, NoteId)
    func requestUsingNote(SectionOwnerNoteList list :[(UInt8,UInt32,UInt32)]) {
        let noteIdList = REQ.UsingNote(SectionOwnerNoteList: list)
        let data = noteIdList.toUInt8Array().toData()
        N.Log("set UsingNote List 0x11 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    /// Offline Note List
    func requestOfflineNoteList() {
        let request = REQ.OfflineNoteList()
        let data = request.toUInt8Array().toData()
        N.Log("requestOfflineFileList2 0x21 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    
    /// Offline Page List
    func requestOfflinePageList(_ section : UInt8, _ owner: UInt32, _  note: UInt32) {
        let request = REQ.OfflinePageList(section, owner, note)
        let data = request.toUInt8Array().toData()
        N.Log("requestOfflinePageListSectionOwnerId 0x22 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    /// Offline note or page unit
    func requestOfflineData(_ section: UInt8,_ owner: UInt32,_ note: UInt32,_ pageList: [UInt32]?) {
        let request = REQ.OfflineData(section, owner, note, pageList)
        let data = request.toUInt8Array().toData()
        N.Log("requestOfflineData2WithOwnerId 0x23 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    /// Offline Ack after OfflineData request
    func requestOfflineDataAck(_ packetId: UInt16,_ errCode: ErrorCode, _ transOption: REQ.OfflineAckTransOP) {
        let request = REQ.OfflineDataAck(packetId, errCode, transOption)
        let data = request.toUInt8Array().toData()
        N.Log("response2AckToOfflineDataWithPacketID 0xA4 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    func requestDeleteOfflineData(_ section: UInt8,_ owner: UInt32,_ noteList: [UInt32]) {
        let request = REQ.DeleteOfflineData(section, owner, noteList)
        let data = request.toUInt8Array().toData()
        N.Log("requestDelOfflineFile2SectionOwnerId 0x25 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    /// Firmware Update
    func UpdateFirmwareirst(at fileUrl: URL,_ deviceName: String,_ fwVersion : String) {
        var request = REQ.FWUpdateFirst()
        request.deviceName = deviceName.toUInt8Array()
        request.fwVer = fwVersion.toUInt8Array()
        do {
            fwFile = Array(try Data.init(contentsOf: fileUrl))
            request.fileSize = UInt32(fwFile.count)
            request.packetSize = UPDATE2_DATA_PACKET_SIZE
            request.dataZipOpt = 1
            request.nCheckSum = checkSum(fwFile)
            let data = request.toUInt8Array().toData()
            N.Log("sendUpdateFileInfo2AtUrl 0x31 data \(data)")
            commManager.writePen2SetData(data)
        } catch {
            N.Log("firmware File Error")
        }
    }
    
    func checkSum(_ fileData: [UInt8]) -> UInt8 {
        var Sum: UInt32 = 0
        for data in fileData {
            Sum += UInt32(data)
        }
        return (UInt8(Sum & 0xff))
    }
    
    func updateFirmwareSecond(at fileOffset: UInt32, andStatus status: UInt8) {
        var request = REQ.FWUpdateSecond()
        var zipFileData: [UInt8] = []
        if (fileOffset + UPDATE2_DATA_PACKET_SIZE) > UInt32(fwFile.count) {
            request.sizeBeforeZip = UInt16(UInt32(fwFile.count) - fileOffset)
        }
        else {
            request.sizeBeforeZip = UInt16(UPDATE2_DATA_PACKET_SIZE)
        }
        let dividedData = Array(fwFile[Int(fileOffset)..<Int(request.sizeBeforeZip)])
        //TODO: Make ZipData
        // zipFileData =
        request.fileData = zipFileData
        request.sizeAfterZip = UInt16(zipFileData.count)
        request.fileData = zipFileData
        if status == 3 {
            request.error = 3
//            notifyFWUpdate(FW_UPDATE_DATA_RECEIVE_FAIL, percent: 0.0)
            N.Log("FW_UPDATE_DATA_RECEIVE_FAIL")
        }
        else {
            request.error = 0
        }
        request.length = request.sizeAfterZip + 14
        //0: continue, 1: stop
        if !cancelFWUpdate {
            request.transContinue = 0
        }
        else {
            request.transContinue = 1
        }
        request.nChecksum = checkSum(dividedData)

        let data = request.toUInt8Array().toData()
        N.Log("sendUpdateFileInfo2AtUrl 0xB2 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    ///Offline Parser
    //SDK2.0
    func parseSDK2OfflinePenData(_ penData: [UInt8], _ offlineData: OffLineData) {
        var offlineData = offlineData
        print("parseSDK2OfflinePenData \(offlineData)")
        var pos: Int = 0
        for _ in 0..<offlineData.nNumOfStrokes {
            var stroke = OffLineStroke(Array(penData[pos..<pos+Int(OffLineStroke.length)]))
            pos += OffLineStroke.length
            
            for _ in 0..<Int(stroke.dotCount){
                let dot =  OffLineDot(Array(penData[pos..<pos+Int(OffLineDot.length)]))
                pos += OffLineDot.length
                if dot.CalCheckSum == dot.nCheckSum{
                    stroke.dotArray.append(dot)
                }
            }
            offlineData.strokeArray.append(stroke)
        }
        
        let msg = PenMessage.init(.OFFLINE_DATA_SEND_SUCCESS, data: offlineData as AnyObject)
        penDelegate?.penMessage(msg)
    }
    

}
