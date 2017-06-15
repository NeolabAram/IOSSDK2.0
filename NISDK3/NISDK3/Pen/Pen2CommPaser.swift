//
//  Pen2CommPasser.swift
//  NISDK3
//
//  Created by Aram Moon on 2017. 6. 8..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation

var IsEscape: Bool = false

extension PenCommParser{
    
    //MARK: Pen Data [UInt8], length
    func parsePen2Data(_ data: [UInt8], withLength length: Int) {
//        N.Log("Received:length = \(length)");
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
                
            }else{
                packetData.append(data[i])
            }
        }
    }

    
    func parsePen2DataPacket(_ data: [UInt8]) {
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
                penDelegate?.dataDot(.Type1, dot)
            }
        case .EVENT_PEN_DOTCODE2:
            let len = DotStruct2.length
            let packet_count: Int = packetDataLength / len
            for i in 0..<packet_count {
                if (len * (i + 1)) > packetDataLength {
                }
                let dot = DotStruct2.init(Array(data[pos..<pos+len]))
                pos += len
                penDelegate?.dataDot(.Type2, dot)
            }
            
        case .EVENT_PEN_DOTCODE3:
            let len = DotStruct3.length
            let packet_count: Int = packetDataLength / len
            for i in 0..<packet_count {
                if (len * (i + 1)) > packetDataLength {
                }
                let dot = DotStruct3.init(Array(data[pos..<pos+len]))
                pos += len
                penDelegate?.dataDot(.Type3, dot)
            }
        case .EVENT_PEN_UPDOWN:
            let len = COMM_PENUP_DATA.length
            let updownData = COMM_PENUP_DATA.init(Array(data[pos..<pos+len]))
            penDelegate?.dataDot(.UpDown, updownData)

        case .EVENT_PEN_NEWID:
            let len = CHANGEDID2_DATA.length
            let PID = CHANGEDID2_DATA.init(Array(data[pos..<pos+len]))
            penDelegate?.dataDot(.PIdChange, PID)

        case .EVENT_POWER_OFF:
            let powerOff = POWER_OFF.init(data[pos])
            if powerOff.reason == .Update {
                let msg = PenMessage.init(.PEN_FW_UPGRADE_STATUS, data: 100 as AnyObject)
                penDelegate?.deviceMessage(msg)
//                notifyFWUpdateStatus(FW_UPDATE_DATA_RECEIVE_END, percent: 100)
            }

        case .EVENT_BATT_ALARM:
            pos += 1
            let battLevel = Int(data[pos]) as AnyObject
            let msg = PenMessage.init(.EVENT_LOW_BATTERY, data: battLevel)
            penDelegate?.deviceMessage(msg)

        case .RES1_OFFLINE_DATA_INFO:
            //error code
            pos += 1
            packetDataLength = Int(toUInt16(data[2],data[3]))
            
            N.Log("Res1 offline data info error code : \(data[1]), \((data[1] == 0) ? "Success" : "Fail")")
            if (data[1] != 0) || (packetData.count < (packetDataLength + 4)) {
                N.Log("OfflineFileStatus fail")
                let msg = PenMessage.init(.OFFLINE_DATA_SEND_FAILURE, data: nil)
                penDelegate?.deviceMessage(msg)
//                notifyOfflineDataStatus(OFFLINE_DATA_RECEIVE_FAIL, percent: 0.0)
                return
            }
            var strokeNum: UInt32
            var offlineDataSize: UInt32
            var isZipped: UInt8
            
            strokeNum = toUInt32(data, at : pos)
            pos += 4
            
            offlineDataSize = toUInt32(data, at : pos)
            pos += 4
            isZipped = data[pos]
            offlineTotalDataReceived = 0
            offlineTotalDataSize = Int(offlineDataSize)
            let msg = PenMessage.init(.OFFLINE_DATA_SEND_START, data: nil)
            penDelegate?.deviceMessage(msg)
//            notifyOfflineDataStatus(OFFLINE_DATA_RECEIVE_START, percent: 0.0)
            N.Log("Res1 offline data info strokeNum:\(strokeNum), offlineDataSize: \(offlineDataSize) isZipped :\(isZipped)")
            /*
        case .REQ2_OFFLINE_DATA:
            var isZip: UInt8
            var trasPosition: UInt8
            var packetId: UInt16
            var sizeBeforeZip: UInt16
            var sizeAfterZip: UInt16
            var strokeCnt: UInt16
            var sectionOwnerId: UInt32
            var noteId: UInt32
            var offlineDataHeader: OffLineData2HeaderStruct
            
            range.length = 2
            packetData.getBytes(packetId, range: range)
            pos += 2
            
            range.length = 1
            packetData.getBytes(isZip, range: range)
            pos += 1
            
            range.length = 2
            packetData.getBytes(sizeBeforeZip, range: range)
            pos += 2
            
            packetData.getBytes(sizeAfterZip, range: range)
            pos += 2
            
            range.length = 1
            packetData.getBytes(trasPosition, range: range)
            pos += 1
            
            range.length = 4
            packetData.getBytes(sectionOwnerId, range: range)
            pos += 4
            
            range.length = 4
            packetData.getBytes(noteId, range: range)
            pos += 4
            
            range.length = 2
            packetData.getBytes(strokeCnt, range: range)
            pos += 2
            N.Log("isZip:\(isZip), sizeBeforeZip:\(sizeBeforeZip), sizeAfterZip:\(sizeAfterZip), transPos:\(trasPosition), sectionOwnerId:\(sectionOwnerId), noteId:\(noteId), storkCnt:\(strokeCnt)")
            N.Log("packetDataSize:\(packetData.count), zipped Data size:\(packetData.count - pos)")
            offlineDataHeader.nSectionOwnerId = sectionOwnerId
            offlineDataHeader.nNoteId = noteId
            offlineDataHeader.nNumOfStrokes = strokeCnt
            if isZip != 0 {
                let zippedData = Data(bytesNoCopy: CChar(packetData.bytes) + pos, length: sizeAfterZip, freeWhenDone: false)
                var penData = Data(length: sizeBeforeZip)
                var destLen: uLongf = penData.count
                let result: Int = uncompress
                OF(((penData.mutableBytes as? Bytef), destLen, (zippedData.bytes as? Bytef), sizeAfterZip))
                if result == Z_OK {
                    // GOOD
                    N.Log("Offline zip file received successfully")
                    if penData != nil {
                        offlineDataDelegate.parseSDK2OfflinePenData(penData, andOfflineDataHeader: offlineDataHeader)
                    }
                    offlineTotalDataReceived += sizeBeforeZip
                    if !cancelOfflineSync {
                        response2AckToOfflineData(withPacketID: packetId, errCode: 0, andTransOption: 1)
                    }
                    else {
                        response2AckToOfflineData(withPacketID: packetId, errCode: 0, andTransOption: 0)
                    }
                }
                else {
                    // BAD
                    N.Log("Offline zip file received badly, OfflineFileStatus fail")
                    notifyOfflineDataStatus(OFFLINE_DATA_RECEIVE_FAIL, percent: 0.0)
                    if !cancelOfflineSync {
                        response2AckToOfflineData(withPacketID: packetId, errCode: 1, andTransOption: 1)
                    }
                    else {
                        response2AckToOfflineData(withPacketID: packetId, errCode: 1, andTransOption: 0)
                    }
                }
            }
            else {
                if !cancelOfflineSync {
                    response2AckToOfflineData(withPacketID: packetId, errCode: 0, andTransOption: 1)
                }
                else {
                    response2AckToOfflineData(withPacketID: packetId, errCode: 0, andTransOption: 0)
                }
            }
            if trasPosition == 2 {
                notifyOfflineDataStatus(OFFLINE_DATA_RECEIVE_END, percent: 100.0)
            }
            else {
                let percent = Float(offlineTotalDataReceived * 100.0) / Float(offlineTotalDataSize)
                N.Log("_offlineTotalDataReceived:\(offlineTotalDataReceived) sizeBeforeZip:\(sizeBeforeZip), _offlineTotalDataSize:\(offlineTotalDataSize)")
                notifyOfflineDataStatus(OFFLINE_DATA_RECEIVE_PROGRESSING, percent: percent)
            }
        
        case RES1_FW_FILE:
            //error code
            
            packetData.getBytes(char1, range: range)
            pos += 1
            
            packetData.getBytes(char2, range: range)
            pos += 1
            
            packetData.getBytes(char3, range: range)
            pos += 1
            packetDataLength = ((Int(char3) << 8) & 0xff00) | (Int(char2) & 0xff)
            N.Log("Res1 FW File error code : \(char1), \((char1 == 0) ? "Success" : "Fail")")
            if (char1 != 0) || (packetData.count < (packetDataLength + 4)) {
                return
            }
            var transPermission: UInt8
            
            range.length = 1
            packetData.getBytes(transPermission, range: range)
            N.Log("transPermission: \(transPermission)")
        case REQ2_FW_FILE:
            
            packetData.getBytes(char1, range: range)
            pos += 1
            
            packetData.getBytes(char2, range: range)
            pos += 1
            packetDataLength = ((Int(char2) << 8) & 0xff00) | (Int(char1) & 0xff)
            var status: UInt8
            var fileOffset: UInt32
            
            range.length = 1
            packetData.getBytes(status, range: range)
            pos += 1
            N.Log("status:\(status), \((status != 3) ? "Success" : "Fail")")
            
            range.length = 4
            packetData.getBytes(fileOffset, range: range)
            sendUpdateFileData2(at: fileOffset, andStatus: status)
             */
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
                    self.penDelegate?.deviceMessage(msg)
                })
                return
            }
            pos += 2
            for i in 0..<setCount {
                let secownerID = toUInt32(data, at: pos)
                let section: UInt8 = UInt8(secownerID >> 24)
                let owner : UInt32 = secownerID & 0x00ffffff
                pos += 4
                
                let noteId: UInt32 = toUInt32(data, at: pos)
                pos += 4
                sectionOwnerNoteId.append((section,owner,noteId))
            }

            if sectionOwnerNoteId.count > 0 {
                N.Log("Getting offline File List finished")
                DispatchQueue.main.async(execute: {() -> Void in
                    let msg = PenMessage.init(.OFFLINE_DATA_NOTE_LIST, data: sectionOwnerNoteId as AnyObject)
                    self.penDelegate?.deviceMessage(msg)
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
            let secownerID = toUInt32(data, at: pos)
            let section: UInt8 = UInt8(secownerID >> 24)
            let owner : UInt32 = secownerID & 0x00ffffff
            pos += 4

            let pageCount = toUInt16(data[pos], data[pos+1])
            pos += 2
            
            var pageIdArray = [UInt32]()
            for i in 0..<pageCount {
                let pageId = toUInt32(data, at: pos)
                pageIdArray.append(pageId)
                pos += 4
            }
            DispatchQueue.main.async(execute: {() -> Void in
                let msg = PenMessage.init(.OFFLINE_DATA_PAGE_LIST, data: pageIdArray as AnyObject)
                self.penDelegate?.deviceMessage(msg)
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
            if data[1] != 0 {
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
            
            var deviceName = [UInt8](repeating: 0, count: 16)
            var fwVer = [UInt8](repeating: 0, count: 16)
            var protocolVer = [UInt8](repeating: 0, count: 8)
            var subName = [UInt8](repeating: 0, count: 16)
            var mac = [UInt8](repeating: 0, count: 6)
            var penType: UInt16

            deviceName = Array(data[pos..<(pos+16)])
            pos += 16
            
            fwVer = Array(data[pos..<(pos+16)])
            pos += 16
            
            protocolVer = Array(data[pos..<(pos+8)])
            protocolVerStr = String.init(data: Data(protocolVer),encoding: String.Encoding.ascii)!
            pos += 8
            
            subName = Array(data[pos..<(pos+16)])
            pos += 16
            
            penType = toUInt16(data[pos], data[pos+1])
            pos += 2
            
            mac = Array(data[pos..<(pos+6)])
            
            if let dName = String.init(data: Data(deviceName), encoding: String.Encoding.utf8), let sName = String.init(data: Data(subName), encoding: String.Encoding.utf8) {
                N.Log(deviceName,fwVer,protocolVerStr, dName, sName)

            }else{
                N.Log(deviceName,fwVer,protocolVerStr)
            }

            setRequestPenState()
            /*
        case .RES_COMPARE_PWD:
            var request = PenPasswordRequestStruct()
            //error code
            
            packetData.getBytes(char1, range: range)
            pos += 1
            
            packetData.getBytes(char2, range: range)
            pos += 1
            
            packetData.getBytes(char3, range: range)
            pos += 1
            packetDataLength = ((Int(char3) << 8) & 0xff00) | (Int(char2) & 0xff)
            N.Log("Res compare password error code : \(char1), \((char1 == 0) ? "Success" : "Fail")")
            if (char1 != 0) || (packetData.count < (packetDataLength + 4)) {
                if request != nil {
                    free(request)
                }
                return
            }
            var status: UInt8
            var retryCount: UInt8
            var maxCount: UInt8
            
            packetData.getBytes(status, range: range)
            //request->status = status;
            pos += 1
            
            packetData.getBytes(retryCount, range: range)
            request?.retryCount = retryCount
            pos += 1
            
            packetData.getBytes(maxCount, range: range)
            request?.resetCount = maxCount
            if status == 1 {
                setNoteIdList()
                if request != nil {
                    free(request)
                }
            }
            else {
                penExchangeDataReady = true
                penCommUpDownDataReady = true
                penCommIdDataReady = true
                penCommStrokeDataReady = true
                parsePenPasswordRequest(UInt8(request), withLength: MemoryLayout<PenPasswordRequestStruct>.size)
            }
        case RES_CHANGE_PWD:
            response = malloc(MemoryLayout<PenPasswordChangeResponseStruct>.size)
            //error code
            
            packetData.getBytes(char1, range: range)
            pos += 1
            
            packetData.getBytes(char2, range: range)
            pos += 1
            
            packetData.getBytes(char3, range: range)
            pos += 1
            packetDataLength = ((Int(char3) << 8) & 0xff00) | (Int(char2) & 0xff)
            N.Log("Res change password error code : \(char1), \((char1 == 0) ? "Success" : "Fail")")
            if (char1 != 0) || (packetData.count < (packetDataLength + 4)) {
                if response != nil {
                    free(response)
                }
                return
            }
            var retryCount: UInt8
            var maxCount: UInt8
            
            packetData.getBytes(retryCount, range: range)
            pos += 1
            
            packetData.getBytes(maxCount, range: range)
            response?.passwordState = char1
            parsePenPasswordChangeResponse(UInt8(response), withLength: MemoryLayout<PenPasswordChangeResponseStruct>.size)
            if response != nil {
                free(response)
            }
             */
        case .RES_PEN_STATE:

            var penState = PenStateStruct()
            var penStatus2 = PenState2Struct()
            //error code
            pos += 1
            packetDataLength = Int(toUInt16(data[2],data[3]))
            if data[1] != 0 {
                return
            }
            
            if (packetData.count < (packetDataLength + 4)) {
                return
            }
            var timeTick: UInt64
            var autoPwrOffTime: UInt16
            var pressure_Max: UInt16
            var lock: UInt8
            var maxRetryCnt: UInt8
            var retryCnt: UInt8
            var memory_Used: UInt8
            var usePenCapOnOff: UInt8
            var usePenTipOnOff: UInt8
            var beepOnOff: UInt8
            var useHover: UInt8
            var battLevel: UInt8
            var offlineOnOff: UInt8
            var fsrStep: UInt8
            var usbMode: UInt8
            var downSampling: UInt8
            var btLocalName = [UInt8](repeating: 0, count: 16)
            var localName: String
            
            lock = data[pos]
            pos += 1
            
            maxRetryCnt = data[pos]
            pos += 1
            
            retryCnt = data[pos]
            pos += 1
            
            timeTick = toUInt64(data, at: pos)
            penState.timeTick = timeTick
            penStatus2.timeTick = timeTick
            pos += 8
            

            autoPwrOffTime = toUInt16(data[pos], data[pos+1])
            penState.autoPwrOffTime = autoPwrOffTime
            penStatus2.autoPwrOffTime = autoPwrOffTime
            pos += 2
            
            pressure_Max = toUInt16(data[pos], data[pos+1])
            penState.pressureMax = UInt8(pressure_Max & 0xff)
            pressureMax2 = Int(pressure_Max)
            pos += 2
            

            penState.memoryUsed = data[pos]
            pos += 1
            
            penStatus2.usePenCapOnOff = data[pos]
            pos += 1
            //auto power on
            
            penState.usePenTipOnOff = data[pos]
            penStatus2.usePenTipOnOff = data[pos]
            pos += 1
            
            penState.beepOnOff = data[pos]
            penStatus2.beepOnOff = data[pos]
            pos += 1
            
            penState.useHover = data[pos]
            penStatus2.useHover = data[pos]
            pos += 1
            
            penState.battLevel = data[pos]
            pos += 1
            
            penStatus2.offlineOnOff = data[pos]
            pos += 1
            
            fsrStep = data[pos]
            penState.penPressure = UInt16(fsrStep)
            penStatus2.penPressure = fsrStep
            pos += 1
            if packetData.count > pos {
                
                penStatus2.usbMode = data[pos]
                pos += 1
                
                penStatus2.downSampling = data[pos]
                pos += 1
                if packetData.count > (pos + 16) {
                    
                    btLocalName = Array(data[pos..<pos+16])
                    let lName = String(data: Data(btLocalName), encoding: String.Encoding.utf8)
                    if let name = lName {
                        localName = name
                    }
                }
            }
            else if data[1] == 0 {
                N.Log("PenStatus PassWord Process skip")
//                parsePenStatusData(penState)
//                if !commManager.initialConnect {
//                    if lock == 1 {
//                        if passwdCounter == 0 {
//                            // try "0000" first in case when app does not recognize that pen has been reset
//                            N.Log("[PenCommParser] 1. try \"0000\" first")
//                            comparePasswordSDK2 = "0000"
//                            commManager.hasPenPassword = false
//                            passwdCounter += 1
//                        }
//                        else {
//                            let password: String = MyFunctions.loadPasswd()
//                            comparePasswordSDK2 = password
//                            commManager.hasPenPassword = true
//                        }
//                    }
//                    else if lock == 0 {
//                        commManager.hasPenPassword = false
//                        setNoteIdList()
//                    }
//                    commManager.initialConnect = true
//                }
            }
        default:
            N.Log("Not implemented CMD", data[0].hexString(), cmd )
        }
    }

    
    // MARK: - Send data SDK2.0

    func setVersionInfo() {
        var setpenInfo = SetVersionInfoStruct()
        
        var tempPacketData = [UInt8]()
        tempPacketData.append(setpenInfo.cmd)
        tempPacketData.append(contentsOf: setpenInfo.length.toUInt8Array())
        tempPacketData.append(contentsOf: setpenInfo.connectionCode)
        tempPacketData.append(contentsOf: setpenInfo.appType)
        setpenInfo.appVer = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)!.toUInt8Array()
        tempPacketData.append(contentsOf: setpenInfo.appVer)
        
        let wholePacketData = makeWholePacket(tempPacketData)
        let data = Data(wholePacketData)
        N.Log("version info 0x01 data", data.hexString())
        commManager.writePen2SetData(data)
    }
    
    func setComparePasswordSDK2(_ pinNumber: String) {
        var penPassword = SetPenPasswordStruct()
        var tempPacketData = [UInt8]()
        tempPacketData.append(penPassword.cmd)
        // - 2;
        tempPacketData.append(contentsOf: penPassword.length.toUInt8Array())
        penPassword.password = pinNumber.toUInt8Array()
        tempPacketData.append(contentsOf: penPassword.password)
        
        let wholePacketData = makeWholePacket(tempPacketData)
        let data = Data(wholePacketData)
        N.Log("compare password 0x02 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    func setPasswordSDK2(_ pinNumber: String) {
        setChangePasswordSDK2From("0000",to: pinNumber)
    }
    
    func setChangePasswordSDK2From(_ curNumber: String, to pinNumber: String) {
        var changePenPassword = SetChangePenPasswordStruct()
        
        var tempPacketData = [UInt8]()
        tempPacketData.append(changePenPassword.cmd)
        tempPacketData.append(contentsOf: changePenPassword.length.toUInt8Array())
        tempPacketData.append(changePenPassword.usePwd)
        
        changePenPassword.oldPassword = curNumber.toUInt8Array()
        tempPacketData.append(contentsOf: changePenPassword.oldPassword)
        
        changePenPassword.newPassword = pinNumber.toUInt8Array()
        tempPacketData.append(contentsOf: changePenPassword.newPassword)
        
        let wholePacketData = makeWholePacket(tempPacketData)
        let data = Data(wholePacketData)
        N.Log("setPasswordSDK2 0x03 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    func setRequestPenState() {
        let req = SetRequestPenStateStruct()
        var tempPacketData = [UInt8]()
        tempPacketData.append(req.cmd)
        tempPacketData.append(contentsOf: req.length.toUInt8Array())
        
        let wholePacketData = makeWholePacket(tempPacketData)
        let data = Data(wholePacketData)
        N.Log("setRequest penState 0x04 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    func setPenState2(_ type: UInt8, andValue value: UInt8) {
        var cmd: UInt8
        var length: UInt16
        var tempPacketData = [UInt8]()
        cmd = 0x05
        tempPacketData.append(cmd)
        length = 2
        tempPacketData.append(contentsOf: length.toUInt8Array())
        tempPacketData.append(type)
        tempPacketData.append(value)
        let wholePacketData = makeWholePacket(tempPacketData)
        let data = Data(wholePacketData)
        N.Log("setPenState2WithType 0x5 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    
    func setPenState2WithTypeAndTimeStamp() {
        var type: UInt8
        var length: UInt16
        var timeStamp: UInt64
        var tempPacketData = [UInt8]()
        let cmd: UInt8 = 0x05
        tempPacketData.append(cmd)
        length = 9
        tempPacketData.append(contentsOf: length.toUInt8Array())
        type = 1
        tempPacketData.append(type)
        let timeInMiliseconds: TimeInterval = Date().timeIntervalSince1970 * 1000
        timeStamp = UInt64(timeInMiliseconds)
        tempPacketData.append(contentsOf: timeStamp.toUInt8Array())
        
        let wholePacketData = makeWholePacket(tempPacketData)
        let data = Data(wholePacketData)
        N.Log("setPenState2WithTypeAndTimeStamp 0x5 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    func setPenState2WithTypeAndAutoPwrOffTime(_ autoPwrOffTime: UInt16) {
        var type: UInt8
        var length: UInt16
        var tempPacketData = [UInt8]()
        let cmd: UInt8 = 0x05
        tempPacketData.append(cmd)
        length = 3
        tempPacketData.append(contentsOf: length.toUInt8Array())
        type = 2
        tempPacketData.append(type)
        tempPacketData.append(contentsOf: autoPwrOffTime.toUInt8Array())
        let wholePacketData = makeWholePacket(tempPacketData)
        let data = Data(wholePacketData)
        N.Log("setPenState2WithTypeAndAutoPwrOffTime 0x5 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    func setPenState2WithTypeAndRGB(_ color: UInt32, tType: UInt8) {
        var cmd: UInt8
        var type: UInt8
        var length: UInt16
        var tempPacketData = [UInt8]()
        cmd = 0x05
        tempPacketData.append(cmd)
        length = 6
        tempPacketData.append(contentsOf: length.toUInt8Array())
        type = 8
        tempPacketData.append(type)
        tempPacketData.append(tType)
        tempPacketData.append(contentsOf: color.toUInt8Array())
        let wholePacketData = makeWholePacket(tempPacketData)
        let data = Data(wholePacketData)
        N.Log("setPenState2WithTypeAndRGB 0x5 data \(data)")
        commManager.writePen2SetData(data)
    }
    
    func setPenState2WithTypeAndHover(_ useHover: UInt8) {
        
        var tempPacketData = [UInt8]()
        let cmd: UInt8 = 0x05
        tempPacketData.append(cmd)
        let length: UInt16 = 2
        tempPacketData.append(contentsOf: length.toUInt8Array())
        let type: UInt8 = 6
        tempPacketData.append(type)
        tempPacketData.append(useHover)
        let wholePacketData = makeWholePacket(tempPacketData)
        let data = Data(wholePacketData)
        N.Log("setPenState2WithTypeAndHover 0x5 data \(data)")
        commManager.writePen2SetData(data)
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
    
    func setAllNoteIdList2() {
        
        var tempPacketData = [UInt8]()
        let cmd: UInt8 = CMD.SET_NOTE_LIST.rawValue
        tempPacketData.append(cmd)
        let length = UInt16(2)
        tempPacketData.append(contentsOf: length.toUInt8Array())
        let count : UInt16 = 0xffff
        tempPacketData.append(contentsOf: count.toUInt8Array())
        
        let wholePacketData: [UInt8] = makeWholePacket(tempPacketData)
        let data = Data(wholePacketData)
        N.Log("setAllNoteIdList2 0x11 data \(data)")
        commManager.writePen2SetData(data)
    }
    /*
    func setNoteIdListSectionOwnerFromPList2() {
        let noteIdList2: SetNoteIdList2Struct
        var sof: UInt8
        var cmd: UInt8
        var eof: UInt8
        var length: UInt16
        var count: UInt16
        var sectionOwnerId: UInt32
        var note_Id: UInt32
        let dleData = [UInt8](repeating: 0, count: 1)
        let packetData = [UInt8](repeating: 0, count: 1)
        var section_id: UInt8
        var owner_id: UInt32
        let noteInfo = NPPaperManager.sharedInstance()
        let notesSupported: [Any] = noteInfo.notesSupported()
        var tempPacketData = Data()
        var filteredPacketData = Data()
        var wholePacketData = Data()
        cmd = 0x11
        tempPacketData.append(cmd, length: MemoryLayout<UInt8>.size)
        count = notesSupported.count
        length = MemoryLayout<noteIdList2>.size - MemoryLayout<cmd>.size - MemoryLayout<length>.size + count * 2 * MemoryLayout<UInt32>.size
        tempPacketData.append(length, length: MemoryLayout<UInt16>.size)
        tempPacketData.append(count, length: MemoryLayout<UInt16>.size)
        for note: [AnyHashable: Any] in notesSupported {
            section_id = CUnsignedChar((note["section"] as? NSNumber))
            owner_id = (UInt32)
            CUnsignedInt((note["owner"] as? NSNumber))
            sectionOwnerId = (section_id << 24) | owner_id
            tempPacketData.append(sectionOwnerId, length: MemoryLayout<UInt32>.size)
            note_Id = 0xffffffff
            tempPacketData.append(note_Id, length: MemoryLayout<UInt32>.size)
        }
        var tempDataBytes: [UInt8] = UInt8(tempPacketData.bytes)
        for i in 0..<tempPacketData.count {
            let int_data = Int(tempDataBytes[0] & 0xff)
            if (int_data == PACKET_START) || (int_data == PACKET_END) || (int_data == PACKET_DLE) {
                dleData[0] = PACKET_DLE
                filteredPacketData
                UInt8()
                packetData[0] = tempDataBytes[0] ^ 0x20
                filteredPacketData
                UInt8()
            }
            else {
                filteredPacketData
                UInt8()
            }
            tempDataBytes = tempDataBytes + 1
        }
        sof = PACKET_START
        wholePacketData.append(sof, length: MemoryLayout<UInt8>.size)
        wholePacketData.append(filteredPacketData.bytes, length: filteredPacketData.count)
        eof = PACKET_END
        wholePacketData.append(eof, length: MemoryLayout<UInt8>.size)
        var btMtu: Int
        let returnedMTU: Int = commManager.mtu
        if IS_OS_9_OR_LATER {
            btMtu = returnedMTU
        }
        else {
            btMtu = DEFAULT_BT_MTU
        }
        if wholePacketData.count > btMtu {
            let data = Data(data: wholePacketData)
            //N.Log(@"setNoteIdListSectionOwnerFromPList2 0x11 data %@", data);
            var dataLocation: Int = 0
            var dataLength: Int = 0
            while dataLocation < data.count {
                if (dataLocation + btMtu) > data.count {
                    dataLength = data.count - dataLocation
                }
                else {
                    dataLength = btMtu
                }
                let splitData = Data(bytesNoCopy: CChar(data.bytes) + dataLocation, length: dataLength, freeWhenDone: false)
                N.Log("setNoteIdListSectionOwnerFromPList2 0x11 data \(splitData)")
                commManager.writePen2SetData(splitData)
                Thread.sleep(forTimeInterval: 0.2)
                dataLocation += btMtu
            }
        }
        else {
            let data = Data(data: wholePacketData)
            //N.Log(@"setNoteIdListSectionOwnerFromPList2 0x11 data %@", data);
            commManager.writePen2SetData(data)
        }
    }
    
    func setNoteIdListFromPList2() {
        let noteIdList2: SetNoteIdList2Struct
        var sof: UInt8
        var cmd: UInt8
        var eof: UInt8
        var length: UInt16
        var count: UInt16
        var sectionOwnerId: UInt32
        var note_Id: UInt32
        let dleData = [UInt8](repeating: 0, count: 1)
        let packetData = [UInt8](repeating: 0, count: 1)
        var section_id: UInt8
        var owner_id: UInt32
        var noteIds: [Any]
        let noteInfo = NPPaperManager.sharedInstance()
        let notesSupported: [Any] = noteInfo.notesSupported()
        var tempPacketData = Data()
        var filteredPacketData = Data()
        var wholePacketData = Data()
        cmd = 0x11
        tempPacketData.append(cmd, length: MemoryLayout<UInt8>.size)
        count = 0
        for note: [AnyHashable: Any] in notesSupported {
            noteIds = (note["noteIds"] as? [Any])
            let noteIdCount = UInt16(noteIds.count)
            count += noteIdCount
        }
        length = MemoryLayout<noteIdList2>.size - MemoryLayout<cmd>.size - MemoryLayout<length>.size + count * 2 * MemoryLayout<UInt32>.size
        tempPacketData.append(length, length: MemoryLayout<UInt16>.size)
        tempPacketData.append(count, length: MemoryLayout<UInt16>.size)
        for note: [AnyHashable: Any] in notesSupported {
            section_id = CUnsignedChar((note["section"] as? NSNumber))
            owner_id = (UInt32)
            CUnsignedInt((note["owner"] as? NSNumber))
            sectionOwnerId = (section_id << 24) | owner_id
            noteIds = (note["noteIds"] as? [Any])
            let noteIdCount = UInt16(noteIds.count)
            for i in 0..<noteIdCount {
                tempPacketData.append(sectionOwnerId, length: MemoryLayout<UInt32>.size)
                note_Id = (UInt32)
                CUnsignedInt((noteIds[i] as? NSNumber))
                tempPacketData.append(note_Id, length: MemoryLayout<UInt32>.size)
            }
        }
        var tempDataBytes: [UInt8] = UInt8(tempPacketData.bytes)
        for i in 0..<tempPacketData.count {
            let int_data = Int(tempDataBytes[0] & 0xff)
            if (int_data == PACKET_START) || (int_data == PACKET_END) || (int_data == PACKET_DLE) {
                dleData[0] = PACKET_DLE
                filteredPacketData
                UInt8()
                packetData[0] = tempDataBytes[0] ^ 0x20
                filteredPacketData
                UInt8()
            }
            else {
                filteredPacketData
                UInt8()
            }
            tempDataBytes = tempDataBytes + 1
        }
        sof = PACKET_START
        wholePacketData.append(sof, length: MemoryLayout<UInt8>.size)
        wholePacketData.append(filteredPacketData.bytes, length: filteredPacketData.count)
        eof = PACKET_END
        wholePacketData.append(eof, length: MemoryLayout<UInt8>.size)
        var btMtu: Int
        let returnedMTU: Int = commManager.mtu
        if IS_OS_9_OR_LATER {
            btMtu = returnedMTU
        }
        else {
            btMtu = DEFAULT_BT_MTU
        }
        if wholePacketData.count > btMtu {
            let data = Data(data: wholePacketData)
            //N.Log(@"setNoteList 0x11 data %@", data);
            var dataLocation: Int = 0
            var dataLength: Int = 0
            while dataLocation < data.count {
                if (dataLocation + btMtu) > data.count {
                    dataLength = data.count - dataLocation
                }
                else {
                    dataLength = btMtu
                }
                let splitData = Data(bytesNoCopy: CChar(data.bytes) + dataLocation, length: dataLength, freeWhenDone: false)
                N.Log("setNoteList 0x11 splitData \(splitData)")
                commManager.writePen2SetData(splitData)
                Thread.sleep(forTimeInterval: 0.2)
                dataLocation += btMtu
            }
        }
        else {
            let data = Data(data: wholePacketData)
            //N.Log(@"setNoteIdListFromPList2 0x11 data %@", data);
            commManager.writePen2SetData(data)
        }
    }
    */
    func requestOfflineFileList2() -> Bool {
        if offlineFileProcessing {
            return false
        }
        offlineFileList.removeAll()
        offlineFileParsedList.removeAll()
        let tempPacketData = SetRequestOfflineFileListStruct().toUInt8Array()
        let wholePacketData: [UInt8] = makeWholePacket(tempPacketData)
        let data = Data(wholePacketData)
        N.Log("requestOfflineFileList2 0x21 data \(data)")
        commManager.writePen2SetData(data)
        return true
    }
    /*
    func requestOfflinePageListSectionOwnerId(_ sectionOwnerId: UInt32, andNoteId noteId: UInt32) -> Bool {
        if offlineFileProcessing {
            return false
        }
        var sof: UInt8
        var eof: UInt8
        let dleData = [UInt8](repeating: 0, count: 1)
        let packetData = [UInt8](repeating: 0, count: 1)
        var filteredPacketData = Data()
        var wholePacketData = Data()
        offlineFileList = [AnyHashable: Any]()
        offlineFileParsedList = [AnyHashable: Any]()
        var request: SetRequestOfflinePageListStruct
        request.cmd = 0x22
        request.length = MemoryLayout<request>.size - MemoryLayout<request.cmd>.size - MemoryLayout<request.length>.size
        // - 2;
        request.sectionOwnerId = sectionOwnerId
        request.noteId = noteId
        var tempPacketData = Data(bytes: request, length: MemoryLayout<request>.size)
        var tempDataBytes: [UInt8] = UInt8(tempPacketData.bytes)
        for i in 0..<tempPacketData.count {
            let int_data = Int(tempDataBytes[0] & 0xff)
            if (int_data == PACKET_START) || (int_data == PACKET_END) || (int_data == PACKET_DLE) {
                dleData[0] = PACKET_DLE
                filteredPacketData
                UInt8()
                packetData[0] = tempDataBytes[0] ^ 0x20
                filteredPacketData
                UInt8()
            }
            else {
                filteredPacketData
                UInt8()
            }
            tempDataBytes = tempDataBytes + 1
        }
        sof = PACKET_START
        wholePacketData.append(sof, length: MemoryLayout<UInt8>.size)
        wholePacketData.append(filteredPacketData.bytes, length: filteredPacketData.count)
        eof = PACKET_END
        wholePacketData.append(eof, length: MemoryLayout<UInt8>.size)
        let data = Data(data: wholePacketData)
        N.Log("requestOfflinePageListSectionOwnerId 0x22 data \(data)")
        commManager.writePen2SetData(data)
        return true
    }
    */
    
    /*
    func requestOfflineData2(withOwnerId ownerId: UInt32, noteId: UInt32, pageId pagesArray: [UInt32]) -> Bool {
        let noteList: [Any]? = (offlineFileList[Int(ownerId)] as? [Any])
        if noteList == nil {
            return false
        }
        if (noteList? as NSArray).index(of: Int(noteId)) == NSNotFound {
            return false
        }
        let request: SetRequestOfflineDataStruct
        var sof: UInt8
        var cmd: UInt8
        var eof: UInt8
        var transOption: UInt8
        var dataZipOption: UInt8
        var length: UInt16
        var sectionOwnerId: UInt32
        var note_Id: UInt32
        var pageCnt: UInt32
        var pageId: UInt32
        let dleData = [UInt8](repeating: 0, count: 1)
        let packetData = [UInt8](repeating: 0, count: 1)
        let count: Int = pagesArray.count
        var tempPacketData = Data()
        var filteredPacketData = Data()
        var wholePacketData = Data()
        cmd = 0x23
        tempPacketData.append(cmd, length: MemoryLayout<UInt8>.size)
        length = MemoryLayout<request>.size - MemoryLayout<cmd>.size - MemoryLayout<length>.size + count * MemoryLayout<pageCnt>.size
        tempPacketData.append(length, length: MemoryLayout<UInt16>.size)
        transOption = 1
        tempPacketData.append(transOption, length: MemoryLayout<UInt8>.size)
        dataZipOption = 1
        tempPacketData.append(dataZipOption, length: MemoryLayout<UInt8>.size)
        sectionOwnerId = ownerId
        tempPacketData.append(sectionOwnerId, length: MemoryLayout<UInt32>.size)
        note_Id = noteId
        tempPacketData.append(note_Id, length: MemoryLayout<UInt32>.size)
        if count != 0 {
            pageCnt = (UInt32)
        }
        else {
            pageCnt = 0
        }
        tempPacketData.append(pageCnt, length: MemoryLayout<UInt32>.size)
        for i in 0..<count {
            pageId = (UInt32)
            pagesArray[i]
            tempPacketData.append(pageId, length: MemoryLayout<UInt32>.size)
        }
        var tempDataBytes: [UInt8] = UInt8(tempPacketData.bytes)
        for i in 0..<tempPacketData.count {
            let int_data = Int(tempDataBytes[0] & 0xff)
            if (int_data == PACKET_START) || (int_data == PACKET_END) || (int_data == PACKET_DLE) {
                dleData[0] = PACKET_DLE
                filteredPacketData
                UInt8()
                packetData[0] = tempDataBytes[0] ^ 0x20
                filteredPacketData
                UInt8()
            }
            else {
                filteredPacketData
                UInt8()
            }
            tempDataBytes = tempDataBytes + 1
        }
        sof = PACKET_START
        wholePacketData.append(sof, length: MemoryLayout<UInt8>.size)
        wholePacketData.append(filteredPacketData.bytes, length: filteredPacketData.count)
        eof = PACKET_END
        wholePacketData.append(eof, length: MemoryLayout<UInt8>.size)
        let data = Data(data: wholePacketData)
        N.Log("requestOfflineData2WithOwnerId 0x23 data \(data)")
        commManager.writePen2SetData(data)
        return true
    }
    
    func response2AckToOfflineData(withPacketID packetId: UInt16, errCode: UInt8, andTransOption transOption: UInt8) -> Bool {
        var sof: UInt8
        var eof: UInt8
        let dleData = [UInt8](repeating: 0, count: 1)
        let packetData = [UInt8](repeating: 0, count: 1)
        var filteredPacketData = Data()
        var wholePacketData = Data()
        var request: Response2OffLineData
        request.cmd = 0xa4
        request.errorCode = errCode
        request.length = 3
        request.packetId = packetId
        request.transOption = transOption
        var tempPacketData = Data(bytes: request, length: MemoryLayout<request>.size)
        var tempDataBytes: [UInt8] = UInt8(tempPacketData.bytes)
        for i in 0..<tempPacketData.count {
            let int_data = Int(tempDataBytes[0] & 0xff)
            if (int_data == PACKET_START) || (int_data == PACKET_END) || (int_data == PACKET_DLE) {
                dleData[0] = PACKET_DLE
                filteredPacketData
                UInt8()
                packetData[0] = tempDataBytes[0] ^ 0x20
                filteredPacketData
                UInt8()
            }
            else {
                filteredPacketData
                UInt8()
            }
            tempDataBytes = tempDataBytes + 1
        }
        sof = PACKET_START
        wholePacketData.append(sof, length: MemoryLayout<UInt8>.size)
        wholePacketData.append(filteredPacketData.bytes, length: filteredPacketData.count)
        eof = PACKET_END
        wholePacketData.append(eof, length: MemoryLayout<UInt8>.size)
        let data = Data(data: wholePacketData)
        N.Log("response2AckToOfflineDataWithPacketID 0xA4 data \(data)")
        commManager.writePen2SetData(data)
        return true
    }
    
    func requestDelOfflineFile2SectionOwnerId(_ sectionOwnerId: UInt32, andNoteIds noteIdsArray: [Any]) -> Bool {
        let request: SetRequestDelOfflineDataStruct
        var sof: UInt8
        var cmd: UInt8
        var eof: UInt8
        var noteCnt: UInt8
        var length: UInt16
        var sectionOwner_Id: UInt32
        var note_Id: UInt32
        let dleData = [UInt8](repeating: 0, count: 1)
        let packetData = [UInt8](repeating: 0, count: 1)
        noteCnt = (UInt8)
        noteIdsArray.count
        var tempPacketData = Data()
        var filteredPacketData = Data()
        var wholePacketData = Data()
        cmd = 0x25
        tempPacketData.append(cmd, length: MemoryLayout<UInt8>.size)
        length = MemoryLayout<request>.size - MemoryLayout<cmd>.size - MemoryLayout<length>.size + noteCnt * MemoryLayout<UInt32>.size
        tempPacketData.append(length, length: MemoryLayout<UInt16>.size)
        sectionOwner_Id = sectionOwnerId
        tempPacketData.append(sectionOwner_Id, length: MemoryLayout<UInt32>.size)
        tempPacketData.append(noteCnt, length: MemoryLayout<UInt8>.size)
        for i in 0..<noteCnt {
            note_Id = (UInt32)
            noteIdsArray[i]
            tempPacketData.append(note_Id, length: MemoryLayout<UInt32>.size)
        }
        var tempDataBytes: [UInt8] = UInt8(tempPacketData.bytes)
        for i in 0..<tempPacketData.count {
            let int_data = Int(tempDataBytes[0] & 0xff)
            if (int_data == PACKET_START) || (int_data == PACKET_END) || (int_data == PACKET_DLE) {
                dleData[0] = PACKET_DLE
                filteredPacketData
                UInt8()
                packetData[0] = tempDataBytes[0] ^ 0x20
                filteredPacketData
                UInt8()
            }
            else {
                filteredPacketData
                UInt8()
            }
            tempDataBytes = tempDataBytes + 1
        }
        sof = PACKET_START
        wholePacketData.append(sof, length: MemoryLayout<UInt8>.size)
        wholePacketData.append(filteredPacketData.bytes, length: filteredPacketData.count)
        eof = PACKET_END
        wholePacketData.append(eof, length: MemoryLayout<UInt8>.size)
        let data = Data(data: wholePacketData)
        N.Log("requestDelOfflineFile2SectionOwnerId 0x25 data \(data)")
        commManager.writePen2SetData(data)
        return true
    }
    
    func sendUpdateFileInfo2(at fileUrl: URL) -> Bool {
        var request: SetRequestFWUpdateStruct
        var sof: UInt8
        var eof: UInt8
        let dleData = [UInt8](repeating: 0, count: 1)
        let packetData = [UInt8](repeating: 0, count: 1)
        var filteredPacketData = Data()
        var wholePacketData = Data()
        cancelFWUpdate = false
        request.cmd = 0x31
        request.length = MemoryLayout<request>.size - MemoryLayout<request.cmd>.size - MemoryLayout<request.length>.size
        memset(request.deviceName, 0, MemoryLayout<request.deviceName>.size)
        let inputStr: String = commManager.deviceName
        let stringData: Data? = inputStr.data(using: String.Encoding.utf8)
        //or nameStrLen
        memcpy(request.deviceName, stringData?.bytes, MemoryLayout<request.deviceName>.size)
        let nameStrLen: Int = (inputStr.characters.count ?? 0)
        for i in 0..<(16 - nameStrLen) {
            request.deviceName[i + nameStrLen] = UInt8(nil)
        }
        memset(request.fwVer, 0, MemoryLayout<request.fwVer>.size)
        let inputStrVer: String = commManager.fwVerServer
        let stringVerData: Data? = inputStrVer.data(using: String.Encoding.utf8)
        memcpy(request.fwVer, stringVerData?.bytes, MemoryLayout<request.fwVer>.size)
        let verStrLen: Int = (inputStrVer.characters.count ?? 0)
        for i in 0..<(16 - verStrLen) {
            request.fwVer[i + verStrLen] = UInt8(nil)
        }
        readUpdateData(from: fileUrl)
        request.fileSize = (UInt32)
        updateFileData.length
        request.packetSize = UPDATE2_DATA_PACKET_SIZE
        request.dataZipOpt = 1
        request.nCheckSum = checkSum(updateFileData, andLength: request.fileSize())
        var tempPacketData = Data(bytes: request, length: MemoryLayout<request>.size)
        var tempDataBytes: [UInt8] = UInt8(tempPacketData.bytes)
        for i in 0..<tempPacketData.count {
            let int_data = Int(tempDataBytes[0] & 0xff)
            if (int_data == PACKET_START) || (int_data == PACKET_END) || (int_data == PACKET_DLE) {
                dleData[0] = PACKET_DLE
                filteredPacketData
                UInt8()
                packetData[0] = tempDataBytes[0] ^ 0x20
                filteredPacketData
                UInt8()
            }
            else {
                filteredPacketData
                UInt8()
            }
            tempDataBytes = tempDataBytes + 1
        }
        sof = PACKET_START
        wholePacketData.append(sof, length: MemoryLayout<UInt8>.size)
        wholePacketData.append(filteredPacketData.bytes, length: filteredPacketData.count)
        eof = PACKET_END
        wholePacketData.append(eof, length: MemoryLayout<UInt8>.size)
        let data = Data(data: wholePacketData)
        N.Log("sendUpdateFileInfo2AtUrl 0x31 data \(data)")
        commManager.writePen2SetData(data)
        notifyFWUpdate(FW_UPDATE_DATA_RECEIVE_START, percent: 0.0)
        let returnedMTU: Int = commManager.mtu
        if IS_OS_9_OR_LATER {
            fwBtMtu = returnedMTU
        }
        else {
            fwBtMtu = DEFAULT_BT_MTU
        }
        return true
    }
    
    func checkSum(_ fileData: Data, andLength length: UInt) -> UInt8 {
        var pos: UInt = 0
        var Sum: UInt = 0
        var data: UInt8
        let range: NSRange
        range.length = 1
        for pos in 0..<length {
            
            fileData.getBytes(data, range: range)
            Sum = Sum + data
        }
        return (Sum & 0xff)
    }
    
    func sendUpdateFileData2(at fileOffset: UInt32, andStatus status: UInt8) -> Bool {
        var sof: UInt8
        var cmd: UInt8
        var error: UInt8
        var transContinue: UInt8
        var nChecksum: UInt8
        var eof: UInt8
        var length: UInt16
        var sizeBeforeZip: UInt32
        var sizeAfterZip: UInt32
        let dleData = [UInt8](repeating: 0, count: 1)
        let packetData = [UInt8](repeating: 0, count: 1)
        var wholePacketData = Data()
        var hdrPacketData = Data()
        var fwPacketData = Data()
        let range: NSRange
        range.location = fileOffset
        if (range.location + UPDATE2_DATA_PACKET_SIZE) > updateFileData.length {
            range.length = updateFileData.length - range.location
        }
        else {
            range.length = UPDATE2_DATA_PACKET_SIZE
        }
        let dividedData = Data(bytesNoCopy: CChar(updateFileData.bytes) + range.location, length: UPDATE2_DATA_PACKET_SIZE, freeWhenDone: false)
        var zippedData = Data(length: (UPDATE2_DATA_PACKET_SIZE + 512))
        var zippedDataLen: uLongf = zippedData.count
        let result: Int = compress
        OF(((zippedData.mutableBytes as? Bytef), zippedDataLen, (dividedData.bytes as? Bytef), UPDATE2_DATA_PACKET_SIZE))
        N.Log("compress result: \(result)")
        cmd = 0xb2
        hdrPacketData.append(cmd, length: MemoryLayout<UInt8>.size)
        if status == 3 {
            error = 3
            notifyFWUpdate(FW_UPDATE_DATA_RECEIVE_FAIL, percent: 0.0)
        }
        else {
            error = 0
        }
        hdrPacketData.append(error, length: MemoryLayout<UInt8>.size)
        length = zippedDataLen + 14
        hdrPacketData.append(length, length: MemoryLayout<UInt16>.size)
        //0: continue, 1: stop
        if !cancelFWUpdate {
            transContinue = 0
        }
        else {
            transContinue = 1
        }
        hdrPacketData.append(transContinue, length: MemoryLayout<UInt8>.size)
        hdrPacketData.append(fileOffset, length: MemoryLayout<UInt32>.size)
        nChecksum = checkSum(dividedData, andLength: UPDATE2_DATA_PACKET_SIZE)
        hdrPacketData.append(nChecksum, length: MemoryLayout<UInt8>.size)
        sizeBeforeZip = UPDATE2_DATA_PACKET_SIZE
        hdrPacketData.append(sizeBeforeZip, length: MemoryLayout<UInt32>.size)
        sizeAfterZip = (UInt32)
        hdrPacketData.append(sizeAfterZip, length: MemoryLayout<UInt32>.size)
        var hdrDataBytes: [UInt8] = UInt8(hdrPacketData.bytes)
        for i in 0..<hdrPacketData.count {
            let int_data = Int(hdrDataBytes[0] & 0xff)
            if (int_data == PACKET_START) || (int_data == PACKET_END) || (int_data == PACKET_DLE) {
                dleData[0] = PACKET_DLE
                fwPacketData
                UInt8()
                packetData[0] = hdrDataBytes[0] ^ 0x20
                fwPacketData
                UInt8()
            }
            else {
                fwPacketData
                UInt8()
            }
            hdrDataBytes = hdrDataBytes + 1
        }
        var fwDataBytes: [UInt8] = UInt8(zippedData.bytes)
        for i in 0..<zippedDataLen {
            let int_data = Int(fwDataBytes[0] & 0xff)
            if (int_data == PACKET_START) || (int_data == PACKET_END) || (int_data == PACKET_DLE) {
                dleData[0] = PACKET_DLE
                fwPacketData
                UInt8()
                packetData[0] = fwDataBytes[0] ^ 0x20
                fwPacketData
                UInt8()
            }
            else {
                fwPacketData
                UInt8()
            }
            fwDataBytes = fwDataBytes + 1
        }
        sof = PACKET_START
        wholePacketData.append(sof, length: MemoryLayout<UInt8>.size)
        wholePacketData.append(fwPacketData.bytes, length: fwPacketData.count)
        eof = PACKET_END
        wholePacketData.append(eof, length: MemoryLayout<UInt8>.size)
        if (range.length) > 0 && (result == Z_OK) {
            let data = Data(data: wholePacketData)
            //N.Log(@"FW 0xB2 data %@", data);
            N.Log("FW 0xB2 data")
            var dataLocation: Int = 0
            var dataLength: Int = 0
            while dataLocation < data.count {
                if (dataLocation + fwBtMtu) > data.count {
                    dataLength = data.count - dataLocation
                }
                else {
                    dataLength = fwBtMtu
                }
                let splitData = Data(bytesNoCopy: CChar(data.bytes) + dataLocation, length: dataLength, freeWhenDone: false)
                //N.Log(@"FW 0xB2 splitData %@", splitData);
                commManager.writePen2SetData(splitData)
                Thread.sleep(forTimeInterval: 0.02)
                dataLocation += fwBtMtu
            }
        }
        let size = Float(updateFileData.length) / UPDATE2_DATA_PACKET_SIZE
        let packetCount: Float = ceilf(size)
        let index: UInt16 = (fileOffset + UPDATE2_DATA_PACKET_SIZE) / UPDATE2_DATA_PACKET_SIZE
        let progress_percent = (Float(index)) / (Float(packetCount)) * 100.0
        notifyFWUpdate(FW_UPDATE_DATA_RECEIVE_PROGRESSING, percent: progress_percent)
        return true
    }
    */
}
