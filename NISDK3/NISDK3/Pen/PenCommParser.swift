//
//  PenCommParser.swift
//  NISDK3
//
//  Created by Aram Moon on 2017. 6. 7..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation
import CoreBluetooth


enum DOT_STATE : Int {
    case NONE
    case FIRST
    case SECOND
    case THIRD
    case NORMAL
}

enum OFFLINE_DOT_STATE : Int {
    case NONE
    case FIRST
    case SECOND
    case THIRD
    case NORMAL
}

enum PenConnectionStatus : Int {
    case none
    case scanStarted
    case connected
    case disconnected
}
enum OFFLINE_DATA_STATUS : Int {
    case START
    case PROGRESSING
    case END
    case FAIL
}
enum FW_UPDATE_DATA_STATUS : Int {
    case START
    case PROGRESSING
    case END
    case FAIL
}

//13bits:data(4bits year,4bits month, 5bits date, ex:14 08 28)
//3bits: cmd, 1bit:dirty bit
class PenCommParser: NSObject {
    
    let SEAL_SECTION_ID = 4
    weak var penDelegate: PenDelegate?
    weak var commManager : PenController!
    
    var offlineFileList = [AnyHashable: Any]()
    var batteryLevel: UInt8 = 0
    var memoryUsed: UInt8 = 0
    var penThickness: Int = 0
    var fwVersion: String = ""
    
    // Pen data related BTLE characteristics.
    var penCommIdDataReady: Bool = false
    var penCommUpDownDataReady: Bool = false
    var penCommStrokeDataReady: Bool = false
    var penExchangeDataReady: Bool = false
    var penPasswordResponse: Bool = false
    var cancelFWUpdate: Bool = false
    var cancelOfflineSync: Bool = false
    var passwdCounter: Int = 0
    var battMemoryBlock = {((UInt8, UInt8) -> ()).self}
    
    var startX: Float = 0.0
    var startY: Float = 0.0
    var subNameStr: String = ""
    var protocolVerStr: String = ""
    var requestNewPageNotification: Bool = false
    
    let POINT_COUNT_MAX = 1024 * STROKE_NUMBER_MAGNITUDE
    let MAX_NODE_NUMBER = 1024
    
    let PRESSURE_MAX = 255
    let PRESSURE_MAX2 = 1023
    let PRESSURE_MIN = 0
    let PRESSURE_V_MIN: Float = 40
    let IDLE_TIMER_INTERVAL = 5.0
    let IDLE_COUNT = (10.0 / 5.0)
    
    var penDown: Bool = false
    var nodes = [Any]()
    var mDotToScreenScale: Float = 0.0
    var strokeArray = [Any]()
    
    var offlineData: Data?
    var offlinePacketData: Data?
    var offlineDataOffset: Int = 0
    var offlineTotalDataSize: Int = 0
    var offlineTotalDataReceived: Int = 0
    var offlineDataSize: Int = 0
    var offlinePacketCount: Int = 0
    var offlinePacketSize: Int = 0
    var offlinePacketOffset: Int = 0
    var offlineLastPacketIndex: Int = 0
    var offlinePacketIndex: Int = 0
    var offlineSliceCount: Int = 0
    var offlineSliceSize: Int = 0
    var offlineLastSliceSize: Int = 0
    var offlineLastSliceIndex: Int = 0
    var offlineSliceIndex: Int = 0
    var offlineOwnerIdRequested: Int = 0
    var offlineNoteIdRequested: Int = 0
    var offlineFileProcessing: Bool = false
    var offlineLastStrokeStartTime: UInt64 = 0
    var offlineFileParsedList = [AnyHashable: Any]()
    var sealReceived: Bool = false
    var lastSealId: Int = 0
    var lbuffer0: UInt8 = 0
    var lbuffer1: UInt8 = 0
    var packetHdrLen: Int = 0
    var packetLenPos1: Int = 0
    var packetLenPos2: Int = 0
    var packetLenDLENextPos: Int = 0
    private var node_count: Int = 0
    private var node_count_pen: Int = 0
    private var dotCheckState: DOT_STATE = .NONE
    private var offlineDotData0 = OffLineDataDotStruct()
    private var offlineDotData1 = OffLineDataDotStruct()
    private var offlineDotData2 = OffLineDataDotStruct()
    private var offlineDotCheckState: OFFLINE_DOT_STATE = .NONE
    
    
    // FW Update
    var updateFileData: Data?
    var updateFilePosition: Int = 0
    var idleCounter: Int = 0
    var idleTimer: Timer?
    var penStatus: PenStateStruct?
    var penState: PenStateStruct?
    var colorFromPen: UInt32 = 0
    var currentPageInfo: PageInfoType?
    var dataRowArray = [Any]()
    var isSendOneTime: Bool = false
    var isAlarmOneTime: Bool = false
    var penTipColor: UInt32 = 0
    var packetCount: UInt16 = 0
    var isReadyExchangeSent: Bool = false
    var paperInfo: PaperInfo?
    var isStart: Bool = false
    var count: Int = 0
    var packetDataLength: Int = 0
    var prevPacketDataLength: Int = 0
    var packetData: [UInt8] = []
    var isDLEData: Bool = false
    var isNoErrCmd: Bool = false
    var isOneTime: Bool = false
    var activeNotebookId: Int = 0
    var activePaperNum: Int = 0
    var activeOwnerId: Int = 0
    var activeSectionId: Int = 0
    var fwBtMtu: Int = 0
    
    
    private var point_x = [Float](repeating: 0.0, count: 1024 * STROKE_NUMBER_MAGNITUDE)
    private var point_y = [Float](repeating: 0.0, count: 1024 * STROKE_NUMBER_MAGNITUDE)
    private var point_p = [Float](repeating: 0.0, count: 1024 * STROKE_NUMBER_MAGNITUDE)
    private var time_diff = [Int](repeating: 0, count: 1024 * STROKE_NUMBER_MAGNITUDE)
    private var point_count: Int = 0
    private var startTime: UInt64 = 0
    private var pressureMax = 0
    var pressureMax2 = 0
    private var penColor: UInt32 = 0
    private var offlinePenColor: UInt32 = 0
    private var point_index: Int = 0
    
    
    init(penCommController manager: PenController) {
        super.init()
        commManager = manager
        strokeArray = [Any]() /* capacity: 3 */
        point_count = 0
        node_count = 0
        node_count_pen = -1
        idleCounter = 0
        idleTimer = nil
        //        voiceManager = NJVoiceManager.sharedInstance()
        updateFileData = nil
        updateFilePosition = 0
        //        pressureMax = PRESSURE_MAX
        //        offlineFileProcessing = false
        //        shouldSendPageChangeNotification = false
        isReadyExchangeSent = false
        //        penThickness = 960.0
        lastSealId = -1
        //        cancelFWUpdate = false
        passwdCounter = 0
        protocolVerStr = "1"
        subNameStr = ""
        isStart = true
        //commad 1, err 1 len 2
        packetHdrLen = 4
        packetLenPos1 = 2
        packetLenPos2 = 3
        isDLEData = false
        isNoErrCmd = false
        isOneTime = false
        packetDataLength = 0
        point_index = 0
    }
    
    
    func isDataIfReady() -> Bool {
        if penCommIdDataReady && penCommStrokeDataReady && penCommUpDownDataReady && penExchangeDataReady {
            return true
        }else{
            return false
        }
    }
    
    
    //MARK: Send Data to Pen
    func sendPenPasswordReponseData() {
        if isDataIfReady() {
            //            let password: String = Common.sharedInstance.getPassword()
            //            setBTComparePassword(password)
        }
    }
    
    func sendPenPasswordReponseData(withPasswd passwd: String) {
        if isDataIfReady() {
            if commManager.isPenSDK2 {
                //                setComparePasswordSDK2(passwd)
            }
            else {
                setBTComparePassword(passwd)
            }
        }
    }
    
    func reqCancelFWUpdate(_ cancelFWUpdate: Bool) {
        self.cancelFWUpdate = cancelFWUpdate
    }
    
    func reqCancelOfflineSync(_ cancelOfflineSync: Bool) {
        self.cancelOfflineSync = cancelOfflineSync
    }
    
    func processPressure(_ pressure: Float) -> Float {
        var tempPressure: Float = 0
        if pressure < PRESSURE_V_MIN {
            tempPressure = PRESSURE_V_MIN
        }
        if commManager.isPenSDK2 {
            tempPressure = (pressure) / Float(pressureMax2 - PRESSURE_MIN)
        }
        else {
            tempPressure = (pressure) / Float(pressureMax - PRESSURE_MIN)
        }
        return tempPressure
    }
    
    //MARK: - Received Pen data
    func parsePenStrokeData(_ data: [UInt8]) {
        let DotLen: Int = 8
        let packet_count: UInt8 = data[0]
        
        for i in 0..<Int(packet_count) {
            let dotPacket = Array(data[i*DotLen+1..<i*DotLen+9])
            parsePenDot(dotPacket)
        }
    }
    
    func parsePenDot(_ d: [UInt8]) {
        var dot = DotStruct1()
        dot.diff_time = d[0]
        dot.x = toUInt16(d[1], d[2])
        dot.y = toUInt16(d[3], d[4])
        dot.f_x = d[5]
        dot.f_y = d[6]
        dot.force = toUInt16(d[7], 0)
        penDelegate?.penData(.Type1, dot as AnyObject)

        N.Log("data", dot)
    }
    
    func parsePenNewIdData(_ data: [UInt8]) {
        let newIdData = PageNewId.init(data)
        penDelegate?.penData(.PIdChange, newIdData as AnyObject)
    }
    
    func parsePenUpDowneData(_ data: [UInt8]) {
        var updownData = PenUpDown()
        updownData.time = toUInt64(data, at: 0)
        updownData.upDown = UpNDown(rawValue: data[8]) ?? .Up
        updownData.penColor = (toUInt32(data, at: 9) | 0xff000000).toUIColor()
        
        penDelegate?.penData(.UpDown, updownData as AnyObject)
    }
    
    func parsePenStatusData(_ data: [UInt8]) {
        var pen = PenStateStruct()
        pen.version = data[0]
        pen.penStatus = data[1]
        pen.timezoneOffset = toUInt32(data, at: 2)
        pen.timeTick = toUInt64(data, at: 6)
        pen.maxPressure = UInt16(data[14])
        pen.battLevel = data[15]
        pen.memoryUsed = data[16]
        pen.colorState = (toUInt32(data, at: 17) | 0xff000000).toUIColor()
        pen.usePenTipOnOff = OnOff.value(ProtoColV1: data[21])
        pen.useAccelerator = OnOff.value(ProtoColV1: data[22])
        pen.useHover = OnOff.value(ProtoColV1: data[23])
        pen.beepOnOff = OnOff.value(ProtoColV1: data[24])
        pen.autoPwrOffTime = toUInt16(data[25], data[26])
        N.Log("Pen Sensitive", toUInt16(data[27], data[28]))
        pen.reserved = Array(data[29..<40])
        N.Log("Pen Statue Ver1", pen)
        
    }
    
    //MARK: Offline 2AC2
    func parseOfflineFileList(_ data: [UInt8]) {
//        let status: UInt8 = data[0] // 0: NextPacket, 1: End
//        let (section, ownerId) = toSetionOwner(toUInt32(data, at: 1))
//        let noteCount = data[5]
//        var noteArray: [UInt32] = []
//        for i in 0..<Int(noteCount){
//            let noteId = toUInt32(data, at: i*4 + 6)
//            noteArray.append(noteId)
//        }
//        let msg = PenMessage.init(.OFFLINE_DATA_NOTE_LIST, data: (section,ownerId,noteArray) as AnyObject)
//        penDelegate?.deviceMessage(msg)
//        N.Log("parseOfflineFileList Status", status)
        //TODO: status 데이터를 연결해서 받아야 할 지도 모름
    }

    func requestNextOfflineNote() -> Bool {
        //        offlineFileProcessing = true
        //        var needNext: Bool = true
        //        let enumerator: NSEnumerator? = offlineFileList.keyEnumerator()
        //        while needNext {
        //            let ownerId = enumerator?.nextObject()
        //            if ownerId == nil {
        //                offlineFileProcessing = false
        //                N.Log("Offline data : no more file left")
        //                return false
        //            }
        //            let noteList: [Any]? = (offlineFileList[ownerId] as? [Any])
        //            if noteList?.count == 0 {
        //                offlineFileList.removeValueForKey(ownerId)
        //                continue
        //            }
        //            let noteId = (noteList?[0] as? NSNumber)
        //            offlineOwnerIdRequested = (UInt32)
        //            CUnsignedInt(ownerId)
        //            offlineNoteIdRequested = (UInt32)
        //            CUnsignedInt(noteId)
        //            requestOfflineData(withOwnerId: offlineOwnerIdRequested, noteId: offlineNoteIdRequested)
        //            needNext = false
        //        }
        return true
    }
    
    func parseOfflineFileListInfo(_ data: [UInt8]) {
        var fileInfo = OfflineFileListInfoStruct()
        fileInfo.fileCount = toUInt32(data, at: 0)
        fileInfo.fileSize = toUInt32(data, at: 4)
        offlineTotalDataSize = Int(fileInfo.fileSize)
        offlineTotalDataReceived = 0
        let msg = PenMessage.init(.OFFLINE_DATA_SEND_START, data: nil)
        penDelegate?.penMessage(msg)
    }
    func parseOfflineFileInfoData(_ d: [UInt8]) {
        if d.count != 13{
            N.Log("Error")
            return
        }
        var fileInfo = OFFLINE_FILE_INFO_DATA()
        fileInfo.type = d[0]
        fileInfo.file_size = toUInt32(d, at: 1)
        fileInfo.packet_count = toUInt16(d[5], d[6])
        fileInfo.packet_size = toUInt16(d[7], d[8])
        fileInfo.slice_count = toUInt16(d[9], d[10])
        fileInfo.slice_size  = toUInt16(d[11], d[12])
        if fileInfo.type == 1 {
            N.Log("Offline File Info : Zip file")
        }
        else {
            N.Log("Offline File Info : Normal file")
        }
        let fileSize: UInt32 = fileInfo.file_size
        offlinePacketCount = Int(fileInfo.packet_count)
        offlinePacketSize = Int(fileInfo.packet_size)
        offlineSliceCount = Int(fileInfo.slice_count)
        offlineSliceSize = Int(fileInfo.slice_size)
        offlineSliceIndex = 0
        N.Log("parseOfflineFileInfoData :", fileInfo)
        offlineLastPacketIndex = Int(fileSize) / offlinePacketSize
        let lastPacketSize: Int = Int(fileSize) % offlinePacketSize
        if lastPacketSize == 0 {
            offlineLastPacketIndex -= 1
            offlineLastSliceIndex = offlineSliceCount - 1
            offlineLastSliceSize = offlineSliceSize
        }
        else {
            offlineLastSliceIndex = lastPacketSize / offlineSliceSize
            offlineLastSliceSize = lastPacketSize % offlineSliceSize
            if offlineLastSliceSize == 0 {
                offlineLastSliceIndex -= 1
                offlineLastSliceSize = offlineSliceSize
            }
        }
        offlineData?.removeAll()
        offlinePacketData = nil
        offlineDataOffset = 0
        offlineDataSize = Int(fileSize)
        offlineFileAck(forType: 1, index: 0)
        // 1 : header, index 0
    }
    func parseOfflineFileStatus(_ d: [UInt8]) {
        var fileStatus = OfflineFileStatusStruct()
        fileStatus.status = d[0]
        if fileStatus.status == 1 {
            N.Log("OfflineFileStatus success")
            let msg = PenMessage.init(.OFFLINE_DATA_SEND_SUCCESS, data: nil)
            penDelegate?.penMessage(msg)
        }
        else {
            N.Log("OfflineFileStatus fail")
            let msg = PenMessage.init(.OFFLINE_DATA_SEND_FAILURE, data: nil)
            penDelegate?.penMessage(msg)
        }
    }
    
    //MARK: Pen Data Passer
    func parseRequestUpdateFile(_ d: [UInt8]) {
        var request = RequestUpdateFileStruct()
        request.index = toUInt16(d[0], d[1])
        if !cancelFWUpdate {
            sendUpdateFileData(at: request.index)
        }
    }
    func parseUpdateFileStatus(_ d: [UInt8]) {
        var status = UpdateFileStatusStruct()
        status.status = toUInt16(d[0], d[1])
        if status.status == 1 {
            let msg = PenMessage.init(.PEN_FW_UPGRADE_SUCCESS, data: nil)
            penDelegate?.penMessage(msg)
        }
        else if status.status == 0 {
            let msg = PenMessage.init(.PEN_FW_UPGRADE_FAILURE, data: nil)
            penDelegate?.penMessage(msg)        }
        else if status.status == 3 {
            N.Log("out of pen memory space")
        }
        N.Log("parseUpdateFileStatus status \(status)")
    }

    func parseReadyExchangeDataRequest(_ d: [UInt8]) {
        var request = ReadyExchangeDataRequestStruct()
        request.ready = d[0]
        if request.ready == 0 {
            isReadyExchangeSent = false
            N.Log("2AB5 was sent to App because a pen was turned off by itself.")
        }else{
            
        }
        if isReadyExchangeSent {
            N.Log("2AB4 was already sent to Pen. So, 2AB5 request is not proceeded again")
            return
        }
    }
    
    func parseFWVersion(_ data: [UInt8]) {
        fwVersion = String(data: Data(data), encoding: .utf8) ?? fwVersion
        N.Log("parseFWVersion", fwVersion)
        //TODO: Password Default
        setPenState()
    }
    
    
    //MARK: - Send data
    func setPenState() {
        let setPenStateData = SetPenStateStruct()
        let data = Data(setPenStateData.toUInt8Array())
        commManager.writeSetPenState(data)
    }
    func setPenStateWithTimeTick() {
        let setPenStateData = SetPenStateStruct()
        let data = Data(setPenStateData.toUInt8Array())
        commManager.writeSetPenState(data)
    }
    func setPenStateWithPenPressure(_ penPressure: UInt16) {
        var setPenStateData = SetPenStateStruct()
        setPenStateData.penPressure = penPressure
        let data = Data(setPenStateData.toUInt8Array())
        commManager.writeSetPenState(data)
    }
    func setPenStateWithAutoPwrOffTime(_ autoPwrOff: UInt16) {
        var setPenStateData = SetPenStateStruct()
        setPenStateData.autoPwrOnTime = autoPwrOff
        let data = Data(setPenStateData.toUInt8Array())
        commManager.writeSetPenState(data)
    }
    func setPenStateAutoPower(_ autoPower: OnOff) {
        var setPenStateData = SetPenStateStruct()
        setPenStateData.usePenTipOnOff = autoPower.rawValueV1()
        let data = Data(setPenStateData.toUInt8Array())
        commManager.writeSetPenState(data)
    }
    
    func requestSetPenAutoPowerSound(_ sound: OnOff){
        var setPenStateData = SetPenStateStruct()
        setPenStateData.beepOnOff = sound.rawValueV1()
        let data = Data(setPenStateData.toUInt8Array())
        commManager.writeSetPenState(data)
    }
    func setPenStateWithRGB(_ color: UIColor) {
        var setPenStateData = SetPenStateStruct()
        let colorState: UInt32 = (color.toUInt32() & 0x00ffffff) & 0x01000000
        setPenStateData.colorState = colorState
        let data = Data(setPenStateData.toUInt8Array())
        commManager.writeSetPenState(data)
    }
    func setPenStateWithHover(_ useHover: OnOff) {
        var setPenStateData = SetPenStateStruct()
        setPenStateData.useHover = useHover.rawValueV1()
        let data = Data(setPenStateData.toUInt8Array())
        commManager.writeSetPenState(data)
    }
    
    
    func setNoteIdList() {
        //        if canvasStartDelegate {
        //            DispatchQueue.main.async(execute: {() -> Void in
        //                canvasStartDelegate.setPenCommNoteIdList()
        //            })
        //        }
    }
    
    func setAllNoteIdList() {
        let type: UInt8 = 0x03 // 1: note id 2: seciton and owner, 3: all
        var d: [UInt8] = []
        d.append(type)
        let data = Data(d)
        commManager.writeNoteIdList(data)
    }
    
    func setUsingNotes(_ noteList: [UInt32]) {
        let type: UInt8 = 0x01 // 1: note id 2: seciton and owner, 3: all
        var d: [UInt8] = []
        d.append(type)
        d.append(UInt8(noteList.count))
        for note in noteList{
            d.append(contentsOf: note.toUInt8Array())
        }
        let data = Data(d)
        commManager.writeNoteIdList(data)

    }
    
    func setUsingSectionOwner(_ sectionOwnerList: [UInt32]) {
        let type: UInt8 = 0x02 // 1: note id 2: seciton and owner, 3: all
        var d: [UInt8] = []
        d.append(type)
        d.append(UInt8(sectionOwnerList.count))
        for sectionOwner in sectionOwnerList{
            d.append(contentsOf: sectionOwner.toUInt8Array())
        }
        let data = Data(d)
        commManager.writeNoteIdList(data)
    }
    func setPassword(_ pinNumber: String) {
        var request = PenPasswordChangeRequestStruct()
        //NSString *currentPassword = [MyFunctions loadPasswd];
        request.prevPassword = "0000".toUInt8Array()
        request.newPassword = pinNumber.toUInt8Array()
        var d: [UInt8] = []
        d.append(contentsOf: request.prevPassword)
        d.append(contentsOf: request.newPassword)
        let data = Data(d)
        commManager.writeSetPasswordData(data)
    }
    func changePassword(from curNumber: String, to pinNumber: String) {
        var request = PenPasswordChangeRequestStruct()
        //NSString *currentPassword = [MyFunctions loadPasswd];
        request.prevPassword = curNumber.toUInt8Array()
        request.newPassword = pinNumber.toUInt8Array()
        var d: [UInt8] = []
        d.append(contentsOf: request.prevPassword)
        d.append(contentsOf: request.newPassword)
        let data = Data(d)
        commManager.writeSetPasswordData(data)
    }
    
    func setBTComparePassword(_ pinNumber: String) {
        let data = Data(pinNumber.toUInt8Array())
        commManager.writePenPasswordResponseData(data)
    }
    
    func writeReadyExchangeData(_ ready: Bool) {
        var request = ReadyExchangeDataStruct()
        request.ready = ready ? 1 : 0
        let data = Data([request.ready])
        commManager.writeReadyExchangeData(data)
        if ready == true {
            //flag should be YES when 2AB4 (response App ready)
            isReadyExchangeSent = true
            N.Log("isReadyExchangeSent set into YES because it is sent to Pen")
        }
        else if ready == false {
            resetDataReady()
            N.Log("isReadyExchangeSent set into NO because of disconnected signal")
        }
    }
    
    func resetDataReady() {
        //reset isReadyExchangeSent flag when disconnected
        isReadyExchangeSent = false
        penExchangeDataReady = false
        penCommUpDownDataReady = false
        penCommIdDataReady = false
        penCommStrokeDataReady = false
        N.Log("resetDataReady is performed because of disconnected signal")
    }
    
    func requestOfflineFileList() -> Bool {
        if offlineFileProcessing {
            return false
        }
        var request = RequestOfflineFileListStruct()
        request.status = 0x00
        let data = Data([request.status])
        commManager.writeRequestOfflineFileList(data)
        return true
    }
    
    
    func requestDelOfflineFile(_ sectionOwnerId: UInt32) {
        let data = Data(sectionOwnerId.toUInt8Array())
        commManager.writeRequestDelOfflineFile(data)
    }
    
    func requestOfflineData(SectionOwner: UInt32,_ noteList: [UInt32]) {
        var d: [UInt8] = []
        d.append(contentsOf: SectionOwner.toUInt8Array())
        d.append(UInt8(noteList.count))
        for note in noteList{
            d.append(contentsOf: note.toUInt8Array())
        }
        let data = Data(d)
        commManager.writeRequestOfflineFile(data)
    }
    
    func offlineFileAck(forType type: UInt8, index: UInt8) {
        let data = Data([type,index])
        commManager.writeOfflineFileAck(data)
    }
    
    
    //MARK: Firmware update
    func sendUpdateFileInfo(at fileUrl: URL) {
        var d: [UInt8] = []
        readUpdateData(from: fileUrl)
        var fileName = Array("\\Update.zip".utf8)
        let adcount = 52 - fileName.count
        let dummy: [UInt8] = [UInt8](repeating: 0, count: adcount)
        fileName.append(contentsOf: dummy)
        var fileSize: UInt16 = 0
//        guard fileSize = updateFileData?.count else{
//            return
//        }

        let FWpacketCount: UInt16 = 0
        let FWPacketSize: UInt16 = 0
        d.append(contentsOf: fileName)
        d.append(contentsOf: fileSize.toUInt8Array())
        d.append(contentsOf: FWpacketCount.toUInt8Array())
        d.append(contentsOf: FWPacketSize.toUInt8Array())

        let data = Data(d)
        commManager.writeUpdateFileInfo(data)
    }
    func sendUpdateFileData(at index: UInt16) {
//        N.Log("sendUpdateFileDataAt \(index)")
//        var updateData: UpdateFileDataStruct
//        updateData.index = index
//        let range: NSRange
//        range.location = index * UPDATE_DATA_PACKET_SIZE
//        if (range.location + UPDATE_DATA_PACKET_SIZE) > updateFileData.length {
//            range.length = updateFileData.length - range.location
//        }
//        else {
//            range.length = UPDATE_DATA_PACKET_SIZE
//        }
//        if range.length > 0 {
//            updateFileData.getBytes(updateData.fileData, range: range)
//            let data = Data(bytes: updateData, length: (MemoryLayout<updateData.index>.size + range.length))
//            commManager.writeUpdateFileData(data)
//        }
//        let progress_percent = (Float(index)) / (Float(packetCount)) * 100.0
//        notifyFWUpdate(FW_UPDATE_DATA_RECEIVE_PROGRESSING, percent: progress_percent)
    }
    func readUpdateData(from fileUrl: URL) {
        do{
            updateFileData = try Data(contentsOf: fileUrl)
            updateFilePosition = 0
        }catch{
            
        }
    }
    func sendUpdateFileInfoAtUrl(toPen fileUrl: URL) {
        cancelFWUpdate = false
        readUpdateData(from: fileUrl)
        var fileInfo = UpdateFileInfoStruct()
        //char *fileName = "\\Update.zip";
//        let fileNameString: String = "\\\(fileUrl.path.lastPathComponent)"
//        let fileName = fileNameString.utf8
//        memset(fileInfo.filePath, 0, MemoryLayout<fileInfo.filePath>.size)
//        memcpy(fileInfo.filePath, fileName, strlen(fileName))
//        fileInfo.fileSize = (UInt32)
//        updateFileData.length
//        let size = Float(fileInfo.fileSize()) / UPDATE_DATA_PACKET_SIZE
//        fileInfo.packetCount = ceilf(size)
//        fileInfo.packetSize = UPDATE_DATA_PACKET_SIZE
//        packetCount = fileInfo.packetCount
//        let data = Data(bytes: fileInfo, length: MemoryLayout<fileInfo>.size)
//        commManager.writeUpdateFileInfo(data)
//        notifyFWUpdate(FW_UPDATE_DATA_RECEIVE_START, percent: 0.0)
    }
    
    //////////////////////////////////////////////////////////////////
    //
    //
    //             Pen Password
    //
    //////////////////////////////////////////////////////////////////
    func parsePenPasswordRequest(_ data: [UInt8]) {
        var request = PenPasswordRequestStruct()
        request.retryCount = data[0]
        request.resetCount = data[1]
        let msg = PenMessage.init(.PASSWORD_REQUEST, data: request as AnyObject)
        penDelegate?.penMessage(msg)
        N.Log("Password",request)
        if request.resetCount == 0 {
            setBTComparePassword("0000")
        }
    }
    func parsePenPasswordChangeResponse(_ data: [UInt8]) {
        let res = data[0]
        if res == 0x00 {
            N.Log("password change success")
            let msg = PenMessage.init(.PASSWORD_SETUP_SUCCESS, data: nil)
            penDelegate?.penMessage(msg)
        }
        else if res == 0x01 {
            N.Log("password change fail")
            let msg = PenMessage.init(.PASSWORD_SETUP_FAILURE, data: nil)
            penDelegate?.penMessage(msg)
        }else if res == 0x02{
            N.Log("password change fail format error")
            let msg = PenMessage.init(.PASSWORD_SETUP_FAILURE, data: nil)
            penDelegate?.penMessage(msg)
        }

    }
    
}
