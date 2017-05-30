//
//  NJOfflineSyncViewController.swift
//  n2sampleSwift
//
//  Created by Aram Moon on 2017. 5. 16..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import UIKit


enum OFFLINE_DOT_CHECK_STATE : Int {
    case NONE
    case FIRST
    case SECOND
    case THIRD
    case NORMAL
}

class NJOfflineSyncViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,NJOfflineDataDelegate {
    
    let kViewTag = 1
    //#define POINT_COUNT_MAX 1024*STROKE_NUMBER_MAGNITUDE
    private var kTitleKey: String = "title"
    private var kViewKey: String = "viewKey"
    private var kViewControllerKey: String = "viewController"
    private var kSwitchCellId: String = "SwitchCell"
    private var kControlCellId: String = "ControlCell"
    private var kPauseCellId: String = "PauseCell"

    var oPage: NJPage?
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    var parentController: NJViewController?

    var menuList : [Int] = []
    var refreshControl: UIRefreshControl?
    var dateLabel: UILabel?
    var lastUpdated: String = ""
    var progressValue: Float = 0.0
    var progressView: UIProgressView?
    var ownerIdToRequest: UInt32 = 0
    var noteIdToRequest: UInt32 = 0
    var noteId: NSNumber?
    var isNoteChange: Bool = false
    var pButton: UIButton?
    var isPauseBtn: Bool = false
    var offlineIdList = [Any]()
    var noteIdList = [Any]()
    var indicator: UIActivityIndicatorView?
    var offlinePageId: UInt32 = 0
    var offlineOverStrokeArray = [Any]()
    
    private var offlineDotData0 = OffLineDataDotStruct()
    private var offlineDotData1 = OffLineDataDotStruct()
    private var offlineDotData2 = OffLineDataDotStruct()
    private var offline2DotData0 = OffLineData2DotStruct()
    private var offline2DotData1 = OffLineData2DotStruct()
    private var offline2DotData2 = OffLineData2DotStruct()
    private var offlineDotCheckState = OFFLINE_DOT_CHECK_STATE(rawValue: 0)!
    
    private var startTime: UInt64 = 0
    private var offlinePenColor: UInt32 = 0
    private var point_index: Int = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        offlinePageId = 0
        offlineOverStrokeArray = [Any]()
        oPage = NJPage(notebookId: 100, andPageNumber: 100)
    }
    
    // MARK: - UIViewController delegate
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        indicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        indicator?.center = CGPoint(x: CGFloat(view.frame.size.width / 2), y: CGFloat(view.frame.size.height / 2))
        indicator?.hidesWhenStopped = true
        view.addSubview(indicator!)
        NJPenCommManager.sharedInstance().setOfflineDataDelegate(self)
    }


    //MARK: - NJOfflineDataDelegate -
    //Step1 : Offline Data Check
    func offlineDataDidReceiveNoteList(_ noteListDic: [AnyHashable: Any]) {
        print("offlineDataDidReceiveNoteList \(noteListDic)")
        // Parse NoteListDictionary
        for data in noteListDic{
            if let ownerId = data.key as? UInt32 {
                if ownerIdToRequest == 0 || noteIdToRequest == 0 {
                    ownerIdToRequest = UInt32(ownerId)
                }
                print("** Owner Id : \(ownerId)")
                
                if let noteList = data.value as? [Int]{
                    menuList = noteList
                    for noteId in noteList {
                        print("   - Note Id : \(noteId)")
                    }
                }
            }

        }

        if menuList.count > 0 {
            tableView.reloadData()
        }
    }
    //Step2 : Offline Data Request
    func requestOfflinedata(withOwnerId:UInt32, noteId: UInt32){
        NJPenCommManager.sharedInstance().requestOfflineData(withOwnerId: withOwnerId, noteId: noteId)
    }
    
    
    //Step3 : Offline Data receiving....
    func offlineDataReceive(_ status: OFFLINE_DATA_STATUS, percent: Float) {
        print("offlineDataReceiveStatus : status \(status), percent \(percent)")
        indicator?.startAnimating()
        if status == OFFLINE_DATA_RECEIVE_END {
            indicator?.stopAnimating()
        }
    }
    
    func offlineDataReceivePercent(_ percent: Float) {
        print("offlineDataReceiveStatus : percent \(percent)")
        progressView?.progress = percent / 100.0
    }
    
    private func offlineDataDidReceiveNoteListCount(_ noteCount: Int, forSectionOwnerId sectionOwnerId: UInt32) {
        let section: UInt8 = UInt8((sectionOwnerId >> 24) & 0xff)
        let ownerId: UInt32 = sectionOwnerId & 0x00ffffff
        let offlineDataListNoteCount: Int = noteCount
        print("offline Data Note List Count: \(offlineDataListNoteCount) for sectionId \(section), ownerId \(ownerId)")
    }
    
    func offlineDataPath(beforeParsed path: String) {
        let offlineDataPath: String = path
        print("offline raw data path: \(offlineDataPath)")
    }
    
    //SDK1.0
    func parseOfflinePenData(_ penData: Data) -> Bool {
//        var dataPosition: Int = 0
//        var dataLength: Int = penData.count
//        let headerSize: Int = MemoryLayout<OffLineDataFileHeaderStruct>.size
//        dataLength = dataLength - headerSize
//        var range: NSRange = NSMakeRange(Int(dataLength), headerSize)
//        var header = OffLineDataFileHeaderStruct.init()
//        penData.getBytes(header, range: range)
//        let noteId: UInt32 = header.nNoteId
//        let pageId: UInt32 = header.nPageId
//        let ownerId: UInt32 = (header.nOwnerId & 0x00ffffff)
//        let sectionId: UInt32 = ((header.nOwnerId >> 24) & 0x000000ff)
//        var offlineStrokeArray = [Any]()
//        var char1: UInt8
//        var char2: UInt8
//        var strokeHeader: OffLineDataStrokeHeaderStruct
//        var offlineLastStrokeStartTime: UInt64 = 0
//        while dataPosition < dataLength {
//            if (dataLength - dataPosition) < (MemoryLayout<OffLineDataStrokeHeaderStruct>.size + 2) {
//                break
//            }
//            range.location = dataPosition += 1
//            range.length = 1
//            penData.getBytes(char1, range: range)
//            range.location = dataPosition += 1
//            penData.getBytes(char2, range: range)
//            if char1 == "L" && char2 == "N" {
//                range.location = dataPosition
//                range.length = MemoryLayout<OffLineDataStrokeHeaderStruct>.size
//                penData.getBytes(strokeHeader, range: range)
//                dataPosition += MemoryLayout<OffLineDataStrokeHeaderStruct>.size
//                if (dataLength - dataPosition) < (strokeHeader.nDotCount * MemoryLayout<OffLineDataDotStruct>.size) {
//                    break
//                }
//                let stroke: NJStroke? = parseOfflineDots(penData, startAt: dataPosition, withFileHeader: header, andStrokeHeader: strokeHeader)
//                dataPosition += (strokeHeader.nDotCount * MemoryLayout<OffLineDataDotStruct>.size)
//                offlineLastStrokeStartTime = strokeHeader.nStrokeStartTime
//                // addedby namSSan 2015-03-10
//                offlineStrokeArray.append(stroke)
//            }
//        }
        //should check if it is working
//        if (strokeHeader.nDotCount > MAX_NODE_NUMBER) && (offlineOverStrokeArray.count > 0) {
//            offlineStrokeArray = offlineStrokeArray + offlineOverStrokeArray
//            offlineOverStrokeArray.removeAll()
//        }
//        let lastStrokeTime = Date(timeIntervalSince1970: (offlineLastStrokeStartTime / 1000.0))
//        didReceiveOfflineStrokes(offlineStrokeArray, forNotebookId: noteId, pageNumber: pageId, section: sectionId, owner: ownerId, lastStrokeTime: lastStrokeTime)
        return true
    }
    
    func didReceiveOfflineStrokes(_ strokes: [NJStroke], forNotebookId notebookId: Int, pageNumber pageNum: Int, section: Int, owner: Int, lastStrokeTime time: Date) {
        for stroke: NJStroke in strokes {
//            oPage.addStrokes(stroke)
        }
    }
    
    func parseOfflineDots(_ penData: Data, startAt position: Int, withFileHeader pFileHeader: OffLineDataFileHeaderStruct, andStrokeHeader pStrokeHeader: OffLineDataStrokeHeaderStruct) -> NJStroke {
//        var dot: OffLineDataDotStruct
//        let range: NSRange = [position, MemoryLayout<OffLineDataDotStruct>.size]
//        let dotCount: Int = min(MAX_NODE_NUMBER, pStrokeHeader.nDotCount)
//        let point_x_buff: [Float] = malloc(MemoryLayout<Float>.size * dotCount)
//        let point_y_buff: [Float] = malloc(MemoryLayout<Float>.size * dotCount)
//        let point_p_buff: [Float] = malloc(MemoryLayout<Float>.size * dotCount)
//        let time_diff_buff: Int? = malloc(MemoryLayout<Int>.size * dotCount)
//        if (point_x_buff == nil) || (point_y_buff == nil) || (point_p_buff == nil) || (time_diff_buff == nil) {
//            return nil
//        }
//        point_index = 0
//        offlineDotCheckState = .FIRST
//        startTime = pStrokeHeader.nStrokeStartTime
//        let color: UInt32 = pStrokeHeader.nLineColor
//        if     /*(color & 0xFF000000) == 0x01000000 && */
//            (color & 0x00ffffff) != 0x00ffffff && (color & 0x00ffffff) != 0x00000000 {
//            offlinePenColor = color | 0xff000000
//            // set Alpha to 255
//        }
//        else {
//            offlinePenColor = 0
//        }
//        print("offlinePenColor 0x\(UInt(offlinePenColor))")
//        if !(oPage != nil) {
//            oPage = NJPage(notebookId: Int(pFileHeader.nNoteId), andPageNumber: pFileHeader.nPageId)
//        }
//        for i in 0..<pStrokeHeader.nDotCount {
//            penData.getBytes(dot, range: range)
//            dotChecker(forOfflineSync: dot, pointX: point_x_buff, pointY: point_y_buff, pointP: point_p_buff, timeDiff: time_diff_buff)
//            if point_index >= MAX_NODE_NUMBER {
//                let stroke = NJStroke(rawDataX: point_x_buff, y: point_y_buff, pressure: point_p_buff, time_diff: time_diff_buff, penColor: offlinePenColor, penThickness: 1, startTime: startTime, size: point_index, normalizer: oPage.inputScale)
//                offlineOverStrokeArray.append(stroke)
//                point_index = 0
//                startTime += 1
//            }
//            position += MemoryLayout<OffLineDataDotStruct>.size
//            range.location = position
//        }
//        offlineDotCheckerLastPointX(point_x_buff, pointY: point_y_buff, pointP: point_p_buff, timeDiff: time_diff_buff)
//        let stroke = NJStroke(rawDataX: point_x_buff, y: point_y_buff, pressure: point_p_buff, time_diff: time_diff_buff, penColor: offlinePenColor, penThickness: 1, startTime: startTime, size: point_index, normalizer: oPage.inputScale)
//        point_index = 0
//        if point_x_buff {
//            free(point_x_buff)
//        }
//        if point_y_buff {
//            free(point_y_buff)
//        }
//        if point_p_buff {
//            free(point_p_buff)
//        }
//        if time_diff_buff {
//            free(time_diff_buff)
//        }
        return NJStroke()//stroke
    }
    
    //SDK2.0
    func parseSDK2OfflinePenData(_ penData: Data!, andOfflineDataHeader offlineDataHeader: UnsafeMutablePointer<OffLineData2HeaderStruct>!) -> Bool {
        let dataHeader = offlineDataHeader.pointee
        print("parseSDK2OfflinePenData \(dataHeader)")
        var pageId: UInt32 = 0
        let noteId: UInt32 = dataHeader.nNoteId
        let ownerId: UInt32 = (dataHeader.nSectionOwnerId & 0x00ffffff)
        let sectionId: UInt32 = ((dataHeader.nSectionOwnerId >> 24) & 0x000000ff)
        var offlineDataDic = [AnyHashable: Any]()
        var dataPosition: Int = 0
        var dataLength: Int = penData.count
        var range: NSRange = NSRange()
        var offlineStrokeArray : [NJStroke] = []
        var lastStrokeTime: Date?
        offlinePageId = 0
        var strokeHeader = OffLineData2StrokeHeaderStruct()
        var offlineLastStrokeStartTime: UInt64 = 0
        
        while dataPosition < dataLength
        {
            var x :[Float] = []
            var y : [Float] = []
            var p : [Float] = []
            var tt :[Int] = []
        
            var dataSize = MemoryLayout<OffLineData2StrokeHeaderStruct>.size
            var strokeArray = penData.subdata(in: dataPosition..<dataPosition+dataSize)
            strokeArray.withUnsafeBytes({ (bytes : UnsafePointer<OffLineData2StrokeHeaderStruct>) -> Void in
                strokeHeader = UnsafePointer<OffLineData2StrokeHeaderStruct>(bytes).pointee
            })
            dataPosition += dataSize
            var dotdata = OffLineData2DotStruct()
            for i in 0..<Int(strokeHeader.nDotCount){
                dataSize = MemoryLayout<OffLineData2DotStruct>.size
                var dotArray = penData.subdata(in: dataPosition..<dataPosition+dataSize)
                dotArray.withUnsafeBytes({ (bytes : UnsafePointer<OffLineData2DotStruct>) -> Void in
                    dotdata = UnsafePointer<OffLineData2DotStruct>(bytes).pointee
                })
                dataPosition += dataSize
                x.append(Float(dotdata.x) + Float(dotdata.fx) * 0.01)
                y.append(Float(dotdata.y) + Float(dotdata.fy) * 0.01)
                p.append(Float(dotdata.force))
                tt.append(Int(dotdata.nTimeDelta))
            }
            
            let stroke = NJStroke(x: x, y: y, p: p, time: tt, penColor: strokeHeader.nLineColor, penThickness: 1, start_at: Int(strokeHeader.nStrokeStartTime), size: Int(strokeHeader.nDotCount))
            offlineStrokeArray.append(stroke)
        }
        
        print("data: \(offlineStrokeArray.count)")
        oPage?.strokes = offlineStrokeArray
        let pageCanvasController = SimpleViewController(nibName: nil, bundle: nil)
        pageCanvasController.page = oPage
        present(pageCanvasController, animated: true, completion: nil)

//        let stroke: NJStroke? = parseSDK2OfflineDots(penData, startAt: dataPosition, withOfflineDataHeader: offlineDataHeader, andStrokeHeader: strokeHeader)
//        offlineStrokeArray.append(stroke)
//        dataPosition += (strokeHeader.nDotCount * MemoryLayout<OffLineData2DotStruct>.size)
//        offlineLastStrokeStartTime = strokeHeader.nStrokeStartTime
//        if (strokeHeader.nDotCount > MAX_NODE_NUMBER) && (offlineOverStrokeArray.count > 0) {
//            offlineStrokeArray = offlineStrokeArray + offlineOverStrokeArray
//            offlineOverStrokeArray.removeAll()
//        }

        
//        while dataPosition < dataLength {
//            if (dataLength - dataPosition) < (MemoryLayout<OffLineData2StrokeHeaderStruct>.size + 2) {
//                break
//            }
//            range.location = dataPosition
//            range.length = MemoryLayout<OffLineData2StrokeHeaderStruct>.size

//            
//            dataPosition += MemoryLayout<OffLineData2StrokeHeaderStruct>.size
//            if (dataLength - dataPosition) < (strokeHeader.nDotCount * MemoryLayout<OffLineData2DotStruct>.size) {
//                break
//            }
//            pageId = strokeHeader.nPageId
//            if (offlinePageId != 0) && (offlinePageId != pageId) && (offlineStrokeArray.count > 0) {
//                let pageIdNum = Int(offlinePageId)
//                lastStrokeTime = Date(timeIntervalSince1970: (offlineLastStrokeStartTime / 1000.0))
//                var offlineStrokeArrayTemp: [Any] = offlineStrokeArray
//                let offlineDataDicForPageId: [AnyHashable: Any] = [
//                    "stroke" : offlineStrokeArrayTemp,
//                    "time" : lastStrokeTime
//                ]
//                
//                offlineDataDic[pageIdNum] = offlineDataDicForPageId
//                offlineStrokeArray.removeAll()
//                offlinePageId = pageId
//            }
//            else {
//                offlinePageId = pageId
//            }
//            let stroke: NJStroke? = parseSDK2OfflineDots(penData, startAt: dataPosition, withOfflineDataHeader: offlineDataHeader, andStrokeHeader: strokeHeader)
//            offlineStrokeArray.append(stroke)
//            dataPosition += (strokeHeader.nDotCount * MemoryLayout<OffLineData2DotStruct>.size)
//            offlineLastStrokeStartTime = strokeHeader.nStrokeStartTime
//            if (strokeHeader.nDotCount > MAX_NODE_NUMBER) && (offlineOverStrokeArray.count > 0) {
//                offlineStrokeArray = offlineStrokeArray + offlineOverStrokeArray
//                offlineOverStrokeArray.removeAll()
//            }
//        }
        return true
    }
    
    func parseSDK2OfflineDots(_ penData: Data, startAt position: Int, withOfflineDataHeader pFileHeader: UnsafeMutablePointer<OffLineData2HeaderStruct>! , andStrokeHeader pStrokeHeader: OffLineData2StrokeHeaderStruct) -> NJStroke {
        var fileHeader : OffLineData2HeaderStruct = pFileHeader.pointee
        print("parseSDK2OfflineDots \(fileHeader)")

//        var dot: OffLineData2DotStruct
//        //    float pressure, x, y;
//        let range: NSRange = [position, MemoryLayout<OffLineData2DotStruct>.size]
//        let dotCount: Int = min(MAX_NODE_NUMBER, (pStrokeHeader.nDotCount))
//        let point_x_buff: [Float] = malloc(MemoryLayout<Float>.size * dotCount)
//        let point_y_buff: [Float] = malloc(MemoryLayout<Float>.size * dotCount)
//        let point_p_buff: [Float] = malloc(MemoryLayout<Float>.size * dotCount)
//        let time_diff_buff: Int? = malloc(MemoryLayout<Int>.size * dotCount)
//        if (point_x_buff == nil) || (point_y_buff == nil) || (point_p_buff == nil) || (time_diff_buff == nil) {
//            return nil
//        }
//        point_index = 0
//        offlineDotCheckState = OFFLINE_DOT_CHECK_FIRST
//        startTime = pStrokeHeader.nStrokeStartTime
//        //    NSLog(@"offline time %llu", startTime);
//        let color: UInt32 = pStrokeHeader.nLineColor
//        if     /*(color & 0xFF000000) == 0x01000000 && */
//            (color & 0x00ffffff) != 0x00ffffff && (color & 0x00ffffff) != 0x00000000 {
//            offlinePenColor = color | 0xff000000
//            // set Alpha to 255
//        }
//        else {
//            offlinePenColor = 0
//        }
//        if !oPage {
//            oPage = NJPage(notebookId: pFileHeader.nNoteId, andPageNumber: pStrokeHeader.nPageId)
//        }
//        for i in 0..<pStrokeHeader.nDotCount {
//            penData.getBytes(dot, range: range)
//            dotChecker(forOfflineSync2: dot, pointX: point_x_buff, pointY: point_y_buff, pointP: point_p_buff, timeDiff: time_diff_buff)
//            if point_index >= MAX_NODE_NUMBER {
//                let stroke = NJStroke(rawDataX: point_x_buff, y: point_y_buff, pressure: point_p_buff, time_diff: time_diff_buff, penColor: offlinePenColor, penThickness: 1, startTime: startTime, size: point_index)
//                offlineOverStrokeArray.append(stroke)
//                point_index = 0
//                startTime += 1
//            }
//            position += MemoryLayout<OffLineData2DotStruct>.size
//            range.location = position
//        }
//        offlineDotCheckerLastPointX(point_x_buff, pointY: point_y_buff, pointP: point_p_buff, timeDiff: time_diff_buff)
//        let stroke = NJStroke(rawDataX: point_x_buff, y: point_y_buff, pressure: point_p_buff, time_diff: time_diff_buff, penColor: offlinePenColor, penThickness: 1, startTime: startTime, size: point_index)
//        point_index = 0
//        if point_x_buff {
//            free(point_x_buff)
//        }
//        if point_y_buff {
//            free(point_y_buff)
//        }
//        if point_p_buff {
//            free(point_p_buff)
//        }
//        if time_diff_buff {
//            free(time_diff_buff)
//        }
        return NJStroke()//stroke
    }
    
    //SDK1.0
    func dotChecker(forOfflineSync aDot: OffLineDataDotStruct, pointX point_x_buff: Float, pointY point_y_buff: Float, pointP point_p_buff: Float, timeDiff time_diff_buff: Int) {
        /*
        if offlineDotCheckState == . {
            if offlineDotChecker(forMiddle: aDot) {
                offlineDotAppend(offlineDotData2, pointX: point_x_buff, pointY: point_y_buff, pointP: point_p_buff, timeDiff: time_diff_buff)
                offlineDotData0 = offlineDotData1
                offlineDotData1 = offlineDotData2
            }
            else {
                print("offlineDotChecker error : middle")
            }
            offlineDotData2 = aDot
        }
        else if offlineDotCheckState == OFFLINE_DOT_CHECK_STATE {
            offlineDotData0 = aDot
            offlineDotData1 = aDot
            offlineDotData2 = aDot
            offlineDotCheckState = OFFLINE_DOT_CHECK_STATE
        }
        else if offlineDotCheckState == OFFLINE_DOT_CHECK_STATE {
            offlineDotData2 = aDot
            offlineDotCheckState = OFFLINE_DOT_CHECK_STATE
        }
        else if offlineDotCheckState == OFFLINE_DOT_CHECK_STATE {
            if offlineDotChecker(forStart: aDot) {
                offlineDotAppend(offlineDotData1, pointX: point_x_buff, pointY: point_y_buff, pointP: point_p_buff, timeDiff: time_diff_buff)
                if offlineDotChecker(forMiddle: aDot) {
                    offlineDotAppend(offlineDotData2, pointX: point_x_buff, pointY: point_y_buff, pointP: point_p_buff, timeDiff: time_diff_buff)
                    offlineDotData0 = offlineDotData1
                    offlineDotData1 = offlineDotData2
                }
                else {
                    print("offlineDotChecker error : middle2")
                }
            }
            else {
                offlineDotData1 = offlineDotData2
                print("offlineDotChecker error : start")
            }
            offlineDotData2 = aDot
            offlineDotCheckState = OFFLINE_DOT_CHECK_STATE.NONE
        }
 */
    }
    
    func offlineDotAppend(_ dot: OffLineDataDotStruct, pointX point_x_buff:inout [Float], pointY point_y_buff: inout [Float], pointP point_p_buff: inout [Float], timeDiff time_diff_buff:inout [Int]) {
        var pressure: Float
        var x: Float
        var y: Float
        x = Float(dot.x) + Float(dot.fx) * 0.01
        y = Float(dot.y) + Float(dot.fy) * 0.01
        pressure = NJPenCommManager.sharedInstance().processPressure(Float(dot.force))
//        point_x_buff[point_index] = x - oPage!.startX
        //*self.oPage.screenRatio;
//        point_y_buff[point_index] = y - oPage!.startY
        //*self.oPage.screenRatio;
        point_p_buff[point_index] = pressure
        time_diff_buff[point_index] = Int(dot.nTimeDelta)
        point_index += 1
    }
    
    func offlineDotChecker(forStart aDot: OffLineDataDotStruct) -> Bool {
        let delta: Float = 2.0
        if offlineDotData1.x > 150 || offlineDotData1.x < 1 {
            return false
        }
        if offlineDotData1.y > 150 || offlineDotData1.y < 1 {
            return false
        }
//        if ((aDot.x - offlineDotData1.x) * (offlineDotData2.x - offlineDotData1.x) > 0) && (abs(aDot.x - offlineDotData1.x) > delta) && (abs(offlineDotData1.x - offlineDotData2.x) > delta) {
//            return false
//        }
//        if (aDot.y - offlineDotData1.y) * (offlineDotData2.y - offlineDotData1.y) > 0 && abs(aDot.y - offlineDotData1.y) > delta && abs(offlineDotData1.y - offlineDotData2.y) > delta {
//            return false
//        }
        return true
    }
    
    func offlineDotChecker(forMiddle aDot: OffLineDataDotStruct) -> Bool {
        let delta: Float = 2.0
        if offlineDotData2.x > 150 || offlineDotData2.x < 1 {
            return false
        }
        if offlineDotData2.y > 150 || offlineDotData2.y < 1 {
            return false
        }
//        if (offlineDotData1.x - offlineDotData2.x) * (aDot.x - offlineDotData2.x) > 0 && abs(offlineDotData1.x - offlineDotData2.x) > delta && abs(aDot.x - offlineDotData2.x) > delta {
//            return false
//        }
//        if (offlineDotData1.y - offlineDotData2.y) * (aDot.y - offlineDotData2.y) > 0 && abs(offlineDotData1.y - offlineDotData2.y) > delta && abs(aDot.y - offlineDotData2.y) > delta {
//            return false
//        }
        return true
    }
    
    func offlineDotCheckerForEnd() -> Bool {
        let delta: Float = 2.0
        if offlineDotData2.x > 150 || offlineDotData2.x < 1 {
            return false
        }
        if offlineDotData2.y > 150 || offlineDotData2.y < 1 {
            return false
        }
//        if (offlineDotData2.x - offlineDotData0.x) * (offlineDotData2.x - offlineDotData1.x) > 0 && abs(offlineDotData2.x - offlineDotData0.x) > delta && abs(offlineDotData2.x - offlineDotData1.x) > delta {
//            return false
//        }
//        if (offlineDotData2.y - offlineDotData0.y) * (offlineDotData2.y - offlineDotData1.y) > 0 && abs(offlineDotData2.y - offlineDotData0.y) > delta && abs(offlineDotData2.y - offlineDotData1.y) > delta {
//            return false
//        }
        return true
    }
    
    func offlineDotCheckerLastPointX(_ point_x_buff: Float, pointY point_y_buff: Float, pointP point_p_buff: Float, timeDiff time_diff_buff: Int) {
        if offlineDotCheckerForEnd() {
//            offlineDotAppend(offlineDotData2, pointX: point_x_buff, pointY: point_y_buff, pointP: point_p_buff, timeDiff: time_diff_buff)
            offlineDotData2.x = UInt16(0.0)
            offlineDotData2.y = UInt16(0.0)
        }
        else {
            print("offlineDotChecker error : end")
        }
        offlineDotCheckState = OFFLINE_DOT_CHECK_STATE.NONE
    }
    
    
    //////////////////////////////////////////////////////////////////
    //
    //
    //            Offline Dot Checker
    //
    //////////////////////////////////////////////////////////////////
    //SDK2.0
    func dotChecker(forOfflineSync2 aDot: OffLineData2DotStruct, pointX point_x_buff: Float, pointY point_y_buff: Float, pointP point_p_buff: Float, timeDiff time_diff_buff: Int) {
        if offlineDotCheckState == .NORMAL {
            if offline2DotChecker(forMiddle: aDot) {
                offline2DotAppend(offline2DotData2, pointX: point_x_buff, pointY: point_y_buff, pointP: point_p_buff, timeDiff: time_diff_buff)
                offline2DotData0 = offline2DotData1
                offline2DotData1 = offline2DotData2
            }
            else {
                print("offlineDotChecker error : middle")
            }
            offline2DotData2 = aDot
        }
        else if offlineDotCheckState == .FIRST {
            offline2DotData0 = aDot
            offline2DotData1 = aDot
            offline2DotData2 = aDot
            offlineDotCheckState = .SECOND
        }
        else if offlineDotCheckState == .SECOND {
            offline2DotData2 = aDot
            offlineDotCheckState = .THIRD
        }
        else if offlineDotCheckState == .THIRD {
            if offline2DotChecker(forStart: aDot) {
                offline2DotAppend(offline2DotData1, pointX: point_x_buff, pointY: point_y_buff, pointP: point_p_buff, timeDiff: time_diff_buff)
                if offline2DotChecker(forMiddle: aDot) {
                    offline2DotAppend(offline2DotData2, pointX: point_x_buff, pointY: point_y_buff, pointP: point_p_buff, timeDiff: time_diff_buff)
                    offline2DotData0 = offline2DotData1
                    offline2DotData1 = offline2DotData2
                }
                else {
                    print("offlineDotChecker error : middle2")
                }
            }
            else {
                offline2DotData1 = offline2DotData2
                print("offlineDotChecker error : start")
            }
            offline2DotData2 = aDot
            offlineDotCheckState = .NORMAL
        }
    }
    
    func offline2DotAppend(_ dot: OffLineData2DotStruct, pointX point_x_buff: Float, pointY point_y_buff: Float, pointP point_p_buff: Float, timeDiff time_diff_buff: Int) {
        var pressure: Float
        var x: Float
        var y: Float
        x = Float(dot.x) + Float(dot.fx) * 0.01
        y = Float(dot.y) + Float(dot.fy) * 0.01
        pressure = NJPenCommManager.sharedInstance().processPressure(Float(dot.force))
//        point_x_buff[point_index] = x - oPage.startX
//        point_y_buff[point_index] = y - oPage.startY
//        point_p_buff[point_index] = pressure
//        time_diff_buff[point_index] = dot.nTimeDelta
        point_index += 1
    }
    
    func offline2DotChecker(forStart aDot: OffLineData2DotStruct) -> Bool {
        let delta: Float = 2.0
        if offline2DotData1.x > 150 || offline2DotData1.x < 1 {
            return false
        }
        if offline2DotData1.y > 150 || offline2DotData1.y < 1 {
            return false
        }
//        if (aDot.x - offline2DotData1.x) * (offline2DotData2.x - offline2DotData1.x) > 0 && abs(aDot.x - offline2DotData1.x) > delta && abs(offline2DotData1.x - offline2DotData2.x) > delta {
//            return false
//        }
//        if (aDot.y - offline2DotData1.y) * (offline2DotData2.y - offline2DotData1.y) > 0 && abs(aDot.y - offline2DotData1.y) > delta && abs(offline2DotData1.y - offline2DotData2.y) > delta {
//            return false
//        }
        return true
    }
    
    func offline2DotChecker(forMiddle aDot: OffLineData2DotStruct) -> Bool {
        let delta: Float = 2.0
        if offline2DotData2.x > 150 || offline2DotData2.x < 1 {
            return false
        }
        if offline2DotData2.y > 150 || offline2DotData2.y < 1 {
            return false
        }
//        if (offline2DotData1.x - offline2DotData2.x) * (aDot.x - offline2DotData2.x) > 0 && abs(offline2DotData1.x - offline2DotData2.x) > delta && abs(aDot.x - offline2DotData2.x) > delta {
//            return false
//        }
//        if (offline2DotData1.y - offline2DotData2.y) * (aDot.y - offline2DotData2.y) > 0 && abs(offline2DotData1.y - offline2DotData2.y) > delta && abs(aDot.y - offline2DotData2.y) > delta {
//            return false
//        }
        return true
    }
    
    func offline2DotCheckerForEnd() -> Bool {
        let delta: Float = 2.0
        if offline2DotData2.x > 150 || offline2DotData2.x < 1 {
            return false
        }
        if offline2DotData2.y > 150 || offline2DotData2.y < 1 {
            return false
        }
//        if (offline2DotData2.x - offline2DotData0.x) * (offline2DotData2.x - offline2DotData1.x) > 0 && abs(offline2DotData2.x - offline2DotData0.x) > delta && abs(offline2DotData2.x - offline2DotData1.x) > delta {
//            return false
//        }
//        if (offline2DotData2.y - offline2DotData0.y) * (offline2DotData2.y - offline2DotData1.y) > 0 && abs(offline2DotData2.y - offline2DotData0.y) > delta && abs(offline2DotData2.y - offline2DotData1.y) > delta {
//            return false
//        }
        return true
    }
    
    
    func offline2DotCheckerLastPointX(_ point_x_buff: Float, pointY point_y_buff: Float, pointP point_p_buff: Float, timeDiff time_diff_buff: Int) {
        if offline2DotCheckerForEnd() {
            offline2DotAppend(offline2DotData2, pointX: point_x_buff, pointY: point_y_buff, pointP: point_p_buff, timeDiff: time_diff_buff)
            offline2DotData2.x = 0
            offline2DotData2.y = UInt16(0.0)
        }
        else {
            print("offlineDotChecker error : end")
        }
        offlineDotCheckState = .NONE
    }
    
    // MARK: - UITableViewDelegate
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let kOffSyncTableCell: String = "UITableViewCell"
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: kOffSyncTableCell)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: kOffSyncTableCell)
        }
        let noteId = CInt((menuList[indexPath.row] as? Int)!)
        cell?.textLabel?.text = noteTitle(Int(noteId))
        cell?.textLabel?.textColor = UIColor.white
        cell?.backgroundColor = UIColor.clear
        cell?.selectionStyle = .none
        cell?.textLabel?.isOpaque = false
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Click \(noteTitle(menuList[indexPath.row]))")
        requestOfflinedata(withOwnerId: ownerIdToRequest, noteId: UInt32(menuList[indexPath.row]))
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55.0
    }
    func noteTitle(_ type: Int) -> String {
        var notebookTitle: String
        switch type {
        case 601:
            notebookTitle = "Pocket Note"
        case 602:
            notebookTitle = "Memo Note"
        case 603:
            notebookTitle = "Spring Note"
        case 605:
            notebookTitle = "FP Memo Pad"
        default:
            notebookTitle = "Unknown Note"
        }
        
        return notebookTitle
    }
}
