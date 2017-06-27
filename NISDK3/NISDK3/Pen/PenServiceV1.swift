//
//  PenServiceV1.swift
//  NISDK3
//
//  Created by Aram Moon on 2017. 6. 21..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation
import CoreBluetooth

/// This is for Protocol Ver1
extension PenController{
    
    func initCharacteristics(){
        penCharacteristics = [Pen.STROKE_DATA_UUID, Pen.UPDOWN_DATA_UUID, Pen.ID_DATA_UUID]
        offlineCharacteristics = [Pen.REQUEST_OFFLINE_FILE_LIST_UUID, Pen.OFFLINE_FILE_LIST_UUID, Pen.REQUEST_DEL_OFFLINE_FILE_UUID]
        offline2Characteristics = [Pen.OFFLINE2_FILE_INFO_UUID, Pen.OFFLINE2_FILE_DATA_UUID,Pen.OFFLINE2_FILE_LIST_INFO_UUID, Pen.REQUEST_OFFLINE2_FILE_UUID, Pen.OFFLINE2_FILE_STATUS_UUID, Pen.OFFLINE2_FILE_ACK_UUID]
        updateCharacteristics = [Pen.UPDATE_FILE_INFO_UUID, Pen.REQUEST_UPDATE_FILE_UUID,Pen.UPDATE_FILE_DATA_UUID, Pen.UPDATE_FILE_STATUS_UUID]
        systemCharacteristics = [Pen.PEN_STATE_UUID,Pen.SET_PEN_STATE_UUID,Pen.SET_NOTE_ID_LIST_UUID,Pen.READY_EXCHANGE_DATA_UUID,Pen.READY_EXCHANGE_DATA_REQUEST_UUID]
        system2Characteristics = [Pen.PEN_PASSWORD_REQUEST_UUID,Pen.PEN_PASSWORD_RESPONSE_UUID,Pen.PEN_PASSWORD_CHANGE_REQUEST_UUID, Pen.PEN_PASSWORD_CHANGE_RESPONSE_UUID]
        supportedServices = [Pen2.NEO_PEN2_SERVICE_UUID,Pen2.NEO_PEN2_SYSTEM_SERVICE_UUID,Pen.NEO_PEN_SERVICE_UUID,Pen.NEO_SYSTEM_SERVICE_UUID,Pen.NEO_OFFLINE_SERVICE_UUID,Pen.NEO_OFFLINE2_SERVICE_UUID,Pen.NEO_UPDATE_SERVICE_UUID,Pen.NEO_DEVICE_INFO_SERVICE_UUID,Pen.NEO_SYSTEM2_SERVICE_UUID]
    }
    
    //MARK: - Receive Data Ver1
    func receiveDataV1(_ uuid: CBUUID, _ packet : [UInt8]){
        if uuid.isEqual(Pen.STROKE_DATA_UUID) {
            penCommParser.parsePenStrokeData(packet)
        }
        else if uuid.isEqual(Pen.UPDOWN_DATA_UUID) {
            N.Log("Received: updown")
            penCommParser.parsePenUpDowneData(packet)
        }
        else if uuid.isEqual(Pen.ID_DATA_UUID) {
            N.Log("Received: id data")
            penCommParser.parsePenNewIdData(packet)
        }
        else if uuid.isEqual(Pen.OFFLINE_FILE_LIST_UUID) {
            N.Log("Received: offline file data");
            penCommParser.parseOfflineFileList(packet)
        }
        else if uuid.isEqual(Pen.OFFLINE2_FILE_LIST_INFO_UUID) {
            N.Log("Received: offline file info data")
            penCommParser.parseOfflineFileInfoData(packet)
        }
        else if uuid.isEqual(Pen.PEN_STATE_UUID) {
            N.Log("Received: pen status data")
            penConnectionStatusMsg = NSLocalizedString("BT_PEN_CONNECTED", comment: "")
            penConnectionStatus = .Connect
            penCommParser.parsePenStatusData(packet)
        }
        else if uuid.isEqual(Pen.OFFLINE_FILE_LIST_UUID) {
            N.Log("Received: offline File list")
            penCommParser.parseOfflineFileList(packet)
        }
        else if uuid.isEqual(Pen.OFFLINE2_FILE_LIST_INFO_UUID) {
            N.Log("Received: offline File List info")
            penCommParser.parseOfflineFileListInfo(packet)
        }
        else if uuid.isEqual(Pen.OFFLINE2_FILE_STATUS_UUID) {
            N.Log("Received: offline File Status")
            penCommParser.parseOfflineFileStatus(packet)
        }
        else if uuid.isEqual(Pen.REQUEST_UPDATE_FILE_UUID) {
            N.Log("Received: request update file")
            penCommParser.parseRequestUpdateFile(packet)
        }
        else if uuid.isEqual(Pen.UPDATE_FILE_STATUS_UUID) {
            N.Log("Received: update file status ")
            penCommParser.parseUpdateFileStatus(packet)
        }
        else if uuid.isEqual(Pen.READY_EXCHANGE_DATA_REQUEST_UUID) {
            N.Log("Received: readyExchangeDataRequestUuid")
            penCommParser.parseReadyExchangeDataRequest(packet)
        }
        else if uuid.isEqual(Pen.PEN_PASSWORD_REQUEST_UUID) {
            N.Log("Received: penPasswordRequestUuid")
            penCommParser.parsePenPasswordRequest(packet)
        }
        else if uuid.isEqual(Pen.PEN_PASSWORD_CHANGE_RESPONSE_UUID) {
            N.Log("Received: penPasswordResponseUuid")
            penCommParser.parsePenPasswordChangeResponse(packet)
        }
        else if uuid.isEqual(Pen.FW_VERSION_UUID) {
            N.Log("Received: FW version")
            penCommParser.parseFWVersion(packet)
        }
        else {
            N.Log("Un-handled data characteristic.UUID \(uuid.uuidString)")
            return
        }
    }
    
    //MARK: - subscribe Pen Ver1
    func subscribeCharacteristicV1(_ characteristic: CBCharacteristic){
        if characteristic == setPenStateCharacteristic {
            N.Log("Set Pen Status successful")
        }
        else if characteristic == requestOfflineFileListCharacteristic {
            N.Log("requestOfflineFileList successful")
        }
        else if characteristic == sendUpdateFileInfoCharacteristic {
            N.Log("sendUpdateFileInfoCharacteristic successful")
        }
        else if characteristic == updateFileDataCharacteristic {
            N.Log("updateFileDataCharacteristic successful")
        }
        else if characteristic == offline2FileAckCharacteristic {
            N.Log("offline2FileAckCharacteristic successful")
        }
        else if characteristic == setNoteIdListCharacteristic {
            N.Log("setNoteIdListCharacteristic successful")
        }
        else if characteristic == requestOfflineFileCharacteristic {
            N.Log("requestOfflineFileCharacteristic successful")
        }
        else if characteristic == requestDelOfflineFileCharacteristic {
            N.Log("requestDelOfflineFileCharacteristic successful")
        }
        else {
            N.Log("Unknown characteristic \(characteristic.uuid) didWriteValueForCharacteristic successful")
        }

    }
    
    //MARK: - Write to Pen Ver1
    func write(_ data: Data, to characteristic: CBCharacteristic) {
        bt_write_dispatch_queue.async(execute: {() -> Void in
            self.nPen?.peripheral.writeValue(data, for: characteristic, type: .withResponse)
        })
    }
    func writeSetPenState(_ data: Data) {
        bt_write_dispatch_queue.async(execute: {() -> Void in
            N.Log("gethere 3")
            self.nPen?.peripheral.writeValue(data, for: self.setPenStateCharacteristic!, type: .withResponse)
        })
    }
    func writeNoteIdList(_ data: Data) {
        bt_write_dispatch_queue.async(execute: {() -> Void in
            self.nPen?.peripheral.writeValue(data, for: self.setNoteIdListCharacteristic!, type: .withResponse)
        })
    }
    func writeReadyExchangeData(_ data: Data) {
        bt_write_dispatch_queue.async(execute: {() -> Void in
            if self.readyExchangeDataCharacteristic != nil {
                self.nPen?.peripheral.writeValue(data, for: self.readyExchangeDataCharacteristic!, type: .withResponse)
            }
        })
    }
    func writePenPasswordResponseData(_ data: Data) {
        bt_write_dispatch_queue.async(execute: {() -> Void in
            if self.penPasswordResponseCharacteristic != nil {
                N.Log("[PenCommMan -writePenPasswordResponseData] writing data to pen")
                self.nPen?.peripheral.writeValue(data, for: self.penPasswordResponseCharacteristic!, type: .withResponse)
            }
        })
    }
    func writeSetPasswordData(_ data: Data) {
        bt_write_dispatch_queue.async(execute: {() -> Void in
            if self.penPasswordChangeRequestCharacteristic != nil {
                self.nPen?.peripheral.writeValue(data, for: self.penPasswordChangeRequestCharacteristic!, type: .withResponse)
            }
        })
    }
    func writeRequestOfflineFileList(_ data: Data) {
        bt_write_dispatch_queue.async(execute: {() -> Void in
            self.nPen?.peripheral.writeValue(data, for: self.requestOfflineFileListCharacteristic!, type: .withResponse)
        })
    }
    func writeRequestDelOfflineFile(_ data: Data) {
        bt_write_dispatch_queue.async(execute: {() -> Void in
            self.nPen?.peripheral.writeValue(data, for: self.requestDelOfflineFileCharacteristic!, type: .withResponse)
        })
    }
    func writeRequestOfflineFile(_ data: Data) {
        bt_write_dispatch_queue.async(execute: {() -> Void in
            self.nPen?.peripheral.writeValue(data, for: self.requestOfflineFileCharacteristic!, type: .withResponse)
        })
    }
    func writeOfflineFileAck(_ data: Data) {
        bt_write_dispatch_queue.async(execute: {() -> Void in
            self.nPen?.peripheral.writeValue(data, for: self.offline2FileAckCharacteristic!, type: .withResponse)
        })
    }
    func writeUpdateFileData(_ data: Data) {
        bt_write_dispatch_queue.async(execute: {() -> Void in
            self.nPen?.peripheral.writeValue(data, for: self.updateFileDataCharacteristic!, type: .withResponse)
        })
    }
    func writeUpdateFileInfo(_ data: Data) {
        bt_write_dispatch_queue.async(execute: {() -> Void in
            self.nPen?.peripheral.writeValue(data, for: self.sendUpdateFileInfoCharacteristic!, type: .withResponse)
        })
    }
    
    //MARK: Protocol V1 Only
    
    
}
