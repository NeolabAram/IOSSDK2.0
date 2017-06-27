//
//  Config.swift
//  NISDK3
//
//  Created by Aram Moon on 2017. 6. 7..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation
import CoreBluetooth

let kNOTEBOOK_ID_DIGITAL = 0
let kNOTEBOOK_ID_START_DIGITAL = 900
let kNOTEBOOK_ID_START_REAL = 0o00
let STROKE_NUMBER_MAGNITUDE = 4

    // event log types
enum kEVENT_LOGTYPE : Int {
    case logtype_LASTSTROKE
    case logtype_WEATHER
    case logtype_SYNC
    case logtype_SHARE
    case logtype_CREATE
    case logtype_COPY
    case logtype_DELETE
}
    // event action modes
enum kEVENT_ACTIONMODE : Int {
    case actionmode_REALTIME
    case actionmode_OFFLINE
    case actionmode_OPERATION
}

// Protocol V1
struct Pen{
    ///18F1
    static let NEO_PEN_SERVICE_UUID = CBUUID(string :"18F1")
    ///2AA0
    static let STROKE_DATA_UUID = CBUUID(string :"2AA0")
    ///2AA1
    static let ID_DATA_UUID = CBUUID(string :"2AA1")
    ///2AA2
    static let UPDOWN_DATA_UUID = CBUUID(string :"2AA2")
    ///2AB1
    static let SET_RTC_UUID = CBUUID(string :"2AB1")
    
    /* OFFLINE Data Service UUID
     */
    ///18F2
    static let NEO_OFFLINE_SERVICE_UUID = CBUUID(string :"18F2")
    ///2AC1
    static let REQUEST_OFFLINE_FILE_LIST_UUID = CBUUID(string :"2AC1")
    
    ///2AC2
    static let OFFLINE_FILE_LIST_UUID = CBUUID(string :"2AC2")
    ///2AC3
    static let REQUEST_DEL_OFFLINE_FILE_UUID = CBUUID(string :"2AC3")
    
    /* OFFLINE2 Data Service UUID
     */
    ///18F3
    static let NEO_OFFLINE2_SERVICE_UUID = CBUUID(string :"18F3")
    ///2AC7
    static let REQUEST_OFFLINE2_FILE_UUID = CBUUID(string :"2AC7")
    ///18F2
    static let OFFLINE2_FILE_LIST_INFO_UUID = CBUUID(string :"2AC8")
    ///2AC9
    static let OFFLINE2_FILE_INFO_UUID = CBUUID(string :"2AC9")
    ///2ACA
    static let OFFLINE2_FILE_DATA_UUID = CBUUID(string :"2ACA")
    ///2ACB
    static let OFFLINE2_FILE_ACK_UUID = CBUUID(string :"2ACB")
    ///2ACC
    static let OFFLINE2_FILE_STATUS_UUID = CBUUID(string :"2ACC")
    
    
    /* Update Service UUID
     */
    ///18F4
    static let NEO_UPDATE_SERVICE_UUID = CBUUID(string :"18F4")
    ///2AD1
    static let UPDATE_FILE_INFO_UUID = CBUUID(string :"2AD1")
    ///2AD2
    static let REQUEST_UPDATE_FILE_UUID = CBUUID(string :"2AD2")
    ///2AD3
    static let UPDATE_FILE_DATA_UUID = CBUUID(string :"2AD3")
    ///2AD4
    static let UPDATE_FILE_STATUS_UUID = CBUUID(string :"2AD4")
    
    /* System Service UUID
     */
    ///18F5
    static let NEO_SYSTEM_SERVICE_UUID = CBUUID(string :"18F5")
    ///2AB0
    static let PEN_STATE_UUID = CBUUID(string :"2AB0")
    ///2AB1
    static let SET_PEN_STATE_UUID = CBUUID(string :"2AB1")
    ///2AB2
    static let SET_NOTE_ID_LIST_UUID = CBUUID(string :"2AB2")
    ///2AB4
    static let READY_EXCHANGE_DATA_UUID = CBUUID(string :"2AB4")
    ///2AB5
    static let READY_EXCHANGE_DATA_REQUEST_UUID = CBUUID(string :"2AB5")
    
    /* System2 Service UUID
     */
    ///18F6
    static let NEO_SYSTEM2_SERVICE_UUID = CBUUID(string :"18F6")
    ///2AB7
    static let PEN_PASSWORD_REQUEST_UUID = CBUUID(string :"2AB7")
    ///2AB8
    static let PEN_PASSWORD_RESPONSE_UUID = CBUUID(string :"2AB8")
    ///2AB9
    static let PEN_PASSWORD_CHANGE_REQUEST_UUID = CBUUID(string :"2AB9")
    ///2ABA
    static let PEN_PASSWORD_CHANGE_RESPONSE_UUID = CBUUID(string :"2ABA")
    
    /* device information Service UUID
     */
    ///180A
    static let NEO_DEVICE_INFO_SERVICE_UUID = CBUUID(string :"180A")
    ///2A26
    static let FW_VERSION_UUID = CBUUID(string :"2A26")
}

// Protocol V2
struct Pen2{
    ///19F1
    static let NEO_PEN2_SERVICE_UUID = CBUUID(string :"19F1" )
    ///19F0
    static let NEO_PEN2_SYSTEM_SERVICE_UUID = CBUUID(string :"19F0")
    ///2BA1
    static let PEN2_DATA_UUID = CBUUID(string :"2BA1")
    ///2BA0
    static let PEN2_SET_DATA_UUID = CBUUID(string :"2BA0")
}

