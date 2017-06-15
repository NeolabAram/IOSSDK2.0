//
//  PenCommParser.swift
//  NISDK3
//
//  Created by Aram Moon on 2017. 6. 7..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation
import CoreBluetooth



//struct DotDataStruct{
//    var x: Float = 0
//    var y: Float = 0
//    var pressure: Float = 0
//    var diff_time: UInt8 = 0
//}



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
    weak var penDelegate: DeviceDelegate?
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
    var activePageDocument: PageDocument?
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
    private var offline2DotData0 = OffLineData2DotStruct()
    private var offline2DotData1 = OffLineData2DotStruct()
    private var offline2DotData2 = OffLineData2DotStruct()
    private var offlineDotCheckState: OFFLINE_DOT_STATE = .NONE
    
    
    // FW Update
    var updateFileData: Data?
    var updateFilePosition: Int = 0
    var idleCounter: Int = 0
    var idleTimer: Timer?
    var penStatus: PenStateStruct?
    var penState: PenStateStruct?
    var penStatus2: PenState2Struct?
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
    
    /*
    func isDataIfReady() -> Bool {
        if penCommIdDataReady && penCommStrokeDataReady && penCommUpDownDataReady && penExchangeDataReady {
            return true
        }else{
            return false
        }
    }
    
    func sendPenPasswordReponseData() {
        if isDataIfReady() {
            let password: String = Common.sharedInstance.getPassword()
            //            setBTComparePassword(password)
        }
    }
    
    func sendPenPasswordReponseData(withPasswd passwd: String) {
        if isDataIfReady() {
            if commManager.isPenSDK2 {
                //                setComparePasswordSDK2(passwd)
            }
            else {
                //                setBTComparePassword(passwd)
            }
        }
    }
    
    func reqPenDown(_ penDown: Bool) {
        if point_count > 0 {
            // both penDown YES and NO
            //            if strokeHandler {
            //                penColor = strokeHandler.setPenColor()
            //            }
            nodes = []
            point_count = 0
        }
        if penDown == true {
            N.Log("penDown YES")
            // Just ignore timestamp from Pen. We use Audio timestamp from iPhone.
            /* ken 2015.04.19*/
            let timeInMiliseconds: UInt64 = (UInt64)(Date().timeIntervalSince1970 * 1000)
            N.Log("Stroke start time \(timeInMiliseconds)")
            startTime = timeInMiliseconds
            dotCheckState = .FIRST
        }
        else {
            N.Log("penDown NO")
            dotCheckState = .NONE
            isSendOneTime = true
        }
        self.penDown = penDown
    }
    
    func reqCancelFWUpdate(_ cancelFWUpdate: Bool) {
        self.cancelFWUpdate = cancelFWUpdate
    }
    
    func reqCancelOfflineSync(_ cancelOfflineSync: Bool) {
        self.cancelOfflineSync = cancelOfflineSync
    }
    
    //MARK: - Received data
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
    
    /*
    func parsePenStrokeData(_ data: [UInt8], withLength length: Int) {
        let STROKE_PACKET_LEN: Int = 8
        if penDown == false || sealReceived == true {
            return
        }
        let packet_count: UInt8 = data[0]
        let strokeDataLength: Int = length - 1
        // data += 1
        // 06-Oct-2014 by namSsan
        // checkXcoord X,Y only called once for middle point of the stroke
        //int mid = (pa)
        var shouldCheck: Bool = false
        let mid: Int = Int(packet_count) / 2
        for i in 0..<Int(packet_count) {
            if (STROKE_PACKET_LEN * (i + 1)) > strokeDataLength {
                break
            }
            shouldCheck = false
            if i == mid {
                shouldCheck = true
            }
            parsePenStrokeData(data, withLength: STROKE_PACKET_LEN)
            //self.data = data + STROKE_PACKET_LEN
        }
    }
    */
    
    /*
    func parsePenStrokePacket(_ data: [UInt8], withLength length: Int) {
        //set for NISDK
        if commManager.isPenSDK2 {
            var strokeData: COMM2_WRITE_DATA?
            Data(data).withUnsafeBytes({ (bytes: UnsafePointer<COMM2_WRITE_DATA>) -> () in
                strokeData = UnsafePointer<COMM2_WRITE_DATA>(bytes).pointee
            })
            let int_x = Float((strokeData?.x)!)
            let int_y = Float((strokeData?.y)!)
            let float_x = Float((strokeData?.f_x)!) * 0.01
            let float_y = Float((strokeData?.f_y)!) * 0.01
            let aDot: DotDataStruct = DotDataStruct(x: int_x + float_x - startX, y: int_y + float_y - startY, pressure: Float((strokeData?.force)!), diff_time: (strokeData?.diff_time)!)
            N.Log("Raw X \(int_x + float_x), Y \(int_y + float_y), P \(aDot.pressure)")

        }
        else {
            
            var strokeData: COMM_WRITE_DATA?
            Data(data).withUnsafeBytes({ (bytes: UnsafePointer<COMM_WRITE_DATA>) -> () in
                strokeData = UnsafePointer<COMM_WRITE_DATA>(bytes).pointee
            })
            let int_x = Float((strokeData?.x)!)
            let int_y = Float((strokeData?.y)!)
            let float_x = Float((strokeData?.f_x)!) * 0.01
            let float_y = Float((strokeData?.f_y)!) * 0.01
            let aDot: DotDataStruct = DotDataStruct(x: int_x + float_x - startX, y: int_y + float_y - startY, pressure: Float((strokeData?.force)!), diff_time: (strokeData?.diff_time)!)
            N.Log("Raw X \(int_x + float_x), Y \(int_y + float_y), P \(aDot.pressure)")
        }
    }
     */
    let DAILY_PLAN_START_PAGE_606 = 62
    let DAILY_PLAN_END_PAGE_606 = 826
    let DAILY_PLAN_START_PAGE_608 = 42
    let DAILY_PLAN_END_PAGE_608 = 424
    
    
    func parsePenUpDowneData(_ data: [UInt8], withLength length: Int) {
        // see the setter for _penDown. It is doing something important.
        var updownData: COMM_PENUP_DATA?
        Data(data).withUnsafeBytes({ (bytes: UnsafePointer<COMM_PENUP_DATA>) -> () in
            updownData = UnsafePointer<COMM_PENUP_DATA>(bytes).pointee
        })
        if updownData?.upDown == 0 {
            penDown = true
            node_count_pen = -1
            node_count = 0
            let color: UInt32? = updownData?.penColor
            if (color! & 0xff000000) == 0x01000000 && (color! & 0x00ffffff) != 0x00ffffff && (color! & 0x00ffffff) != 0x00000000 {
                penColor = color! | 0xff000000
                // set Alpha to 255
            }
            N.Log("Pen color 0x\(UInt(penColor))")
        }
        else {
            penDown = false
        }
        let time: UInt64? = updownData?.time
        let timeNumber = Int(time!)
        let color = Int(penColor)
        let status: String = (penDown) ? "down" : "up"
        let stroke: [AnyHashable: Any] = [
            "type" : "updown",
            "time" : timeNumber,
            "status" : status,
            "color" : color
        ]
    }
    
    func parsePenNewIdData(_ data: [UInt8], withLength length: Int) {
        var newIdData: COMM_CHANGEDID2_DATA?
        Data(data).withUnsafeBytes({ (bytes: UnsafePointer<COMM_CHANGEDID2_DATA>) -> () in
            newIdData = UnsafePointer<COMM_CHANGEDID2_DATA>(bytes).pointee
        })
        let section: UInt8? = UInt8((newIdData?.owner_id)! >> 24) & 0xff
        let owner: UInt? = (newIdData?.owner_id)! & 0x00ffffff
        let noteId: UInt32? = newIdData?.note_id
        let pageNumber: UInt32? = newIdData?.page_id
        N.Log("newIdData: \(String(describing: newIdData))")
        // Handle seal if section is 4.
        if Int(section!) == SEAL_SECTION_ID {
            // Note ID is delivered as owner ID.
            sealReceived = true
            //To ignore stroke.
            return
        }
        sealReceived = false
        if !requestNewPageNotification && (activeNotebookId == Int(noteId)) && (activePaperNum == pageNumber) && (activeOwnerId == owner) && (activeSectionId == section) {
            return
        }
        requestNewPageNotification = false
        activeNotebookId = noteId
        activePaperNum = pageNumber
        activeOwnerId = owner
        activeSectionId = section
        N.Log("New Id Data noteId \(UInt(noteId)), pageNumber \(UInt(pageNumber))")
        paperInfo = NJNotebookPaperInfo.sharedInstance().getNotePaperInfo(forNotebook: Int(noteId), pageNum: Int(pageNumber), section: Int(section), owner: Int(owner))
        startX = paperInfo.startX
        startY = paperInfo.startY
        if canvasStartDelegate {
            DispatchQueue.main.async(execute: {() -> Void in
                canvasStartDelegate.activeNoteId(forFirstStroke: Int(noteId), pageNum: Int(pageNumber), sectionId: Int(section), ownderId: Int(owner))
            })
        }
        DispatchQueue.main.async(execute: {() -> Void in
            if strokeHandler != nil {
                strokeHandler.notifyPageChanging()
                strokeHandler.activeNoteId(Int(noteId), pageNum: Int(pageNumber), sectionId: Int(section), ownderId: Int(owner))
            }
            NotificationCenter.default.post(name: NJPenCommParserPageChangedNotification, object: nil, userInfo: nil)
        })
    }
    
    func parsePenStatusData(_ data: [UInt8], withLength length: Int) {
        Data(data).withUnsafeBytes { (bytes: UnsafePointer<PenStateStruct>) -> () in
            penStatus = UnsafePointer<PenStateStruct>(bytes).pointee
        }
        
        N.Log("Penstate: \(penStatus)")
        
        //SDK2.0 later
        if !commManager.isPenSDK2 {
            pressureMax = Int(penStatus!.pressureMax)
        }
        //SDK2.0
        if commManager.isPenSDK2 {
            if penStatus2?.offlineOnOff == 0 {
                let pOfflineOnOff: UInt8 = 1
                setPenState2(PENSTATETYPE_OFFLINESAVE, andValue: pOfflineOnOff)
            }
        }
        DispatchQueue.main.async(execute: {() -> Void in
            penStatusDelegate.penStatusData(penStatus)
        })

    }
    
    
    func parseOfflineFileList(_ data: [UInt8], withLength length: Int) {
        let fileList: OfflineFileListStruct? = (data as? OfflineFileListStruct)
        let noteCount: Int? = min(fileList?.noteCount, 10)
        let section: UInt8? = (fileList?.sectionOwnerId >> 24) & 0xff
        let ownerId: UInt32? = fileList?.sectionOwnerId & 0x00ffffff
        let notebookInfo = NJNotebookPaperInfo.sharedInstance()
        //exclude owner 28
        let sectionOwnerStr = String(format: "%05tu_%05tu", Int(section), Int(ownerId))
        if notebookInfo.hasInfo(forSectionId: Int(section), ownerId: Int(ownerId)) {
            DispatchQueue.main.async(execute: {() -> Void in
                if !isEmpty(offlineDataDelegate) && offlineDataDelegate.responds(to: Selector("offlineDataDidReceiveNoteListCount:ForSectionOwnerId:")) {
                    offlineDataDelegate.offlineDataDidReceiveNoteListCount(noteCount, forSectionOwnerId: fileList?.sectionOwnerId)
                }
            })
        }
        #if FW_UPDATE_TEST
            do {
                let paths: [Any] = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                let documentDirectory: String = paths[0]
                let updateFilePath: String = URL(fileURLWithPath: documentDirectory).appendingPathComponent("Update.zip").absoluteString
                let url = URL(fileURLWithPath: updateFilePath)
                sendUpdateFileInfo(at: url)
            }
        #endif
        if noteCount == 0 {
            return
        }
        //exclude owner 28
        if notebookInfo.hasInfo(forSectionId: Int(section), ownerId: Int(ownerId)) {
            if section == SEAL_SECTION_ID {
                //Just ignore for offline data
                requestDelOfflineFile(fileList?.sectionOwnerId)
            }
            else {
                let sectionOwnerId = Int(fileList?.sectionOwnerId)
                var noteArray: [Any]? = (offlineFileList[sectionOwnerId] as? [Any])
                if noteArray == nil {
                    noteArray = [Any]() /* capacity: noteCount */
                    offlineFileList[sectionOwnerId] = noteArray
                }
                N.Log("OfflineFileList owner : \(sectionOwnerId)")
                for i in 0..<noteCount {
                    let noteId = Int(fileList?.noteId[i])
                    N.Log("OfflineFileList note : \(noteId)")
                    noteArray?.append(noteId)
                }
            }
        }
        if fileList?.status == 0 {
            N.Log("More offline File List remained")
        }
        else {
            if offlineFileList.keys.count > 0 {
                N.Log("Getting offline File List finished")
                DispatchQueue.main.async(execute: {() -> Void in
                    if !isEmpty(offlineDataDelegate) && offlineDataDelegate.responds(to: #selector(self.offlineDataDidReceiveNoteList)) {
                        offlineDataDelegate.offlineDataDidReceiveNote(offlineFileList)
                    }
                })
            }
        }
    }
    
    func requestNextOfflineNote() -> Bool {
        offlineFileProcessing = true
        var needNext: Bool = true
        let enumerator: NSEnumerator? = offlineFileList.keyEnumerator()
        while needNext {
            let ownerId = enumerator?.nextObject()
            if ownerId == nil {
                offlineFileProcessing = false
                N.Log("Offline data : no more file left")
                return false
            }
            let noteList: [Any]? = (offlineFileList[ownerId] as? [Any])
            if noteList?.count == 0 {
                offlineFileList.removeValueForKey(ownerId)
                continue
            }
            let noteId = (noteList?[0] as? NSNumber)
            offlineOwnerIdRequested = (UInt32)
            CUnsignedInt(ownerId)
            offlineNoteIdRequested = (UInt32)
            CUnsignedInt(noteId)
            requestOfflineData(withOwnerId: offlineOwnerIdRequested, noteId: offlineNoteIdRequested)
            needNext = false
        }
        return true
    }
    
    func didReceiveOfflineFile(forOwnerId ownerId: UInt32, noteId: UInt32) {
        let ownerNumber = Int(offlineOwnerIdRequested)
        let noteNumber = Int(offlineNoteIdRequested)
        var noteList: [Any]? = (offlineFileList[ownerNumber] as? [Any])
        if noteList == nil {
            return
        }
        let index: Int = (noteList? as NSArray).index(of: noteNumber)
        if index == NSNotFound {
            return
        }
        noteList?.remove(at: index)
    }
    
     //MARK: - Notification
    func notifyOfflineDataStatus(_ status: OFFLINE_DATA_STATUS, percent: Float) {
        DispatchQueue.main.async(execute: {() -> Void in
            switch status{
            case .offline_DATA_RECEIVE_START:
                let msg = PenMessage.init(PenMessageType.OFFLINE_DATA_SEND_START, data: nil)
                self.penDelegate?.onReceiveMessage(msg)
            case .offline_DATA_RECEIVE_PROGRESSING:
                let msg = PenMessage.init(PenMessageType.OFFLINE_DATA_SEND_STATUS, data: percent as AnyObject)
                self.penDelegate?.onReceiveMessage(msg)
            case .offline_DATA_RECEIVE_END:
                let msg = PenMessage.init(PenMessageType.OFFLINE_DATA_SEND_SUCCESS, data: nil)
                self.penDelegate?.onReceiveMessage(msg)
            case .offline_DATA_RECEIVE_FAIL:
                let msg = PenMessage.init(PenMessageType.OFFLINE_DATA_SEND_FAILURE, data: nil)
                self.penDelegate?.onReceiveMessage(msg)
            }
        })
    }
    func notifyOfflineDataFileListDidReceive() {
        DispatchQueue.main.async(execute: {() -> Void in
            let msg = PenMessage.init(PenMessageType.OFFLINE_DATA_NOTE_LIST, data: self.offlineFileList as AnyObject)
            self.penDelegate?.onReceiveMessage(msg)
        })
    }
    func parseRequestUpdateFile(_ data: [UInt8], withLength length: Int) {
        let request: RequestUpdateFileStruct? = (data as? RequestUpdateFileStruct)
        if !cancelFWUpdate {
            sendUpdateFileData(at: request?.index)
        }
    }
    func parseUpdateFileStatus(_ data: [UInt8], withLength length: Int) {
        let status: UpdateFileStatusStruct? = (data as? UpdateFileStatusStruct)
        if status?.status == 1 {
            notifyFWUpdateStatus(FW_UPDATE_DATA_RECEIVE_END, percent: 100)
        }
        else if status?.status == 0 {
            notifyFWUpdateStatus(FW_UPDATE_DATA_RECEIVE_FAIL, percent: 0.0)
        }
        else if status?.status == 3 {
            N.Log("out of pen memory space")
        }
        N.Log("parseUpdateFileStatus status \(status?.status)")
    }
    func notifyFWUpdate(_ status: FW_UPDATE_DATA_STATUS, percent: Float) {
        DispatchQueue.main.async(execute: {() -> Void in
            fwUpdateDelegate.fwUpdateDataReceive(status, percent: percent)
        })
    }
    func parseReadyExchangeDataRequest(_ data: [UInt8], withLength length: Int) {
        let request: ReadyExchangeDataRequestStruct? = (data as? ReadyExchangeDataRequestStruct)
        if request?.ready == 0 {
            isReadyExchangeSent = false
            N.Log("2AB5 was sent to App because a pen was turned off by itself.")
        }
        if isReadyExchangeSent {
            N.Log("2AB4 was already sent to Pen. So, 2AB5 request is not proceeded again")
            return
        }
        if !commManager.isPenSDK2 {
            penExchangeDataReady = (request?.ready == 1)
        }
    }
    */
    func parseFWVersion(_ data: [UInt8], withLength length: Int) {
        fwVersion = String(data: Data(data), encoding: .utf8)!  //String(bytes: data, length: length, encoding: String.Encoding.utf8)
        print("parseFWVersion", fwVersion)
    }
    
    /*
    //MARK: - Send data
    func setPenState() {
        let timeInMiliseconds: TimeInterval = Date().timeIntervalSince1970 * 1000
        let localTimeZone = NSTimeZone.local()
        let millisecondsFromGMT: Int = 1000 * localTimeZone.secondsFromGMT + localTimeZone.daylightSavingTimeOffset * 1000
        var setPenStateData: SetPenStateStruct
        setPenStateData.timeTick = (UInt64)
        setPenStateData.timezoneOffset = (int32_t)
        N.Log("set timezoneOffset \(setPenStateData.timezoneOffset), timeTick \(setPenStateData.timeTick)")
        if penStatus {
            let color: UInt32 = penStatus.colorState
            setPenStateData.colorState = (color & 0x00ffffff) | (0x01000000)
            setPenStateData.usePenTipOnOff = penStatus.usePenTipOnOff
            setPenStateData.useAccelerator = penStatus.useAccelerator
            setPenStateData.useHover = 2
            setPenStateData.beepOnOff = penStatus.beepOnOff
            setPenStateData.autoPwrOnTime = penStatus.autoPwrOffTime
            setPenStateData.penPressure = penStatus.penPressure
        }
        else {
            let color: UIColor? = nil
            if color != nil {
                var r: CGFloat
                var g: CGFloat
                var b: CGFloat
                var a: CGFloat
                color?.getRed(r, green: g, blue: b, alpha: a)
                let ir: UInt32 = (UInt32)(r * 255)
                let ig: UInt32 = (UInt32)(g * 255)
                let ib: UInt32 = (UInt32)(b * 255)
                let ia: UInt32 = (UInt32)(a * 255)
                setPenStateData.colorState = (ia << 24) | (ir << 16) | (ig << 8) | (ib)
            }
            else {
                setPenStateData.colorState = 0
            }
            setPenStateData.usePenTipOnOff = 1
            setPenStateData.useAccelerator = 1
            setPenStateData.useHover = 2
            setPenStateData.beepOnOff = 1
        }
        let data = Data(bytes: setPenStateData, length: MemoryLayout<setPenStateData>.size)
        commManager.writeSetPenState(data)
    }
    func setPenStateWithTimeTick() {
        let timeInMiliseconds: TimeInterval = Date().timeIntervalSince1970 * 1000
        let localTimeZone = NSTimeZone.local()
        let millisecondsFromGMT: Int = 1000 * localTimeZone.secondsFromGMT + localTimeZone.daylightSavingTimeOffset * 1000
        var setPenStateData: SetPenStateStruct
        setPenStateData.timeTick = (UInt64)
        setPenStateData.timezoneOffset = (int32_t)
        N.Log("set timezoneOffset \(setPenStateData.timezoneOffset), timeTick \(setPenStateData.timeTick)")
        if penStatus {
            let color: UInt32 = penStatus.colorState
            setPenStateData.colorState = (color & 0x00ffffff) | (0x01000000)
            setPenStateData.usePenTipOnOff = penStatus.usePenTipOnOff
            setPenStateData.useAccelerator = penStatus.useAccelerator
            setPenStateData.useHover = 2
            setPenStateData.beepOnOff = penStatus.beepOnOff
            setPenStateData.autoPwrOnTime = penStatus.autoPwrOffTime
            setPenStateData.penPressure = penStatus.penPressure
            let data = Data(bytes: setPenStateData, length: MemoryLayout<setPenStateData>.size)
            commManager.writeSetPenState(data)
        }
        else {
            N.Log("setPenStateWithTimeTick, self.penStatus : nil")
        }
    }
    func setPenStateWithPenPressure(_ penPressure: UInt16) {
        let timeInMiliseconds: TimeInterval = Date().timeIntervalSince1970 * 1000
        let localTimeZone = NSTimeZone.local()
        let millisecondsFromGMT: Int = 1000 * localTimeZone.secondsFromGMT + localTimeZone.daylightSavingTimeOffset * 1000
        var setPenStateData: SetPenStateStruct
        setPenStateData.timeTick = (UInt64)
        setPenStateData.timezoneOffset = (int32_t)
        N.Log("set timezoneOffset \(setPenStateData.timezoneOffset), timeTick \(setPenStateData.timeTick)")
        if penStatus {
            let color: UInt32 = penStatus.colorState
            setPenStateData.colorState = (color & 0x00ffffff) | (0x01000000)
            setPenStateData.usePenTipOnOff = penStatus.usePenTipOnOff
            setPenStateData.useAccelerator = penStatus.useAccelerator
            setPenStateData.useHover = 2
            setPenStateData.beepOnOff = penStatus.beepOnOff
            setPenStateData.autoPwrOnTime = penStatus.autoPwrOffTime
        }
        setPenStateData.penPressure = penPressure
        let data = Data(bytes: setPenStateData, length: MemoryLayout<setPenStateData>.size)
        commManager.writeSetPenState(data)
    }
    func setPenStateWithAutoPwrOffTime(_ autoPwrOff: UInt16) {
        let timeInMiliseconds: TimeInterval = Date().timeIntervalSince1970 * 1000
        let localTimeZone = NSTimeZone.local()
        let millisecondsFromGMT: Int = 1000 * localTimeZone.secondsFromGMT + localTimeZone.daylightSavingTimeOffset * 1000
        var setPenStateData: SetPenStateStruct
        setPenStateData.timeTick = (UInt64)
        setPenStateData.timezoneOffset = (int32_t)
        N.Log("set timezoneOffset \(setPenStateData.timezoneOffset), timeTick \(setPenStateData.timeTick)")
        if penStatus {
            let color: UInt32 = penStatus.colorState
            setPenStateData.colorState = (color & 0x00ffffff) | (0x01000000)
            setPenStateData.usePenTipOnOff = penStatus.usePenTipOnOff
            setPenStateData.useAccelerator = penStatus.useAccelerator
            setPenStateData.useHover = 2
            setPenStateData.beepOnOff = penStatus.beepOnOff
            setPenStateData.penPressure = penStatus.penPressure
        }
        setPenStateData.autoPwrOnTime = autoPwrOff
        let data = Data(bytes: setPenStateData, length: MemoryLayout<setPenStateData>.size)
        commManager.writeSetPenState(data)
    }
    func setPenStateAutoPower(_ autoPower: UInt8, sound: UInt8) {
        let timeInMiliseconds: TimeInterval = Date().timeIntervalSince1970 * 1000
        let localTimeZone = NSTimeZone.local()
        let millisecondsFromGMT: Int = 1000 * localTimeZone.secondsFromGMT + localTimeZone.daylightSavingTimeOffset * 1000
        var setPenStateData: SetPenStateStruct
        setPenStateData.timeTick = (UInt64)
        setPenStateData.timezoneOffset = (int32_t)
        N.Log("set timezoneOffset \(setPenStateData.timezoneOffset), timeTick \(setPenStateData.timeTick)")
        if penStatus {
            let color: UInt32 = penStatus.colorState
            setPenStateData.colorState = (color & 0x00ffffff) | (0x01000000)
            setPenStateData.usePenTipOnOff = autoPower
            setPenStateData.useAccelerator = penStatus.useAccelerator
            setPenStateData.useHover = 2
            setPenStateData.beepOnOff = sound
            setPenStateData.autoPwrOnTime = penStatus.autoPwrOffTime
            setPenStateData.penPressure = penStatus.penPressure
        }
        else {
            let color: UIColor? = nil
            if color != nil {
                var r: CGFloat
                var g: CGFloat
                var b: CGFloat
                var a: CGFloat
                color?.getRed(r, green: g, blue: b, alpha: a)
                let ir: UInt32 = (UInt32)(r * 255)
                let ig: UInt32 = (UInt32)(g * 255)
                let ib: UInt32 = (UInt32)(b * 255)
                let ia: UInt32 = (UInt32)(a * 255)
                setPenStateData.colorState = (ia << 24) | (ir << 16) | (ig << 8) | (ib)
            }
            else {
                setPenStateData.colorState = 0
            }
            setPenStateData.usePenTipOnOff = autoPower
            setPenStateData.useAccelerator = 1
            setPenStateData.useHover = 2
            setPenStateData.beepOnOff = sound
            setPenStateData.autoPwrOnTime = 15
            setPenStateData.penPressure = 20
        }
        let data = Data(bytes: setPenStateData, length: MemoryLayout<setPenStateData>.size)
        commManager.writeSetPenState(data)
    }
    func setPenStateWithRGB(_ color: UInt32) {
        let timeInMiliseconds: TimeInterval = Date().timeIntervalSince1970 * 1000
        let localTimeZone = NSTimeZone.local()
        let millisecondsFromGMT: Int = 1000 * localTimeZone.secondsFromGMT + localTimeZone.daylightSavingTimeOffset * 1000
        var setPenStateData: SetPenStateStruct
        setPenStateData.timeTick = (UInt64)
        setPenStateData.timezoneOffset = (int32_t)
        N.Log("set timezoneOffset \(setPenStateData.timezoneOffset), timeTick \(setPenStateData.timeTick)")
        if penStatus {
            N.Log("setPenStateWithRGB color 0x\(UInt(color))")
            setPenStateData.colorState = (color & 0x00ffffff) | (0x01000000)
            setPenStateData.usePenTipOnOff = penStatus.usePenTipOnOff
            setPenStateData.useAccelerator = penStatus.useAccelerator
            setPenStateData.useHover = 2
            setPenStateData.beepOnOff = penStatus.beepOnOff
            setPenStateData.autoPwrOnTime = penStatus.autoPwrOffTime
            setPenStateData.penPressure = penStatus.penPressure
        }
        else {
            N.Log("setPenStateWithRGB color 0x\(UInt(color))")
            setPenStateData.colorState = (color & 0x00ffffff) | (0x01000000)
            setPenStateData.usePenTipOnOff = 1
            setPenStateData.useAccelerator = 1
            setPenStateData.useHover = 2
            setPenStateData.beepOnOff = 1
            setPenStateData.autoPwrOnTime = 15
            setPenStateData.penPressure = 20
        }
        let data = Data(bytes: setPenStateData, length: MemoryLayout<setPenStateData>.size)
        commManager.writeSetPenState(data)
    }
    func setPenStateWithHover(_ useHover: UInt16) {
        let timeInMiliseconds: TimeInterval = Date().timeIntervalSince1970 * 1000
        let localTimeZone = NSTimeZone.local()
        let millisecondsFromGMT: Int = 1000 * localTimeZone.secondsFromGMT + localTimeZone.daylightSavingTimeOffset * 1000
        var setPenStateData: SetPenStateStruct
        setPenStateData.timeTick = (UInt64)
        setPenStateData.timezoneOffset = (int32_t)
        N.Log("set timezoneOffset \(setPenStateData.timezoneOffset), timeTick \(setPenStateData.timeTick)")
        if penStatus {
            let color: UInt32 = penStatus.colorState
            setPenStateData.colorState = (color & 0x00ffffff) | (0x01000000)
            setPenStateData.usePenTipOnOff = penStatus.usePenTipOnOff
            setPenStateData.useAccelerator = penStatus.useAccelerator
            setPenStateData.beepOnOff = penStatus.beepOnOff
            setPenStateData.autoPwrOnTime = penStatus.autoPwrOffTime
            setPenStateData.penPressure = penStatus?.penPressure
        }
        setPenStateData.useHover = useHover
        let data = Data(bytes: setPenStateData, length: MemoryLayout<setPenStateData>.size)
        commManager.writeSetPenState(data)
    }
    func convertRGB(toUIColor penTipColor: UInt32) -> UIColor {
        let red: UInt8 = (UInt8)(penTipColor >> 16) & 0xff
        let green: UInt8 = (UInt8)(penTipColor >> 8) & 0xff
        let blue = UInt8(penTipColor) & 0xff
        let color = UIColor(red: CGFloat(red / 255), green: CGFloat(green / 255), blue: CGFloat(blue / 255), alpha: CGFloat(1.0))
        return color
    }
    */
    func setNoteIdList() {
//        if canvasStartDelegate {
//            DispatchQueue.main.async(execute: {() -> Void in
//                canvasStartDelegate.setPenCommNoteIdList()
//            })
//        }
    }
    /*
    func setAllNoteIdList() {
        var noteIdList: SetNoteIdListStruct
        var data: Data?
        //NISDK -
        noteIdList.type = 3
        let index: Int = 0
        noteIdList.count = index
        data = Data(bytes: noteIdList, length: MemoryLayout<noteIdList>.size)
        commManager.writeNoteIdList(data)
    }
    func setNoteIdListFromPList() {
        var noteIdList: SetNoteIdListStruct
        var data: Data?
        var section_id: UInt8
        var owner_id: UInt32
        var noteIds: [Any]
        let noteInfo = NPPaperManager.sharedInstance()
        let notesSupported: [Any] = noteInfo.notesSupported()
        if isEmpty(noteInfo.paperInfos) {
            return
        }
        let allKeyName: [Any] = noteInfo.paperInfos.keys
        noteIdList.type = 1
        // Note Id
        for note: [AnyHashable: Any] in notesSupported {
            section_id = CUnsignedChar((note["section"] as? NSNumber))
            owner_id = (UInt32)
            CUnsignedInt((note["owner"] as? NSNumber))
            noteIds = (note["noteIds"] as? [Any])
            noteIdList.params[0] = (section_id << 24) | owner_id
            let noteIdCount = Int(noteIds.count)
            var index: Int = 0
            for i in 0..<noteIdCount {
                noteIdList.params[index + 1] = (UInt32)
                CUnsignedInt((noteIds[i] as? NSNumber))
                N.Log("note id at \(i) : \(UInt(noteIdList.params[index + 1]))")
                index += 1
                if index == (NOTE_ID_LIST_SIZE - 1) {
                    noteIdList.count = index
                    data = Data(bytes: noteIdList, length: MemoryLayout<noteIdList>.size)
                    commManager.writeNoteIdList(data)
                    index = 0
                }
            }
            if index != 0 {
                noteIdList.count = index
                data = Data(bytes: noteIdList, length: MemoryLayout<noteIdList>.size)
                commManager.writeNoteIdList(data)
            }
        }
        //Season note
        noteIdList.type = 1
        // Note Id
        section_id = 0
        owner_id = 19
        noteIdList.params[0] = (section_id << 24) | owner_id
        noteIdList.params[1] = 1
        noteIdList.count = 1
        data = Data(bytes: noteIdList, length: MemoryLayout<noteIdList>.size)
        commManager.writeNoteIdList(data)
        // To get Seal ID
        noteIdList.type = 2
        var noteId: UInt32
        for note: [AnyHashable: Any] in notesSupported {
            section_id = SEAL_SECTION_ID
            // Fixed for seal
            noteIds = (note["noteIds"] as? [Any])
            let noteIdCount = Int(noteIds.count)
            var index: Int = 0
            for i in 0..<noteIdCount {
                noteId = (UInt32)
                CUnsignedInt((noteIds[i] as? NSNumber))
                noteIdList.params[index] = (section_id << 24) | noteId
                index += 1
                if index == (NOTE_ID_LIST_SIZE) {
                    noteIdList.count = index
                    var data = Data(bytes: noteIdList, length: MemoryLayout<noteIdList>.size)
                    commManager.writeNoteIdList(data)
                    index = 0
                }
            }
            if index != 0 {
                noteIdList.count = index
                data = Data(bytes: noteIdList, length: MemoryLayout<noteIdList>.size)
                commManager.writeNoteIdList(data)
            }
        }
    }
    func setNoteIdListSectionOwnerFromPList() {
        var noteIdList: SetNoteIdListStruct
        var data: Data?
        var section_id: UInt8
        var owner_id: UInt32
        let noteInfo = NPPaperManager.sharedInstance()
        let notesSupported: [Any] = noteInfo.notesSupported()
        noteIdList.type = 2
        let index: Int = 0
        for note: [AnyHashable: Any] in notesSupported {
            section_id = CUnsignedChar((note["section"] as? NSNumber))
            owner_id = (UInt32)
            CUnsignedInt((note["owner"] as? NSNumber))
            noteIdList.params[index += 1] = (section_id << 24) | owner_id
        }
        noteIdList.count = index
        data = Data(bytes: noteIdList, length: MemoryLayout<noteIdList>.size)
        commManager.writeNoteIdList(data)
    }
    func setPassword(_ pinNumber: String) {
        var request: PenPasswordChangeRequestStruct
        //NSString *currentPassword = [MyFunctions loadPasswd];
        let currentPassword: String = "0000"
        let stringData: Data? = currentPassword.data(using: String.Encoding.utf8)
        memcpy(request.prevPassword, stringData?.bytes, MemoryLayout<stringData>.size)
        let newData: Data? = pinNumber.data(using: String.Encoding.utf8)
        memcpy(request.newPassword, newData?.bytes, MemoryLayout<newData>.size)
        for i in 0..<12 {
            request.prevPassword[i + 4] = UInt8(nil)
            request.newPassword[i + 4] = UInt8(nil)
        }
        let data = Data(bytes: request, length: MemoryLayout<PenPasswordChangeRequestStruct>.size)
        commManager.writeSetPasswordData(data)
    }
    func changePassword(from curNumber: String, to pinNumber: String) {
        var request: PenPasswordChangeRequestStruct
        let stringData: Data? = curNumber.data(using: String.Encoding.utf8)
        memcpy(request.prevPassword, stringData?.bytes, MemoryLayout<stringData>.size)
        let newData: Data? = pinNumber.data(using: String.Encoding.utf8)
        memcpy(request.newPassword, newData?.bytes, MemoryLayout<newData>.size)
        for i in 0..<12 {
            request.prevPassword[i + 4] = UInt8(nil)
            request.newPassword[i + 4] = UInt8(nil)
        }
        let data = Data(bytes: request, length: MemoryLayout<PenPasswordChangeRequestStruct>.size)
        commManager.writeSetPasswordData(data)
    }
    func setBTComparePassword(_ pinNumber: String) {
        var response: PenPasswordResponseStruct
        let stringData: Data? = pinNumber.data(using: String.Encoding.utf8)
        memcpy(response.password, stringData?.bytes, MemoryLayout<stringData>.size)
        for i in 0..<12 {
            response.password[i + 4] = UInt8(nil)
        }
        let data = Data(bytes: response, length: MemoryLayout<PenPasswordResponseStruct>.size)
        commManager.writePenPasswordResponseData(data)
    }
    func writeReadyExchangeData(_ ready: Bool) {
        var request: ReadyExchangeDataStruct
        request.ready = ready ? 1 : 0
        let data = Data(bytes: request, length: MemoryLayout<ReadyExchangeDataStruct>.size)
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
    */
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
        if commManager.isPenSDK2 {
            requestOfflineFileList2()
            return true
        }
        if offlineFileProcessing {
            return false
        }
        var request = RequestOfflineFileListStruct()
        request.status = 0x00
        let data = Data([request.status])
        commManager.writeRequestOfflineFileList(data)
        return true
    }
    
    /*
    func requestDelOfflineFile(_ sectionOwnerId: UInt32) -> Bool {
        var request: RequestDelOfflineFileStruct
        request.sectionOwnerId = sectionOwnerId
        let data = Data(bytes: request, length: MemoryLayout<request>.size)
        commManager.writeRequestDelOfflineFile(data)
        return true
    }
    func requestOfflineData(withOwnerId ownerId: UInt32, noteId: UInt32) -> Bool {
        let noteList: [Any]? = (offlineFileList[Int(ownerId)] as? [Any])
        if noteList == nil {
            return false
        }
        if (noteList? as NSArray).index(of: Int(noteId)) == NSNotFound {
            return false
        }
        var request: RequestOfflineFileStruct
        request.sectionOwnerId = ownerId
        request.noteCount = 1
        request.noteId[0] = noteId
        let data = Data(bytes: request, length: MemoryLayout<request>.size)
        commManager.writeRequestOfflineFile(data)
        return true
    }
    func offlineFileAck(forType type: UInt8, index: UInt8) {
        var fileAck: OfflineFileAckStruct
        fileAck.type = type
        fileAck.index = index
        let data = Data(bytes: fileAck, length: MemoryLayout<fileAck>.size)
        commManager.writeOfflineFileAck(data)
    }
    func sendUpdateFileInfo(at fileUrl: URL) {
        readUpdateData(from: fileUrl)
        var fileInfo: UpdateFileInfoStruct
        let fileName = "\\Update.zip"
        memset(fileInfo.filePath, 0, MemoryLayout<fileInfo.filePath>.size)
        memcpy(fileInfo.filePath, fileName, strlen(fileName))
        fileInfo.fileSize = (UInt32)
        updateFileData.length
        let size = Float(fileInfo.fileSize()) / UPDATE_DATA_PACKET_SIZE
        fileInfo.packetCount = ceilf(size)
        fileInfo.packetSize = UPDATE_DATA_PACKET_SIZE
        let data = Data(bytes: fileInfo, length: MemoryLayout<fileInfo>.size)
        commManager.writeUpdateFileInfo(data)
    }
    func sendUpdateFileData(at index: UInt16) {
        N.Log("sendUpdateFileDataAt \(index)")
        var updateData: UpdateFileDataStruct
        updateData.index = index
        let range: NSRange
        range.location = index * UPDATE_DATA_PACKET_SIZE
        if (range.location + UPDATE_DATA_PACKET_SIZE) > updateFileData.length {
            range.length = updateFileData.length - range.location
        }
        else {
            range.length = UPDATE_DATA_PACKET_SIZE
        }
        if range.length > 0 {
            updateFileData.getBytes(updateData.fileData, range: range)
            let data = Data(bytes: updateData, length: (MemoryLayout<updateData.index>.size + range.length))
            commManager.writeUpdateFileData(data)
        }
        let progress_percent = (Float(index)) / (Float(packetCount)) * 100.0
        notifyFWUpdate(FW_UPDATE_DATA_RECEIVE_PROGRESSING, percent: progress_percent)
    }
    func readUpdateData(from fileUrl: URL) {
        updateFileData = Data(contentsOf: fileUrl)
        updateFilePosition = 0
    }
    func sendUpdateFileInfoAtUrl(toPen fileUrl: URL) {
        cancelFWUpdate = false
        readUpdateData(from: fileUrl)
        var fileInfo: UpdateFileInfoStruct
        //char *fileName = "\\Update.zip";
        let fileNameString: String = "\\\(fileUrl.path.lastPathComponent)"
        let fileName = fileNameString.utf8
        memset(fileInfo.filePath, 0, MemoryLayout<fileInfo.filePath>.size)
        memcpy(fileInfo.filePath, fileName, strlen(fileName))
        fileInfo.fileSize = (UInt32)
        updateFileData.length
        let size = Float(fileInfo.fileSize()) / UPDATE_DATA_PACKET_SIZE
        fileInfo.packetCount = ceilf(size)
        fileInfo.packetSize = UPDATE_DATA_PACKET_SIZE
        packetCount = fileInfo.packetCount
        let data = Data(bytes: fileInfo, length: MemoryLayout<fileInfo>.size)
        commManager.writeUpdateFileInfo(data)
        notifyFWUpdate(FW_UPDATE_DATA_RECEIVE_START, percent: 0.0)
    }
    
    //////////////////////////////////////////////////////////////////
    //
    //
    //             Pen Password
    //
    //////////////////////////////////////////////////////////////////
    func parsePenPasswordRequest(_ data: [UInt8], withLength length: Int) {
        let request: PenPasswordRequestStruct? = (data as? PenPasswordRequestStruct)
        if penCommIdDataReady && penCommStrokeDataReady && penCommUpDownDataReady && penExchangeDataReady {
            DispatchQueue.main.async(execute: {() -> Void in
                penPasswordDelegate.penPasswordRequest(request)
            })
        }
    }
    func parsePenPasswordChangeResponse(_ data: [UInt8], withLength length: Int) {
        let response: PenPasswordChangeResponseStruct? = (data as? PenPasswordChangeResponseStruct)
        if response?.passwordState == 0x00 {
            N.Log("password change success")
            commManager.hasPenPassword = true
        }
        else if response?.passwordState == 0x01 {
            N.Log("password change fail")
        }
        let PasswordChangeResult: Bool? = (response?.passwordState) ? false : true
        let info: [AnyHashable: Any] = ["result": Int(PasswordChangeResult)]
        DispatchQueue.main.async(execute: {() -> Void in
            NotificationCenter.default.post(name: NJPenCommParserPenPasswordSutupSuccess, object: nil, userInfo: info)
        })
    }
    */
}
