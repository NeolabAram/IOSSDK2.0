//
//  SymbolChecker.swift
//  NISDK3
//
//  Created by Aram Moon on 2017. 6. 12..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation

enum PageArrayCommand : Int {
    case None = 0x00
    case Email = 0x01
    case Alarm = 0x02
    case Activity = 0x04
}

struct PageInfoType {
    var page_id: Int = 0
    var activeStartX: Float = 0.0
    var activeStartY: Float = 0.0
    var activeWidth: Float = 0.0
    var activeHeight: Float = 0.0
    var spanX: Float = 0.0
    var spanY: Float = 0.0
    var arrayX: Int = 0
    //email:action array, alarm: month start array
    var arrayY: Int = 0
    //email:action array, alarm: month start array
    var startDate: Int = 0
    var endDate: Int = 0
    var remainedDate: Int = 0
    var month: Int = 0
    var year: Int = 0
    var cmd = PageArrayCommand.None
}

/*
 func dotChecker(forOfflineSync aDot: OffLineDataDotStruct, pointX point_x_buff: Float, pointY point_y_buff: Float, pointP point_p_buff: Float, timeDiff time_diff_buff: Int) {
 if offlineDotCheckState == .NORMAL {
 if offlineDotChecker(forMiddle: aDot) {
 offlineDotAppend(offlineDotData2, pointX: point_x_buff, pointY: point_y_buff, pointP: point_p_buff, timeDiff: time_diff_buff)
 offlineDotData0 = offlineDotData1
 offlineDotData1 = offlineDotData2
 }
 else {
 N.Log("offlineDotChecker error : middle")
 }
 offlineDotData2 = aDot
 }
 else if offlineDotCheckState == .FIRST {
 offlineDotData0 = aDot
 offlineDotData1 = aDot
 offlineDotData2 = aDot
 offlineDotCheckState = .SECOND
 }
 else if offlineDotCheckState == .SECOND {
 offlineDotData2 = aDot
 offlineDotCheckState = .THIRD
 }
 else if offlineDotCheckState == .THIRD {
 if offlineDotChecker(forStart: aDot) {
 offlineDotAppend(offlineDotData1, pointX: point_x_buff, pointY: point_y_buff, pointP: point_p_buff, timeDiff: time_diff_buff)
 if offlineDotChecker(forMiddle: aDot) {
 offlineDotAppend(offlineDotData2, pointX: point_x_buff, pointY: point_y_buff, pointP: point_p_buff, timeDiff: time_diff_buff)
 offlineDotData0 = offlineDotData1
 offlineDotData1 = offlineDotData2
 }
 else {
 N.Log("offlineDotChecker error : middle2")
 }
 }
 else {
 offlineDotData1 = offlineDotData2
 N.Log("offlineDotChecker error : start")
 }
 offlineDotData2 = aDot
 offlineDotCheckState = OFFLINE_DOT_CHECK_NORMAL
 }
 
 //MARK: - Page data
 func getDotScale() -> Float {
 if mDotToScreenScale == 0 {
 return 1
 }
 return mDotToScreenScale
 }
 func calcDotScaleScreenW(_ screenW: Float, screenH: Float) {
 let dotWidth: Float = 600
 let dotHeight: Float = 900
 let widthScale: Float = screenW / dotWidth
 let heightScale: Float = screenH / dotHeight
 let dotToScreenScale: Float = widthScale > heightScale ? heightScale : widthScale
 mDotToScreenScale = dotToScreenScale
 }
 
 func pageInfoArrayInitNoteId(_ noteId: UInt32, andPageNumber pageNumber: UInt32) {
 var startPageNumber: Int = 1
 let index: Int = 0
 let notebookInfo = NJNotebookPaperInfo.sharedInstance()
 let tempInfo: [AnyHashable: Any]? = (notebookInfo.notebookPuiInfo[Int(noteId)] as? [AnyHashable: Any])
 let tempPageInfo: PageInfoType? = (tempInfo?["page_info"] as? PageInfoType)?.pointer()
 startPageNumber = notebookInfo.getPaperStartPageNumber(forNotebook: noteId)
 let keysArray: [Any] = notebookInfo.notebookPuiInfo.keys
 let count = Int(keysArray.count)
 for noteIdInfo: NSNumber in keysArray {
 //N.Log(@"NoteIdInfo : %@", noteIdInfo);
 if noteId == UInt32(CUnsignedInt(noteIdInfo)) {
 break
 }
 index += 1
 }
 if index == count {
 N.Log("noteId isn't included to pui info")
 currentPageInfo = nil
 return
 }
 if (tempPageInfo == nil) || (noteId == 605) {
 N.Log("tempPageInfo == NULL or active Note Id == 605")
 currentPageInfo = nil
 return
 }
 if (noteId == 601) || (noteId == 602) || (noteId == 2) || (noteId == 604) || (noteId == 609) || (noteId == 610) || (noteId == 611) || (noteId == 612) || (noteId == 613) || (noteId == 614) || (noteId == 617) || (noteId == 618) || (noteId == 619) || (noteId == 620) || (noteId == 114) || (noteId == 700) || (noteId == 701) || (noteId == 702) {
 if pageNumber >= startPageNumber {
 currentPageInfo = tempPageInfo[0]
 }
 }
 else if (noteId == 615) || (noteId == 616) {
 if pageNumber >= startPageNumber {
 currentPageInfo = tempPageInfo[0]
 }
 }
 else if noteId == 603 {
 if pageNumber >= startPageNumber {
 if (pageNumber % 2) == 1 {
 currentPageInfo = tempPageInfo[0]
 }
 else if (pageNumber % 2) == 0 {
 currentPageInfo = tempPageInfo[1]
 }
 }
 }
 else {
 if pageNumber >= startPageNumber {
 currentPageInfo = tempPageInfo[0]
 }
 }
 if currentPageInfo == nil {
 N.Log("2. _currentPageInfo == NULL")
 return
 }
 //N.Log(@"pageArrayInit _currentPageInfo:%@", self.currentPageInfo);
 let rowSize: Int = (currentPageInfo.activeHeight) / (currentPageInfo.spanY)
 let colSize: Int = (currentPageInfo.activeWidth) / (currentPageInfo.spanX)
 dataRowArray = [Any]() /* capacity: rowSize */
 for i in 0..<rowSize {
 var dataColArray = [Any]() /* capacity: colSize */
 for j in 0..<colSize {
 if currentPageInfo.cmd == Email {
 dataColArray[j] = Int(0)
 if (i == currentPageInfo.arrayY) && (j == currentPageInfo.arrayX) {
 dataColArray[j] = Int(Email)
 }
 }
 }
 dataRowArray.insert(dataColArray, at: i)
 }
 sendOneTime = true
 alarmOneTime = true
 }
 
 func checkXcoord(_ x: Float, ycoord y: Float) {
 if currentPageInfo == nil {
 //N.Log(@"3. _currentPageInfo == NULL");
 return
 }
 if (x < currentPageInfo.activeStartX) || (x > (currentPageInfo.activeStartX + currentPageInfo.activeWidth)) || (y < currentPageInfo.activeStartY) || (y > (currentPageInfo.activeStartY + currentPageInfo.activeHeight)) {
 //N.Log(@"out of active paper area");
 return
 }
 let arrayY: Int = (y - currentPageInfo.activeStartY) / (currentPageInfo.spanY)
 let arrayX: Int = (x - currentPageInfo.activeStartX) / (currentPageInfo.spanX)
 //N.Log(@"arrayX: %d, arrayY: %d",arrayX, arrayY);
 if arrayY >= dataRowArray.count {
 //N.Log(@"arrayY is beyond array count");
 return
 }
 var subArray: [Any]? = (dataRowArray[arrayY] as? [Any])
 if arrayX >= subArray?.count {
 //N.Log(@"arrayX is beyond array count");
 return
 }
 if currentPageInfo.cmd == Email {
 //N.Log(@"Email command, before sendOneTime");
 if CInt(subArray[arrayX]) == Email {
 if sendOneTime {
 N.Log("Email command, sendOneTime YES")
 //delegate
 if commandHandler != nil {
 DispatchQueue.main.async(execute: {() -> Void in
 commandHandler.sendEmailWithPdf()
 })
 }
 sendOneTime = false
 }
 }
 }
 }
 
 func checkPUICoordX(_ x: Float, coordY y: Float) {
 if isEmpty(paperInfo) {
 return
 }
 var found: Bool = false
 var cmdType: PUICmdType = PUICmdTypeNone
 let pui: PUIInfo?
 paperInfo.puiArray
 do {
 var padding: CGFloat = 0.0
 if (pui?.width > 5.0) && (pui?.height > 5.0) {
 padding = min(pui?.width, pui?.height) * 0.1
 }
 if x < (pui?.startX + padding) {
 continue
 }
 if y < (pui?.startY + padding) {
 continue
 }
 if x > (pui?.startX + pui?.width - padding) {
 continue
 }
 if y > (pui?.startY + pui?.height - padding) {
 continue
 }
 found = true
 cmdType = pui?.cmdType
 break
 }
 if cmdType == PUICmdTypeNone {
 return
 }
 //    N.Log(@"PUI Command Type ---> %tu",cmdType);
 if commandHandler != nil {
 DispatchQueue.main.async(execute: {() -> Void in
 if cmdType == PUICmdTypeEmail {
 commandHandler.sendEmailWithPdf()
 }
 commandHandler.findApplicableSymbols(pui?.param, action: pui?.action, andName: pui?.name)
 })
 }
 }
 
func offlineDotChecker(forStart aDot: OffLineDataDotStruct) -> Bool {
    let delta: Float = 2.0
    if offlineDotData1.x > 150 || offlineDotData1.x < 1 {
        return false
    }
    if offlineDotData1.y > 150 || offlineDotData1.y < 1 {
        return false
    }
    if (aDot.x - offlineDotData1.x) * (offlineDotData2.x - offlineDotData1.x) > 0 && abs(aDot.x - offlineDotData1.x) > delta && abs(offlineDotData1.x - offlineDotData2.x) > delta {
        return false
    }
    if (aDot.y - offlineDotData1.y) * (offlineDotData2.y - offlineDotData1.y) > 0 && abs(aDot.y - offlineDotData1.y) > delta && abs(offlineDotData1.y - offlineDotData2.y) > delta {
        return false
    }
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
    if (offlineDotData1.x - offlineDotData2.x) * (aDot.x - offlineDotData2.x) > 0 && abs(offlineDotData1.x - offlineDotData2.x) > delta && abs(aDot.x - offlineDotData2.x) > delta {
        return false
    }
    if (offlineDotData1.y - offlineDotData2.y) * (aDot.y - offlineDotData2.y) > 0 && abs(offlineDotData1.y - offlineDotData2.y) > delta && abs(aDot.y - offlineDotData2.y) > delta {
        return false
    }
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
    if (offlineDotData2.x - offlineDotData0.x) * (offlineDotData2.x - offlineDotData1.x) > 0 && abs(offlineDotData2.x - offlineDotData0.x) > delta && abs(offlineDotData2.x - offlineDotData1.x) > delta {
        return false
    }
    if (offlineDotData2.y - offlineDotData0.y) * (offlineDotData2.y - offlineDotData1.y) > 0 && abs(offlineDotData2.y - offlineDotData0.y) > delta && abs(offlineDotData2.y - offlineDotData1.y) > delta {
        return false
    }
    return true
}
func offlineDotCheckerLastPointX(_ point_x_buff: Float, pointY point_y_buff: Float, pointP point_p_buff: Float, timeDiff time_diff_buff: Int) {
    if offlineDotCheckerForEnd() {
        offlineDotAppend(offlineDotData2, pointX: point_x_buff, pointY: point_y_buff, pointP: point_p_buff, timeDiff: time_diff_buff)
        offlineDotData2.x = UInt16(0.0)
        offlineDotData2.y = 0.0
    }
    else {
        N.Log("offlineDotChecker error : end")
    }
    offlineDotCheckState = OFFLINE_DOT_CHECK_NONE
}


//////////////////////////////////////////////////////////////////
//
//
//            Online Dot Checker
//
//////////////////////////////////////////////////////////////////
//SDK1.0
func dotcode2PixelX(_ dot: Int, y fdot: Int) -> Float {
    let doScale: Float = getDotScale()
    return (dot * doScale + Float(fdot * doScale * 0.01))
}
func dotChecker(_ aDot: DotDataStruct) {
    if dotCheckState == DOT_CHECK_NORMAL {
        if dotChecker(forMiddle: aDot) {
            dotAppend(dotData2)
            dotData0 = dotData1
            dotData1 = dotData2
        }
        else {
            N.Log("dotChecker error : middle")
        }
        dotData2 = aDot
    }
    else if dotCheckState == DOT_CHECK_FIRST {
        dotData0 = aDot
        dotData1 = aDot
        dotData2 = aDot
        dotCheckState = DOT_CHECK_SECOND
    }
    else if dotCheckState == DOT_CHECK_SECOND {
        dotData2 = aDot
        dotCheckState = DOT_CHECK_THIRD
    }
    else if dotCheckState == DOT_CHECK_THIRD {
        if dotChecker(forStart: aDot) {
            dotAppend(dotData1)
            if dotChecker(forMiddle: aDot) {
                dotAppend(dotData2)
                dotData0 = dotData1
                dotData1 = dotData2
            }
            else {
                N.Log("dotChecker error : middle2")
            }
        }
        else {
            dotData1 = dotData2
            N.Log("dotChecker error : start")
        }
        dotData2 = aDot
        dotCheckState = DOT_CHECK_NORMAL
    }
}
func dotCheckerLast() {
    if dotCheckerForEnd() {
        dotAppend(dotData2)
        dotData2.x = 0.0
        dotData2.y = 0.0
    }
    else {
        N.Log("dotChecker error : end")
    }
}
func dotChecker(forStart aDot: dotDataStruct) -> Bool {
    let delta: Float = 10.0
    if dotData1.x > 150 || dotData1.x < 1 {
        return false
    }
    if dotData1.y > 150 || dotData1.y < 1 {
        return false
    }
    if (aDot.x - dotData1.x) * (dotData2.x - dotData1.x) > 0 && abs(aDot.x - dotData1.x) > delta && abs(dotData1.x - dotData2.x) > delta {
        return false
    }
    if (aDot.y - dotData1.y) * (dotData2.y - dotData1.y) > 0 && abs(aDot.y - dotData1.y) > delta && abs(dotData1.y - dotData2.y) > delta {
        return false
    }
    return true
}
func dotChecker(forMiddle aDot: dotDataStruct) -> Bool {
    let delta: Float = 10.0
    if dotData2.x > 150 || dotData2.x < 1 {
        return false
    }
    if dotData2.y > 150 || dotData2.y < 1 {
        return false
    }
    if (dotData1.x - dotData2.x) * (aDot.x - dotData2.x) > 0 && abs(dotData1.x - dotData2.x) > delta && abs(aDot.x - dotData2.x) > delta {
        return false
    }
    if (dotData1.y - dotData2.y) * (aDot.y - dotData2.y) > 0 && abs(dotData1.y - dotData2.y) > delta && abs(aDot.y - dotData2.y) > delta {
        return false
    }
    return true
}
func dotCheckerForEnd() -> Bool {
    let delta: Float = 10.0
    if dotData2.x > 150 || dotData2.x < 1 {
        return false
    }
    if dotData2.y > 150 || dotData2.y < 1 {
        return false
    }
    if (dotData2.x - dotData0.x) * (dotData2.x - dotData1.x) > 0 && abs(dotData2.x - dotData0.x) > delta && abs(dotData2.x - dotData1.x) > delta {
        return false
    }
    if (dotData2.y - dotData0.y) * (dotData2.y - dotData1.y) > 0 && abs(dotData2.y - dotData0.y) > delta && abs(dotData2.y - dotData1.y) > delta {
        return false
    }
    return true
}

func dotAppend(_ aDot: DotDataStruct) {
    let pressure: Float = processPressure(aDot.pressure)
    point_x[point_count] = aDot.x
    point_y[point_count] = aDot.y
    point_p[point_count] = pressure
    time_diff[point_count] = aDot.diff_time
    point_count += 1
    node_count += 1
    //    N.Log(@"time %d, x %f, y %f, pressure %f", aDot->diff_time, aDot->x, aDot->y, pressure);
    if point_count >= MAX_NODE_NUMBER {
        // call _penDown setter
        penDown = false
        penDown = true
    }
    let node = NJNode(pointX: aDot.x, poinY: aDot.y, pressure: pressure)
    //requested
    node.timeDiff = aDot.diff_time
    let new_node: [AnyHashable: Any] = [
        "type" : "stroke",
        "node" : node
    ]
    if strokeHandler != nil {
        DispatchQueue.main.async(execute: {() -> Void in
            strokeHandler.processStroke(new_node)
        })
    }
}


//////////////////////////////////////////////////////////////////
//
//
//            Online Dot Checker
//
//////////////////////////////////////////////////////////////////
//SDK2.0
func dotChecker(forOfflineSync2 aDot: OffLineData2DotStruct, pointX point_x_buff: Float, pointY point_y_buff: Float, pointP point_p_buff: Float, timeDiff time_diff_buff: Int) {
    if offlineDotCheckState == OFFLINE_DOT_CHECK_NORMAL {
        if offline2DotChecker(forMiddle: aDot) {
            offline2DotAppend(offline2DotData2, pointX: point_x_buff, pointY: point_y_buff, pointP: point_p_buff, timeDiff: time_diff_buff)
            offline2DotData0 = offline2DotData1
            offline2DotData1 = offline2DotData2
        }
        else {
            N.Log("offlineDotChecker error : middle")
        }
        offline2DotData2 = aDot
    }
    else if offlineDotCheckState == OFFLINE_DOT_CHECK_FIRST {
        offline2DotData0 = aDot
        offline2DotData1 = aDot
        offline2DotData2 = aDot
        offlineDotCheckState = OFFLINE_DOT_CHECK_SECOND
    }
    else if offlineDotCheckState == OFFLINE_DOT_CHECK_SECOND {
        offline2DotData2 = aDot
        offlineDotCheckState = OFFLINE_DOT_CHECK_THIRD
    }
    else if offlineDotCheckState == OFFLINE_DOT_CHECK_THIRD {
        if offline2DotChecker(forStart: aDot) {
            offline2DotAppend(offline2DotData1, pointX: point_x_buff, pointY: point_y_buff, pointP: point_p_buff, timeDiff: time_diff_buff)
            if offline2DotChecker(forMiddle: aDot) {
                offline2DotAppend(offline2DotData2, pointX: point_x_buff, pointY: point_y_buff, pointP: point_p_buff, timeDiff: time_diff_buff)
                offline2DotData0 = offline2DotData1
                offline2DotData1 = offline2DotData2
            }
            else {
                N.Log("offlineDotChecker error : middle2")
            }
        }
        else {
            offline2DotData1 = offline2DotData2
            N.Log("offlineDotChecker error : start")
        }
        offline2DotData2 = aDot
        offlineDotCheckState = OFFLINE_DOT_CHECK_NORMAL
    }
}
func offline2DotAppend(_ dot: OffLineData2DotStruct, pointX point_x_buff: Float, pointY point_y_buff: Float, pointP point_p_buff: Float, timeDiff time_diff_buff: Int) {
    var pressure: Float
    var x: Float
    var y: Float
    x = Float(dot.x) + Float(dot.fx) * 0.01
    y = Float(dot.y) + Float(dot.fy) * 0.01
    pressure = processPressure(Float(dot.force))
    point_x_buff[point_index] = x
    point_y_buff[point_index] = y
    point_p_buff[point_index] = pressure
    time_diff_buff[point_index] = dot.nTimeDelta
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
    if (aDot.x - offline2DotData1.x) * (offline2DotData2.x - offline2DotData1.x) > 0 && abs(aDot.x - offline2DotData1.x) > delta && abs(offline2DotData1.x - offline2DotData2.x) > delta {
        return false
    }
    if (aDot.y - offline2DotData1.y) * (offline2DotData2.y - offline2DotData1.y) > 0 && abs(aDot.y - offline2DotData1.y) > delta && abs(offline2DotData1.y - offline2DotData2.y) > delta {
        return false
    }
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
    if (offline2DotData1.x - offline2DotData2.x) * (aDot.x - offline2DotData2.x) > 0 && abs(offline2DotData1.x - offline2DotData2.x) > delta && abs(aDot.x - offline2DotData2.x) > delta {
        return false
    }
    if (offline2DotData1.y - offline2DotData2.y) * (aDot.y - offline2DotData2.y) > 0 && abs(offline2DotData1.y - offline2DotData2.y) > delta && abs(aDot.y - offline2DotData2.y) > delta {
        return false
    }
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
    if (offline2DotData2.x - offline2DotData0.x) * (offline2DotData2.x - offline2DotData1.x) > 0 && abs(offline2DotData2.x - offline2DotData0.x) > delta && abs(offline2DotData2.x - offline2DotData1.x) > delta {
        return false
    }
    if (offline2DotData2.y - offline2DotData0.y) * (offline2DotData2.y - offline2DotData1.y) > 0 && abs(offline2DotData2.y - offline2DotData0.y) > delta && abs(offline2DotData2.y - offline2DotData1.y) > delta {
        return false
    }
    return true
}
func offline2DotCheckerLastPointX(_ point_x_buff: Float, pointY point_y_buff: Float, pointP point_p_buff: Float, timeDiff time_diff_buff: Int) {
    if offline2DotCheckerForEnd() {
        offline2DotAppend(offline2DotData2, pointX: point_x_buff, pointY: point_y_buff, pointP: point_p_buff, timeDiff: time_diff_buff)
        offline2DotData2.x = 0.0
        offline2DotData2.y = 0.0
    }
    else {
        N.Log("offlineDotChecker error : end")
    }
    offlineDotCheckState = OFFLINE_DOT_CHECK_NONE
}
 */
