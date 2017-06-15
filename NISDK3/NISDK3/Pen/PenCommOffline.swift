//
//  PenCommOffline.swift
//  NISDK3
//
//  Created by Aram Moon on 2017. 6. 12..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation

class PenCommOffline: NSObject {
    /*
    func parseOfflineFileListInfo(_ data: [UInt8], withLength length: Int) {
        let fileInfo: OfflineFileListInfoStruct? = (data as? OfflineFileListInfoStruct)
        N.Log("OfflineFileListInfo file Count \(UInt(fileInfo?.fileCount)), size \(UInt(fileInfo?.fileSize()))")
        offlineTotalDataSize = fileInfo?.fileSize()
        offlineTotalDataReceived = 0
        notifyOfflineDataStatus(OFFLINE_DATA_RECEIVE_START, percent: 0.0)
    }
    
    func parseOfflineFileInfoData(_ data: [UInt8], withLength length: Int) {
        let fileInfo: OFFLINE_FILE_INFO_DATA? = (data as? OFFLINE_FILE_INFO_DATA)
        if fileInfo?.type == 1 {
            N.Log("Offline File Info : Zip file")
        }
        else {
            N.Log("Offline File Info : Normal file")
        }
        let fileSize: UInt32? = fileInfo?.file_size
        offlinePacketCount = fileInfo?.packet_count
        offlinePacketSize = fileInfo?.packet_size
        offlineSliceCount = fileInfo?.slice_count
        offlineSliceSize = fileInfo?.slice_size
        offlineSliceIndex = 0
        N.Log("File size : \(UInt(fileSize)), packet count : \(offlinePacketCount), packet size : \(offlinePacketSize)")
        N.Log("Slice count : \(UInt(offlineSliceCount)), slice size : \(offlineSliceSize)")
        offlineLastPacketIndex = fileSize / offlinePacketSize
        let lastPacketSize: Int = fileSize % offlinePacketSize
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
        offlineData = Data(length: fileSize)
        offlinePacketData = nil
        offlineDataOffset = 0
        offlineDataSize = fileSize
        offlineFileAck(forType: 1, index: 0)
        // 1 : header, index 0
    }
    
    
    func parseOfflineFileData(_ data: [UInt8], withLength length: Int) {
        var expected_slice: Int = -1
        var slice_valid: Bool = true
        let fileData: OFFLINE_FILE_DATA? = (data as? OFFLINE_FILE_DATA)
        let index: Int? = fileData?.index
        let slice_index: Int? = fileData?.slice_index
        let dataReceived: UInt8? = (fileData?.data)
        if slice_index == 0 {
            expected_slice = -1
            slice_valid = true
            offlinePacketOffset = 0
            offlinePacketData = Data() /* capacity: offlinePacketSize */
        }
        var lengthToCopy: Int? = length - MemoryLayout<fileData?.index>.size - MemoryLayout<fileData?.slice_index>.size
        lengthToCopy = min(lengthToCopy, offlineSliceSize)
        if index == offlineLastPacketIndex && slice_index == offlineLastSliceIndex {
            lengthToCopy = offlineLastSliceSize
        }
        else if (offlinePacketOffset + lengthToCopy) > offlinePacketSize {
            lengthToCopy = offlinePacketSize - offlinePacketOffset
        }
        N.Log("Data index : \(index), slice index : \(slice_index), data size received: \(length) copied : \(lengthToCopy)")
        
        if slice_valid == false {
            return
        }
        expected_slice += 1
        if expected_slice != slice_index {
            N.Log("Bad slice index : expected \(expected_slice), received \(slice_index)")
            slice_valid = false
            return
            // Wait for next start
        }
        offlinePacketData.append(dataReceived, length: lengthToCopy)
        offlinePacketOffset += lengthToCopy
        if slice_index == (offlineSliceCount - 1) || (index == offlineLastPacketIndex && slice_index == offlineLastSliceIndex) {
            offlineFileAck(forType: 2, index: UInt8(index))
            // 2 : data
            let range: NSRange = [index * offlinePacketSize, offlinePacketOffset]
            offlineData.replaceBytes(in: range, withBytes: offlinePacketData.bytes)
            offlineDataOffset += offlinePacketOffset
            offlinePacketOffset = 0
            let percent = Float((offlineTotalDataReceived + offlineDataOffset) * 100.0) / Float(offlineTotalDataSize)
            notifyOfflineDataStatus(OFFLINE_DATA_RECEIVE_PROGRESSING, percent: percent)
            N.Log("offlineDataOffset=\(offlineDataOffset), offlineDataSize=\(offlineDataSize)")
        }
        if offlineDataOffset >= offlineDataSize {
            #if SPEED_TEST
                endTime4Speed = Date().timeIntervalSince1970
                let timeLapse: TimeInterval = endTime4Speed - startTime4Speed
                N.Log("Offline receiving speed \(length4Speed / timeLapse) bytes/sec")
            #endif
            let paths: [Any] = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            let documentDirectory: String = paths[0]
            let offlineFilePath: String = URL(fileURLWithPath: documentDirectory).appendingPathComponent("OfflineFile").absoluteString
            let url = URL(fileURLWithPath: offlineFilePath)
            let fm = FileManager.default
            var error: Error? = nil
            try? fm.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            let path: String = URL(fileURLWithPath: offlineFilePath).appendingPathComponent("offlineFile.zip").absoluteString
            fm.createFile(at: path, contents: offlineData, attributes: nil)
            //NISDK
            DispatchQueue.main.async(execute: {() -> Void in
                if !isEmpty(offlineDataDelegate) && offlineDotCheckState.responds(to: #selector(self.offlineDataPathBeforeParsed)) {
                    offlineDataDelegate.offlineDataPath(beforeParsed: path)
                }
            })
            let offlineZip = try? ZZArchive(url: URL(fileURLWithPath: path))
            let penDataEntry: ZZArchiveEntry? = offlineZip?.entries[0]
            if penDataEntry?.check(error) {
                // GOOD
                N.Log("Offline zip file received successfully")
                let penData = try? penDataEntry?.newData()
                if penData != nil {
                    offlineDataDelegate.parseOfflinePenData(penData)
                }
                offlineTotalDataReceived += offlineDataSize
            }
            else {
                // BAD
                N.Log("Offline zip file received badly")
            }
            offlinePacketOffset = 0
            offlinePacketData = nil
        }
    }
    func parseOfflineFileStatus(_ data: [UInt8], withLength length: Int) {
        let fileStatus: OfflineFileStatusStruct? = (data as? OfflineFileStatusStruct)
        if fileStatus?.status == 1 {
            N.Log("OfflineFileStatus success")
            didReceiveOfflineFile(forOwnerId: offlineOwnerIdRequested, noteId: offlineNoteIdRequested)
            notifyOfflineDataStatus(.offline_DATA_RECEIVE_END, percent: 100.0)
        }
        else {
            N.Log("OfflineFileStatus fail")
            notifyOfflineDataStatus(.offline_DATA_RECEIVE_FAIL, percent: 0.0)
        }
    }
}

func offlineDotAppend(_ dot: OffLineDataDotStruct, pointX point_x_buff: Float, pointY point_y_buff: Float, pointP point_p_buff: Float, timeDiff time_diff_buff: Int) {
    var pressure: Float
    var x: Float
    var y: Float
    x = Float(dot.x) + Float(dot.fx) * 0.01
    y = Float(dot.y) + Float(dot.fy) * 0.01
    pressure = processPressure(Float(dot.force))
    point_x_buff[point_index] = x - startX
    point_y_buff[point_index] = y - startY
    point_p_buff[point_index] = pressure
    time_diff_buff[point_index] = dot.nTimeDelta
    point_index += 1
}



func parseOfflinePenData_new(_ penData: Data) -> Bool {
    var dataPosition: Int = 0
    var dataLength: UInt = penData.count
    let headerSize: Int = MemoryLayout<OffLineDataFileHeaderStruct>.size
    dataLength -= headerSize
    let range: NSRange = [dataLength, headerSize]
    var header: OffLineDataFileHeaderStruct
    penData.getBytes(header, range: range)
    var strokes = [Any]()
    let offlineStrokes: [AnyHashable: Any] = [
        "note_id" : Int(header.nNoteId),
        "page_number" : Int(header.nPageId),
        "strokes" : strokes
    ]
    var char1: UInt8
    var char2: UInt8
    var strokeHeader: OffLineDataStrokeHeaderStruct
    while dataPosition < dataLength {
        if (dataLength - dataPosition) < (MemoryLayout<OffLineDataStrokeHeaderStruct>.size + 2) {
            break
        }
        range.location = dataPosition += 1
        range.length = 1
        penData.getBytes(char1, range: range)
        range.location = dataPosition += 1
        penData.getBytes(char2, range: range)
        if char1 == "L" && char2 == "N" {
            range.location = dataPosition
            range.length = MemoryLayout<OffLineDataStrokeHeaderStruct>.size
            penData.getBytes(strokeHeader, range: range)
            dataPosition += MemoryLayout<OffLineDataStrokeHeaderStruct>.size
            if (dataLength - dataPosition) < (strokeHeader.nDotCount * MemoryLayout<OffLineDataDotStruct>.size) {
                break
            }
            parseOfflineDots(penData, startAt: dataPosition, withFileHeader: header, andStrokeHeader: strokeHeader, toArray: strokes)
            dataPosition += (strokeHeader.nDotCount * MemoryLayout<OffLineDataDotStruct>.size)
        }
    }
    let semaphore = DispatchSemaphore(value: 0)
    DispatchQueue.main.async(execute: {() -> Void in
        N.Log("dispatch_async start")
        var noteIdBackup: UInt32 = 0
        var pageIdBackup: UInt32 = 0
        var hasPageBackup: Bool = false
        if strokeHandler {
            strokeHandler.notifyDataUpdating(true)
        }
        var value = (offlineStrokes["note_id"] as? NSNumber)
        let noteId = UInt32(CUnsignedInt(value))
        value = (offlineStrokes["page_number"] as? NSNumber)
        let pageId = UInt32(CUnsignedInt(value))
        if writerManager.activeNoteBookId != noteId || writerManager.activePageNumber != pageId {
            noteIdBackup = (UInt32)
            writerManager.activeNoteBookId
            pageIdBackup = (UInt32)
            writerManager.activePageNumber
            hasPageBackup = true
            N.Log("Offline New Id Data noteId \(UInt(noteId)), pageNumber \(UInt(pageId))")
            //Chage X, Y start cordinates.
            paperInfo.getPaperDotcodeStart(forNotebook: Int(noteId), startX: startX, startY: startY)
            writerManager.activeNotebookIdDidChange(noteId, withPageNumber: pageId)
        }
        let strokeSaved: [Any]? = (offlineStrokes["strokes"] as? [Any])
        for i in 0..<strokeSaved?.count {
            let a_stroke: NJStroke? = strokeSaved[i]
            activePageDocument.page.insertStroke(byTimestamp: a_stroke)
        }
        writerManager.saveCurrentPage(withEventlog: true, andEvernote: true, andLastStrokeTime: Date(timeIntervalSince1970: (offlineLastStrokeStartTime / 1000.0)))
        if hasPageBackup && noteIdBackup > 0 {
            paperInfo.getPaperDotcodeStart(forNotebook: Int(noteIdBackup), startX: startX, startY: startY)
            writerManager.activeNotebookIdDidChange(noteIdBackup, withPageNumber: pageIdBackup)
        }
        if strokeHandler {
            strokeHandler.notifyDataUpdating(false)
        }
        N.Log("dispatch_semaphore_signal")
        dispatch_semaphore_signal(semaphore)
    })
    N.Log("dispatch_semaphore_wait start")
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    N.Log("dispatch_semaphore_wait end")
    return true
}

func parseOfflineDots(_ penData: Data, startAt position: Int, withFileHeader pFileHeader: OffLineDataFileHeaderStruct, andStrokeHeader pStrokeHeader: OffLineDataStrokeHeaderStruct, toArray strokes: [Any]) {
    var dot: OffLineDataDotStruct
    var pressure: Float
    var x: Float
    var y: Float
    let range: NSRange = [position, MemoryLayout<OffLineDataDotStruct>.size]
    let dotCount: Int = min(MAX_NODE_NUMBER, pStrokeHeader.nDotCount)
    let point_x_buff: [Float] = malloc(MemoryLayout<Float>.size * dotCount)
    let point_y_buff: [Float] = malloc(MemoryLayout<Float>.size * dotCount)
    let point_p_buff: [Float] = malloc(MemoryLayout<Float>.size * dotCount)
    let time_diff_buff: Int? = malloc(MemoryLayout<Int>.size * dotCount)
    var point_index: Int = 0
    startTime = pStrokeHeader.nStrokeStartTime
    //    N.Log(@"offline time %llu", startTime);
    #if HAS_LINE_COLOR
        let color: UInt32 = pStrokeHeader.nLineColor
        if (color & 0x00ffffff) != 0x00ffffff && (color & 0x00ffffff) != 0x00000000 {
            offlinePenColor = color | 0xff000000
            // set Alpha to 255
        }
        else {
            offlinePenColor = 0
        }
    #else
        offlinePenColor = 0
    #endif
    offlinePenColor = penColor
    // 2015-01-28 add for maintaining color feature
    N.Log("offlinePenColor 0x\(UInt(offlinePenColor))")
    var paperStartX: Float
    var paperStartY: Float
    var paperSizeX: Float
    var paperSizeY: Float
    paperInfo.getPaperDotcodeStart(forNotebook: Int(pFileHeader.nNoteId), startX: paperStartX, startY: paperStartY)
    paperInfo.getPaperDotcodeRange(forNotebook: Int(pFileHeader.nNoteId), xmax: paperSizeX, ymax: paperSizeY)
    let normalizeScale: Float = max(paperSizeX, paperSizeY)
    for i in 0..<pStrokeHeader.nDotCount {
        penData.getBytes(dot, range: range)
        x = Float(dot.x) + Float(dot.fx) * 0.01
        y = Float(dot.y) + Float(dot.fy) * 0.01
        pressure = processPressure(Float(dot.force))
        point_x_buff[point_index] = x - paperStartX
        point_y_buff[point_index] = y - paperStartY
        point_p_buff[point_index] = pressure
        time_diff_buff[point_index] = dot.nTimeDelta
        point_index += 1
        //        N.Log(@"x %f, y %f, pressure %f, o_p %f", x, y, pressure, (float)dot.force);
        if point_index >= MAX_NODE_NUMBER {
            let stroke = NJStroke(rawDataX: point_x_buff, y: point_y_buff, pressure: point_p_buff, time_diff: time_diff_buff, penColor: offlinePenColor, penThickness: penThickness, startTime: startTime, size: point_index, normalizer: normalizeScale)
            strokes.append(stroke)
            point_index = 0
        }
        position += MemoryLayout<OffLineDataDotStruct>.size
        range.location = position
    }
    let stroke = NJStroke(rawDataX: point_x_buff, y: point_y_buff, pressure: point_p_buff, time_diff: time_diff_buff, penColor: offlinePenColor, penThickness: penThickness, startTime: startTime, size: point_index, normalizer: normalizeScale)
    strokes.append(stroke)
    free(point_x_buff)
    free(point_y_buff)
    free(point_p_buff)
    free(time_diff_buff)
}
 */
}


