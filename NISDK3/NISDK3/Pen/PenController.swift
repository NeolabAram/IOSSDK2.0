//
//  PenController.swift
//  NISDK3
//
//  Created by Aram Moon on 2017. 6. 7..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation
import CoreBluetooth

public enum PenStatus : Int {
    case None
    case ScanStart
    case Discover
    case Connect
    case Disconnect
}
enum OfflineData : Int {
    case Start
    case Progressing
    case End
    case Fail
}
enum FirmWareUpdate : Int {
    case Start
    case Progressing
    case End
    case Fail
}

enum PenService : String{
    case UUID = "E20A39F4-73F5-4BC4-A12F-17D1AD07A961"
}

enum PenCharacteristic : String{
    case ReadUUID = "08590F7E-DB05-467E-8757-72F6FAEB13D4"
    case WriteUUID = "C0C0C0C0-DEAD-F154-1319-740381000000"
}

let NOTIFY_MTU = 20

class PageDocument{
    //TODO: need to search
}

public struct NPen{
    var peripheral: CBPeripheral
    var macAddress: String = ""
    var name: String = ""
    var subName: String = ""
    var protocolVersion: String = ""
    var rssi: Int = -90
}

public class PenController: NSObject {
    
    public static let sharedInstance = PenController()
    var centralManager: CBCentralManager!
    var penCommParser: PenCommParser!
    
    //SCAN
    fileprivate var nPens = [NPen]()
    private var timer: Timer?

    //Connecte Pen
    fileprivate var nPen: NPen?
    var penConnectionStatus :PenStatus  = .None
    private var verInfoTimer: Timer?
    
    //SDK Version
    public var isPenSDK2: Bool = true
    
    // Pen SDK2.0 Service
    var pen2Service: CBService?
    var pen2Characteristics: [CBUUID] = []
    var pen2SetDataCharacteristic: CBCharacteristic?
    
    // Pen Servce
    var penCharacteristics: [CBUUID] = []
    var penService: CBService?
    
    // Offline data service
    var offlineCharacteristics: [CBUUID] = []
    var offline2Characteristics: [CBUUID] = []
    var offlineService: CBService?
    var offline2Service: CBService?
    var requestDelOfflineFileCharacteristic: CBCharacteristic?
    var requestOfflineFileCharacteristic: CBCharacteristic?
    var requestOfflineFileListCharacteristic: CBCharacteristic?
    var offline2FileAckCharacteristic: CBCharacteristic?
    var isNeedRequestOfflineFileList: Bool = false
    
    // Update Service
    var updateCharacteristics = [CBUUID]()
    var updateService: CBService?
    var sendUpdateFileInfoCharacteristic: CBCharacteristic?
    var updateFileDataCharacteristic: CBCharacteristic?
    
    // System Service
    var systemCharacteristics = [CBUUID]()
    var systemService: CBService?
    var setPenStateCharacteristic: CBCharacteristic?
    var setNoteIdListCharacteristic: CBCharacteristic?
    var readyExchangeDataCharacteristic: CBCharacteristic?
    
    // System2 Service
    var system2Characteristics = [CBUUID]()
    var system2Service: CBService?
    var penPasswordResponseCharacteristic: CBCharacteristic?
    var penPasswordChangeRequestCharacteristic: CBCharacteristic?
    var supportedServices = [CBUUID]()
    
    // Device Information Service
    var deviceInfoCharacteristics = [Pen.FW_VERSION_UUID]
    
    var deviceInfoService: CBService?
    var setRtcCharacteristic: CBCharacteristic?

    private var bt_write_dispatch_queue :DispatchQueue!
    private let bt_write_queue_lable = "bt_write_dispatch_queue"
    
    var penConnectionStatusMsg = ""
    
    var isAutoConnection = false
    
    private override init() {
        super.init()
        
        pen2Characteristics = [Pen2.PEN2_DATA_UUID,Pen2.PEN2_SET_DATA_UUID]
        penCharacteristics = [Pen.STROKE_DATA_UUID, Pen.UPDOWN_DATA_UUID, Pen.ID_DATA_UUID]
        
        // Offline data Service
        offlineCharacteristics = [Pen.REQUEST_OFFLINE_FILE_LIST_UUID, Pen.OFFLINE_FILE_LIST_UUID, Pen.REQUEST_DEL_OFFLINE_FILE_UUID]
        
        // Offline2 data Service
        offline2Characteristics = [Pen2.OFFLINE2_FILE_INFO_UUID, Pen2.OFFLINE2_FILE_DATA_UUID,Pen2.OFFLINE2_FILE_LIST_INFO_UUID, Pen2.REQUEST_OFFLINE2_FILE_UUID, Pen2.OFFLINE2_FILE_STATUS_UUID, Pen2.OFFLINE2_FILE_ACK_UUID]
        
        // Update Service
        updateCharacteristics = [Pen.UPDATE_FILE_INFO_UUID, Pen.REQUEST_UPDATE_FILE_UUID,Pen.UPDATE_FILE_DATA_UUID, Pen.UPDATE_FILE_STATUS_UUID]
        
        // System Service
        systemCharacteristics = [Pen.PEN_STATE_UUID,Pen.SET_PEN_STATE_UUID,Pen.SET_NOTE_ID_LIST_UUID,Pen.READY_EXCHANGE_DATA_UUID,Pen.READY_EXCHANGE_DATA_REQUEST_UUID]

        // System2 Service
        system2Characteristics = [Pen2.PEN_PASSWORD_REQUEST_UUID,Pen2.PEN_PASSWORD_RESPONSE_UUID,Pen2.PEN_PASSWORD_CHANGE_REQUEST_UUID, Pen2.PEN_PASSWORD_CHANGE_RESPONSE_UUID]
        
        // Device Information Service
        supportedServices = [Pen2.NEO_PEN2_SERVICE_UUID,Pen2.NEO_PEN2_SYSTEM_SERVICE_UUID,Pen.NEO_PEN_SERVICE_UUID,Pen.NEO_SYSTEM_SERVICE_UUID,Pen.NEO_OFFLINE_SERVICE_UUID,Pen2.NEO_OFFLINE2_SERVICE_UUID,Pen.NEO_UPDATE_SERVICE_UUID,Pen.NEO_DEVICE_INFO_SERVICE_UUID,Pen2.NEO_PEN2_SYSTEM_SERVICE_UUID]

        bt_write_dispatch_queue = DispatchQueue(label: bt_write_queue_lable)
        initBluetooth()
        
        penCommParser = PenCommParser(penCommController: self)
    }
    
    public func setPenDelegate(_ delegate: DeviceDelegate) {
        penCommParser?.penDelegate = delegate
    }
    
    public func showLog(_ flag : Bool){
        N.isDebug = flag
    }
    
    //MARK: - Public Bluetooth -
    /// Scan for peripherals - specifically for our service's 128bit CBUUID
    ///if time = 0 default scan Time
    public func scan(durationTime time : CGFloat) {
        nPens.removeAll()
        penCommParser.passwdCounter = 0
        N.Log("Scanning started")
        centralManager.stopScan()
        centralManager.scanForPeripherals(withServices: [Pen2.NEO_PEN2_SERVICE_UUID, Pen.NEO_PEN_SERVICE_UUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        if !time.isZero{
            startScanTimer(time)
        }
    }
    
    public func autoConnection() -> Int {
        var connectedPeripherals: [Any]
        if centralManager.state == .poweredOn {
            if (penConnectionStatus == .None) || (penConnectionStatus == .Disconnect) {
                penConnectionStatus = .None
                connectedPeripherals = centralManager.retrieveConnectedPeripherals(withServices: [Pen2.NEO_PEN2_SERVICE_UUID, Pen2.NEO_PEN2_SYSTEM_SERVICE_UUID , Pen.NEO_PEN_SERVICE_UUID, Pen.NEO_SYSTEM_SERVICE_UUID])

                if connectedPeripherals.count == 0 {
                    isAutoConnection = true
                    scan(durationTime: 3.0)
                }
                else {
                    if penCommParser.penDelegate != nil {
                        DispatchQueue.main.async(execute: {() -> Void in
                            self.penCommParser.penDelegate?.deviceService(PenStatus.Connect, device: nil)
                        })
                    }
                }
            }
        }
        N.Log("Status", centralManager.state)
        let btState: Int = centralManager.state.rawValue
        return btState
    }
    
    public func scanStop() {
        if centralManager.state == .poweredOn {
            if penConnectionStatus == .ScanStart {
                centralManager.stopScan()
                N.Log("stop scanning by stop searching button")
            }
        }
    }
    
    public func disConnect() {
        // Give some time to pen, before actual disconnect.
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double((Int64)(500 * NSEC_PER_MSEC)) / Double(NSEC_PER_SEC), execute: {() -> Void in
            self.disConnectInternal()
        })
    }
    
    private func disConnectInternal() {
        N.Log("disconnect current peripheral \(String(describing: nPen))")
        if let pen = nPen {
            centralManager.cancelPeripheralConnection(pen.peripheral)
            nPen = nil
        }
        penConnectionStatus = .Disconnect
        #if AUDIO_BACKGROUND_FOR_BT
            let delegate: NJAppDelegate? = (UIApplication.shared.delegate as? NJAppDelegate)
            delegate?.audioController?.stop()
        #endif
    }
    
    public func connectPeripheral(_ peripheral: CBPeripheral) {
        N.Log("Connecting to peripheral \(String(describing: peripheral))")
        centralManager.connect(peripheral, options: nil)
    }

    func getMacAddr(fromString data: Any) -> String {
        var macAddrStr: String = String.init(describing: data)
        macAddrStr = macAddrStr.replacingOccurrences(of: "<", with: "")
        macAddrStr = macAddrStr.replacingOccurrences(of: ">", with: "")
        macAddrStr = macAddrStr.replacingOccurrences(of: " ", with: "")
        return macAddrStr
    }
    
    //MARK: - private Bluetooth -
    private func startScanTimer(_ duration: CGFloat) {
        if timer == nil {
            timer = Timer(timeInterval: TimeInterval(duration), target: self, selector: #selector(self.selectRSSI), userInfo: nil, repeats: false)
            RunLoop.main.add(timer!, forMode: RunLoopMode.defaultRunLoopMode)
        }
    }
    
    private func stopScanTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    fileprivate func startTimerForVerInfoReq() {
        if verInfoTimer == nil {
            verInfoTimer = Timer(timeInterval: 0.7, target: self, selector: #selector(self.requestVersionInfo), userInfo: nil, repeats: false)
            RunLoop.main.add(verInfoTimer!, forMode: .defaultRunLoopMode)
        }
    }
    
    private func stopTimerForVerInfoReq() {
        verInfoTimer?.invalidate()
        verInfoTimer = nil
    }
    
    @objc private func requestVersionInfo() {
        stopTimerForVerInfoReq()
        setVersionInfo()
    }
    
    @objc private func selectRSSI() {
        N.Log("Scan Stop")

        centralManager.stopScan()
        stopScanTimer()
        if !isAutoConnection{
            return
        }
        isAutoConnection = false
        N.Log("[selectRSSI] slectRSSI started....")
        let noPeripherals: Int = nPens.count
        if noPeripherals == 0 {
            N.Log("[selectRSSI] no peripherals found....")
            // we have not any discovered peripherals
            penConnectionStatusMsg = "NULL"
            penConnectionStatus = .Disconnect
            return
        }
        var maxRssi : Int = -90
        var maxRssiPen: NPen?

        for pen in nPens{
            if pen.rssi > maxRssi{
                maxRssi = pen.rssi
                maxRssiPen = pen
            }
            
        }
        
        if let selectedPen = maxRssiPen{
            N.Log("Connecting to MAC",selectedPen.macAddress)
            connectPeripheral(selectedPen.peripheral)
            nPen = selectedPen
            return
        }
        
        /*
        var serviceUUID: String
        var penLocalName: String
        
        // 1.try macAddr first
        var uid: String = selectedPen.macAddress
        
        if serviceIdArray.count > rssiIndex {
            serviceUUID = serviceIdArray[rssiIndex]
        }
        if penLocalNameArray.count > rssiIndex {
            penLocalName = penLocalNameArray[rssiIndex].uppercased()
            //NSLog(@"penLocalName: %@", penLocalName);
        }
        else {
            N.Log("penLocalNameArray count \(UInt(penLocalNameArray.count)), rssiIndex:\(Int(rssiIndex))")
        }
        if uid.isEmpty {
            // 2.if no macAddr (backwards-compatibility) try uuid
            uid = (foundPeripheral?.identifier.uuidString)!
        }
        penName = foundPeripheral?.name
        let pName: String? = foundPeripheral?.name?.uppercased()
        #if SUPPORT_SDK2
            if (serviceUUID == "19F0") || (serviceUUID == "19F1") {
                isPenSDK2 = true
                N.Log("PenSDK2.0 Pen registered")
            }
            else {
                isPenSDK2 = false
                N.Log("PenSDK1.0 Pen registered")
            }
        #else
            isPenSDK2 = false
        #endif
        #if !SUPPORT_PEN_LOCALSUBNAME
            regUuid = uid
            hasPenRegistered = true
            UserDefaults.standard.set(true, forKey: "penAutoPower")
            connectPeripheral(at: rssiIndex)
            N.Log("registration success uuid \(uid)")
            //                    NotificationCenter.default.post(name: NJPenRegistrationNotification, object: nil, userInfo: nil)
            return
        #else
            if btIDList.isEmpty {
                regUuid = uid
                isPenRegister = true
                UserDefaults.standard.set(true, forKey: "penAutoPower")
                connectPeripheral(at: rssiIndex)
                N.Log("registration success uuid \(uid)")
                //                        NotificationCenter.default.post(name: NJPenRegistrationNotification, object: nil, userInfo: nil)
                return
            }
            else {
                //NSLog(@"BT ID List %@",self.btIDList);
                for btIDPermitted: String in btIDList {
                    //NSLog(@"BT ID from BT ID List: %@, penLocalName: %@",btIDPermitted, penLocalName);
                    if (penLocalName == btIDPermitted) {
                        regUuid() = uid
                        hasPenRegistered() = true
                        UserDefaults.standard.set(true, forKey: "penAutoPower")
                        connectPeripheral(at: rssiIndex)
                        N.Log("registration success uuid \(uid)")
                        NotificationCenter.default.post(name: NJPenRegistrationNotification, object: nil, userInfo: nil)
                        return
                    }
                }
            }
        #endif
        
        */
        // if we reached here --> we failed, and try the scan again
        N.Log("[selectRSSI] not found any eligible peripheral....")
        penConnectionStatusMsg = "This pen is not registered."
        penConnectionStatus = .Disconnect
    }
    
    /// Call this when things either go wrong, or you're done with the connection.
    /// This cancels any subscriptions if there are any, or straight disconnects if not.
    /// (didUpdateNotificationStateForCharacteristic will cancel the connection if a subscription is involved)
    func cleanup() {
        N.Log("[PenCommMan] cleanup()")
        // Don't do anything if we're not connected
        if nPen?.peripheral.state != .connected {
            return
        }
        // See if we are subscribed to a characteristic on the peripheral
        if nPen?.peripheral.services != nil {
            for service: CBService in (nPen?.peripheral.services)! {
                if service.characteristics != nil {
                    for characteristic: CBCharacteristic in service.characteristics! {
                        if characteristic.uuid.isEqual(Pen.STROKE_DATA_UUID
                            ) {
                            if characteristic.isNotifying {
                                // It is notifying, so unsubscribe
                                nPen?.peripheral.setNotifyValue(false, for: characteristic)
                                // And we're done.
                                penConnectionStatusMsg = "NULL"
                                penConnectionStatus = .Disconnect
                                return
                            }
                        }
                    }
                }
            }
        }
        // If we've got this far, we're connected, but we're not subscribed, 
        // so we just disconnect
        centralManager.cancelPeripheralConnection((nPen!.peripheral))
    }
    
    //MARK: - Write to Pen
    func writePen2SetData(_ data: Data) {
        bt_write_dispatch_queue.async(execute: {() -> Void in
            self.nPen?.peripheral.writeValue(data, for: self.pen2SetDataCharacteristic!, type: .withResponse)
        })
    }
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
    
    // MARK: - Public API
    public func setPenStateWithRGB(_ color: UInt32) {
        if isPenSDK2 {
            let tType: UInt8 = 0
            //normal:0, eraser:1
            //penCommParser.setPenState2WithTypeAndRGB(color, tType: UInt8(tType))
        }
        else {
            //penCommParser.setPenStateWithRGB(color)
        }
    }
    
    public func setPenStateWithPenPressure(_ penPressure: UInt16) {
        if isPenSDK2 {
            let type: RequestPenStateType = .PenPresure
            //penCommParser.setPenStateWithPenPressure(penPressure)
        }
        else {
            //penCommParser.setPenStateWithPenPressure(penPressure)
        }
    }
    
    public func setPenStateWithAutoPwrOffTime(_ autoPwrOff: UInt16) {
        if isPenSDK2 {
            //penCommParser.setPenState2WithTypeAndAutoPwrOffTime(autoPwrOff)
        }
        else {
            //penCommParser.setPenStateWithAutoPwrOffTime(autoPwrOff)
        }
    }
    
    public func setPenStateAutoPower(_ autoPower: UInt8, sound: UInt8) {
        if isPenSDK2 {
            var type: RequestPenStateType
            if sound == 0xff {
                type = .AutoPowerOn
                //penCommParser.setPenState2(UInt8(type.rawValue), andValue: autoPower)
            }
            else if autoPower == 0xff {
                type = .BeepOnOff
                //penCommParser.setPenState2(UInt8(type.rawValue), andValue: sound)
            }
        }
        else {
            //penCommParser.setPenStateAutoPower(autoPower, sound: sound)
        }
    }
    
    public func setPenStateWithHover(_ useHover: UInt16) {
        if isPenSDK2 {
            //penCommParser.setPenState2WithTypeAndHover(UInt8(useHover))
        }
        else {
            //penCommParser.setPenStateWithHover(useHover)
        }
    }
    
    public func setPenStateWithTimeTick() {
        if isPenSDK2 {
            //penCommParser.setPenState2WithTypeAndTimeStamp()
        }
        else {
            //penCommParser.setPenStateWithTimeTick()
        }
    }
    
    public func getPenStateWithBatteryLevel() -> UInt8 {
        return penCommParser.batteryLevel
    }
    
    public func getPenStateWithMemoryUsed() -> UInt8 {
        return penCommParser.memoryUsed
    }
    
    public func getFWVersion() -> String {
        return penCommParser.fwVersion
    }
    
    /// Offline
    public func requestOfflineNoteList(){
        self.penCommParser.requestOfflineFileList2()
    }
    
    public func requestOfflinePageList(pageList: [UInt32]){
        self.penCommParser.requestOfflineFileList2()
    }
    
    public func requestOfflineData(withOwnerId ownerId: UInt32, noteId: UInt32) -> Bool {
        if isPenSDK2
        {
            let selectedPagesArray = [UInt32]()
            return true //penCommParser.requestOfflineData2(withOwnerId: ownerId, noteId: noteId, pageId: selectedPagesArray)
        }
        else {
            return true
//            return penCommParser.requestOfflineData(withOwnerId: ownerId, noteId: noteId)
        }
    }
    
    public func setPenThickness(_ thickness: Int) {
        penCommParser.penThickness = thickness
    }
    
    public func setPassword(_ pinNumber: String) {
        if isPenSDK2 {
            penCommParser.setPasswordSDK2(pinNumber)
        }
        else {
//            penCommParser.setPassword(pinNumber)
        }
    }
    
    public func changePassword(from curNumber: String, to pinNumber: String) {
        if isPenSDK2 {
            penCommParser.setChangePasswordSDK2From(curNumber, to: pinNumber)
        }
        else {
//            penCommParser.changePassword(from: curNumber, to: pinNumber)
        }
    }
    
    public func setBTComparePassword(_ pinNumber: String) {
        if isPenSDK2 {
            penCommParser.setComparePasswordSDK2(pinNumber)
        }
        else {
//            penCommParser.setBTComparePassword(pinNumber)
        }
    }
    
    public func sendUpdateFileInfoAtUrl(toPen fileUrl: URL) {
        if isPenSDK2 {
//            penCommParser.sendUpdateFileInfo2(at: (fileUrl as? URL)!)
        }
        else {
//            penCommParser.sendUpdateFileInfoAtUrl(toPen: (fileUrl as? URL)!)
        }
    }
    
    public func setCancelFWUpdate(_ cancelFWUpdate: Bool) {
//        penCommParser.setCancelFWUpdate(cancelFWUpdate)
    }
    
    /// Offline cancel
    public func setCancelOfflineSync(_ cancelOfflineSync: Bool) {
//        penCommParser.setCancelOfflineSync(cancelOfflineSync)
    }
    
    public func getPenBattLevelAndMemoryUsedSize() {
        if isPenSDK2 {
            penCommParser.setRequestPenState()
        }
        else {
//            penCommParser.setPenStateWithTimeTick()
        }
    }

    public func setPenState() {
        if isPenSDK2 {
            penCommParser.setRequestPenState()
        }
        else {
//            penCommParser.setPenState()
        }
    }
    
    public func setNoteIdListFromPList() {
        if isPenSDK2 {
//            penCommParser.setNoteIdListFromPList2()
        }
        else {
//            penCommParser.setNoteIdListFromPList()
        }
    }
    
    /// Using Note Set
    public func setAllNoteIdList() {
        if isPenSDK2 {
            penCommParser.setAllNoteIdList2()
        }
        else {
//            penCommParser.setAllNoteIdList()
        }
    }
    
    public func setNoteIdListSectionOwnerFromPList() {
        if isPenSDK2 {
//            penCommParser.setNoteIdListSectionOwnerFromPList2()
        }
        else {
//            penCommParser.setNoteIdListSectionOwnerFromPList()
        }
    }
    
    public func processPressure(_ pressure: Float) -> Float {
        return 0 //penCommParser.processPressure(pressure)
    }
    
    //MARK: - SDK 2.0 -
    public func setVersionInfo() {
        penCommParser.setVersionInfo()
    }
    
    public func protocolVersion() -> String {
        if isPenSDK2 {
            return penCommParser.protocolVerStr
        }
        else {
            return "1"
        }
    }
}

// MARK: - CBPeripheralDelegate -
extension PenController: CBPeripheralDelegate {
    
    // After connected
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            N.Log("Error discovering services: \(String(describing: error?.localizedDescription))")
            cleanup()
            return
        }
        // Discover the characteristic we want...
        // Loop through the newly filled peripheral.services array, just in case there's more than one.
        guard peripheral.services != nil else {
            return
        }
        
        for service: CBService in peripheral.services! {
            N.Log("Service UUID : \(service.uuid.uuidString)")
            if service.uuid.isEqual(Pen2.NEO_PEN2_SERVICE_UUID) {
                pen2Service = service
                peripheral.discoverCharacteristics(pen2Characteristics, for: service)
            }
            else if service.uuid.isEqual(Pen.NEO_SYSTEM_SERVICE_UUID) {
                systemService = service
                peripheral.discoverCharacteristics(systemCharacteristics, for: service)
            }
            else if service.uuid.isEqual(Pen2.NEO_SYSTEM2_SERVICE_UUID) {
                system2Service = service
                peripheral.discoverCharacteristics(system2Characteristics, for: service)
            }
            else if service.uuid.isEqual(Pen.NEO_PEN_SERVICE_UUID) {
                penService = service
                // Initialize some value.
                peripheral.discoverCharacteristics(penCharacteristics, for: service)
            }
            else if service.uuid.isEqual(Pen.NEO_OFFLINE_SERVICE_UUID) {
                offlineService = service
                peripheral.discoverCharacteristics(offlineCharacteristics, for: service)
            }
            else if service.uuid.isEqual(Pen2.NEO_OFFLINE2_SERVICE_UUID) {
                offline2Service = service
                peripheral.discoverCharacteristics(offline2Characteristics, for: service)
            }
            else if service.uuid.isEqual(Pen.NEO_UPDATE_SERVICE_UUID) {
                updateService = service
                peripheral.discoverCharacteristics(updateCharacteristics, for: service)
            }
            else if service.uuid.isEqual(Pen.NEO_DEVICE_INFO_SERVICE_UUID) {
                deviceInfoService = service
                peripheral.discoverCharacteristics(deviceInfoCharacteristics, for: service)
            }
        }
    }
    /** The Transfer characteristic was discovered.
     *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
     */
    // After discovered Service
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // Deal with errors (if any)
        if error != nil {
            N.Log("Error discovering characteristics: \(String(describing: error?.localizedDescription))")
            cleanup()
            return
        }
        guard let characters = service.characteristics else{
            N.Log("Service Characteristics is nil")
            return
        }
        if service == pen2Service {
            // Again, we loop through the array, just in case.
            for characteristic: CBCharacteristic in characters {
                // And check if it's the right one
                if pen2Characteristics.contains(characteristic.uuid) {
                    if characteristic.uuid.isEqual(Pen2.PEN2_DATA_UUID) {
                        //NSLog(@"pen2DataUuid");
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                    else if characteristic.uuid.isEqual(Pen2.PEN2_SET_DATA_UUID) {
                        //NSLog(@"pen2SetDataUuid");
                        pen2SetDataCharacteristic = characteristic
                        startTimerForVerInfoReq()
                    }
                }
                else {
                    N.Log("Unknown characteristic \(service.uuid) for service \(characteristic.uuid)")
                }
            }
        }
        else if service == penService {
            // Again, we loop through the array, just in case.
            for characteristic: CBCharacteristic in characters {
                // And check if it's the right one
                if penCharacteristics.contains(characteristic.uuid) {
                    if characteristic.uuid.isEqual(Pen.STROKE_DATA_UUID) {
                        N.Log("strokeDataUuid")
                        penCommParser.penCommStrokeDataReady = true
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                    else if characteristic.uuid.isEqual(Pen.UPDOWN_DATA_UUID) {
                        N.Log("updownDataUuid")
                        penCommParser.penCommUpDownDataReady = true
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                    else if characteristic.uuid.isEqual(Pen.ID_DATA_UUID) {
                        N.Log("idDataUuid")
                        penCommParser.penCommIdDataReady = true
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                    else if characteristic.uuid.isEqual(Pen2.OFFLINE2_FILE_INFO_UUID) {
                        N.Log("offlineFileInfoUuid")
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                    else if characteristic.uuid.isEqual(Pen2.OFFLINE2_FILE_DATA_UUID) {
                        N.Log("offlineFileDataUuid")
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                }
                else {
                    N.Log("Unknown characteristic \(service.uuid) for service \(characteristic.uuid)")
                }
            }
        }
        else if service == systemService {
            for characteristic: CBCharacteristic in characters {
                // And check if it's the right one
                if systemCharacteristics.contains(characteristic.uuid) {
                    if characteristic.uuid.isEqual(Pen.PEN_STATE_UUID) {
                        N.Log("penStateDataUuid")
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                    else if characteristic.uuid.isEqual(Pen.SET_PEN_STATE_UUID) {
                        N.Log("setPenStateUuid")
                        setPenStateCharacteristic = characteristic
                    }
                    else if characteristic.uuid.isEqual(Pen.SET_NOTE_ID_LIST_UUID) {
                        N.Log("setNoteIdListUuid")
                        setNoteIdListCharacteristic = characteristic
                        penCommParser.setNoteIdList()
                    }
                    else if characteristic.uuid.isEqual(Pen.READY_EXCHANGE_DATA_UUID) {
                        N.Log("readyExchangeDataUuid")
                        readyExchangeDataCharacteristic = characteristic
                    }
                    else if characteristic.uuid.isEqual(Pen.READY_EXCHANGE_DATA_REQUEST_UUID) {
                        N.Log("readyExchangeDataRequestUuid")
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                }
                else {
                    N.Log("Unknown characteristic \(service.uuid) for service \(characteristic.uuid)")
                }
            }
        }
        else if service == system2Service {
            for characteristic: CBCharacteristic in characters {
                // And check if it's the right one
                if system2Characteristics.contains(characteristic.uuid) {
                    if characteristic.uuid.isEqual(Pen2.PEN_PASSWORD_REQUEST_UUID) {
                        N.Log("penPasswordRequestUuid")
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                    else if characteristic.uuid.isEqual(Pen2.PEN_PASSWORD_RESPONSE_UUID) {
                        N.Log("penPasswordResponseUuid")
                        penPasswordResponseCharacteristic = characteristic
                    }
                    else if characteristic.uuid.isEqual(Pen2.PEN_PASSWORD_CHANGE_REQUEST_UUID) {
                        N.Log("penPasswordChangeRequestUuid")
                        penPasswordChangeRequestCharacteristic = characteristic
                    }
                    else if characteristic.uuid.isEqual(Pen2.PEN_PASSWORD_CHANGE_RESPONSE_UUID) {
                        N.Log("penPasswordChangeResponseUuid")
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                }
                else {
                    N.Log("Unknown characteristic \(service.uuid) for service \(characteristic.uuid)")
                }
            }
        }
        else if service == offline2Service {
            // Again, we loop through the array, just in case.
            for characteristic: CBCharacteristic in characters {
                // And check if it's the right one
                if offline2Characteristics.contains(characteristic.uuid) {
                    if characteristic.uuid.isEqual(Pen2.OFFLINE2_FILE_INFO_UUID) {
                        N.Log("offlineFileInfoUuid")
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                    else if characteristic.uuid.isEqual(Pen2.OFFLINE2_FILE_DATA_UUID) {
                        N.Log("offlineFileDataUuid")
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                    else if characteristic.uuid.isEqual(Pen2.OFFLINE2_FILE_LIST_INFO_UUID) {
                        N.Log("offlineFileListInfoUuid")
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                    else if characteristic.uuid.isEqual(Pen2.REQUEST_OFFLINE2_FILE_UUID) {
                        N.Log("requestOfflineFileUuid")
                        requestOfflineFileCharacteristic = characteristic
                    }
                    else if characteristic.uuid.isEqual(Pen2.OFFLINE2_FILE_STATUS_UUID) {
                        N.Log("offlineFileStatusUuid")
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                    else if characteristic.uuid.isEqual(Pen2.OFFLINE2_FILE_ACK_UUID) {
                        N.Log("offline2FileAckUuid")
                        offline2FileAckCharacteristic = characteristic
                    }
                    else {
                        N.Log("Unhandled characteristic \(service.uuid) for service \(characteristic.uuid)")
                    }
                }
                else {
                    N.Log("Unknown characteristic \(service.uuid) for service \(characteristic.uuid)")
                }
            }
        }
        else if service == offlineService {
            // Again, we loop through the array, just in case.
            for characteristic: CBCharacteristic in characters {
                // And check if it's the right one
                if offlineCharacteristics.contains(characteristic.uuid) {
                    if characteristic.uuid.isEqual(Pen.REQUEST_OFFLINE_FILE_LIST_UUID) {
                        N.Log("requestOfflineFileListUuid")
                        requestOfflineFileListCharacteristic = characteristic
                    }
                    else if characteristic.uuid.isEqual(Pen.OFFLINE_FILE_LIST_UUID) {
                        N.Log("offlineFileListUuid")
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                    else if characteristic.uuid.isEqual(Pen.REQUEST_DEL_OFFLINE_FILE_UUID) {
                        N.Log("requestDelOfflineFileUuid")
                        requestDelOfflineFileCharacteristic = characteristic
                    }
                    else {
                        N.Log("Unhandled characteristic \(service.uuid) for service \(characteristic.uuid)")
                    }
                }
                else {
                    N.Log("Unknown characteristic \(service.uuid) for service \(characteristic.uuid)")
                }
            }
        }
        else if service == updateService {
            // Again, we loop through the array, just in case.
            for characteristic: CBCharacteristic in characters {
                // And check if it's the right one
                if updateCharacteristics.contains(characteristic.uuid) {
                    if characteristic.uuid.isEqual(Pen.UPDATE_FILE_INFO_UUID) {
                        N.Log("updateFileInfoUuid")
                        sendUpdateFileInfoCharacteristic = characteristic
                    }
                    else if characteristic.uuid.isEqual(Pen.REQUEST_UPDATE_FILE_UUID) {
                        N.Log("requestUpdateFileInfoUuid")
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                    else if characteristic.uuid.isEqual(Pen.UPDATE_FILE_DATA_UUID) {
                        N.Log("updateFileDataUuid")
                        updateFileDataCharacteristic = characteristic
                    }
                    else if characteristic.uuid.isEqual(Pen.UPDATE_FILE_STATUS_UUID) {
                        N.Log("updateFileStatusUuid")
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                    else {
                        N.Log("Unhandled characteristic \(service.uuid) for service \(characteristic.uuid)")
                    }
                }
                else {
                    N.Log("Unknown characteristic \(service.uuid) for service \(characteristic.uuid)")
                }
            }
        }
        else if service == deviceInfoService {
            // Again, we loop through the array, just in case.
            for characteristic: CBCharacteristic in characters {
                // And check if it's the right one
                if deviceInfoCharacteristics.contains(characteristic.uuid) {
                    if characteristic.uuid.isEqual(Pen.FW_VERSION_UUID) {
                        N.Log("fwVersionUuid")
                        peripheral.readValue(for: characteristic)
                    }
                }
                else {
                    N.Log("Unknown characteristic \(service.uuid) for service \(characteristic.uuid)")
                }
            }
        }
        // Once this is complete, we just need to wait for the data to come in.
    }
    
    /** This callback lets us know more data has arrived via notification on the characteristic
     */
    //MARK: Pen DATA
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            N.Log("Error discovering characteristics: \(String(describing: error?.localizedDescription))")
            return
        }
        guard let received_data = characteristic.value else {
            N.Log("Data is empty")
            return
        }
        let dataLength = received_data.count
        let packet = [UInt8](received_data)
//        N.Log("Pen Data", packet[1], CMD(rawValue: packet[1]))
        if characteristic.uuid.isEqual(Pen2.PEN2_DATA_UUID) {
//            N.Log("Received: pen2DataUuid data");
            penCommParser.parsePen2Data(packet, withLength: dataLength)
        }
        else if characteristic.uuid.isEqual(Pen.STROKE_DATA_UUID) {
            //penCommParser.parsePenStrokeData(packet, withLength: dataLength)
        }
        else if characteristic.uuid.isEqual(Pen.UPDOWN_DATA_UUID) {
            N.Log("Received: updown")
//            writeSetPenState = true
            //penCommParser.parsePenStrokeData(packet, withLength: dataLength)
        }
        else if characteristic.uuid.isEqual(Pen.ID_DATA_UUID) {
            N.Log("Received: id data")
            //penCommParser.parsePenNewIdData(packet, withLength: dataLength)
        }
        else if characteristic.uuid.isEqual(Pen.OFFLINE_FILE_LIST_UUID) {
            N.Log("Received: offline file data");
            //penCommParser.parseOfflineFileData(packet, withLength: dataLength)
        }
        else if characteristic.uuid.isEqual(Pen2.OFFLINE2_FILE_LIST_INFO_UUID) {
            N.Log("Received: offline file info data")
            //penCommParser.parseOfflineFileInfoData(packet, withLength: dataLength)
        }
        else if characteristic.uuid.isEqual(Pen.PEN_STATE_UUID) {
            N.Log("Received: pen status data")
            penConnectionStatusMsg = NSLocalizedString("BT_PEN_CONNECTED", comment: "")
            penConnectionStatus = .Connect
            //penCommParser.parsePenStatusData(packet, withLength: dataLength)
        }
        else if characteristic.uuid.isEqual(Pen.OFFLINE_FILE_LIST_UUID) {
            N.Log("Received: offline File list")
            //penCommParser.parseOfflineFileList(packet, withLength: dataLength)
        }
        else if characteristic.uuid.isEqual(Pen2.OFFLINE2_FILE_LIST_INFO_UUID) {
            N.Log("Received: offline File List info")
            //penCommParser.parseOfflineFileListInfo(packet, withLength: dataLength)
        }
        else if characteristic.uuid.isEqual(Pen2.OFFLINE2_FILE_STATUS_UUID) {
            N.Log("Received: offline File Status")
            //penCommParser.parseOfflineFileStatus(packet, withLength: dataLength)
        }
        else if characteristic.uuid.isEqual(Pen.REQUEST_UPDATE_FILE_UUID) {
            N.Log("Received: request update file")
            //penCommParser.parseRequestUpdateFile(packet, withLength: dataLength)
        }
        else if characteristic.uuid.isEqual(Pen.UPDATE_FILE_STATUS_UUID) {
            N.Log("Received: update file status ")
            //penCommParser.parseUpdateFileStatus(packet, withLength: dataLength)
        }
        else if characteristic.uuid.isEqual(Pen.READY_EXCHANGE_DATA_REQUEST_UUID) {
            N.Log("Received: readyExchangeDataRequestUuid")
            //penCommParser.parseReadyExchangeDataRequest(packet, withLength: dataLength)
        }
        else if characteristic.uuid.isEqual(Pen2.PEN_PASSWORD_REQUEST_UUID) {
            N.Log("Received: penPasswordRequestUuid")
            //penCommParser.parsePenPasswordRequest(packet, withLength: dataLength)
        }
        else if characteristic.uuid.isEqual(Pen2.PEN_PASSWORD_CHANGE_RESPONSE_UUID) {
            N.Log("Received: penPasswordResponseUuid")
            //penCommParser.parsePenPasswordChangeResponse(packet, withLength: dataLength)
        }
        else if characteristic.uuid.isEqual(Pen.FW_VERSION_UUID) {
            N.Log("Received: FW version")
            penCommParser.parseFWVersion(packet, withLength: dataLength)
        }
        else {
            N.Log("Un-handled data characteristic.UUID \(characteristic.uuid.uuidString)")
            return
        }
    }
    /** The peripheral letting us know whether our subscribe/unsubscribe happened or not
     */
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            N.Log("Error changing notification state: \(String(describing: error?.localizedDescription)) characteristic : \(characteristic.uuid)")
        }
        // Notification has started
        if characteristic.isNotifying {
            N.Log("Notification began on \(characteristic)")
            penCommParser.penDelegate?.deviceService(.Connect, device: self.nPen)
        }
        else {
            // so disconnect from the peripheral
            N.Log("Notification stopped on \(characteristic).  Disconnecting")
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            N.Log("Error WriteValueForCharacteristic: \(String(describing: error?.localizedDescription)) characteristic : \(characteristic.uuid)")
            return
        }
        if characteristic == pen2SetDataCharacteristic {
            N.Log("Pen2.0 Data Write successful")
//            if IS_OS_9_OR_LATER && mtuReadRetry += 1 < 5 {
//                mtu() = peripheral.maximumWriteValueLength(forType: CBCharacteristicWriteWithoutResponse)
//                N.Log("MTU \(mtu())")
//            }
        }
        else if characteristic == setPenStateCharacteristic {
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
}

// MARK: - CBCentralManagerDelegate -
extension PenController: CBCentralManagerDelegate {
    /** This callback comes whenever a peripheral that is advertising the NEO_PEN_SERVICE_UUID is discovered.
     *  We check the RSSI, to make sure it's close enough that we're interested in it, and if it is,
     *  we start the connection process
     */
    
    fileprivate func initBluetooth(){
        centralManager = CBCentralManager(delegate: self, queue: (DispatchQueue(label: "kr.neolab.penBT")), options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    
    /** centralManagerDidUpdateState is a required protocol method.
     *  Usually, you'd check for other states to make sure the current device supports LE, is powered on, etc.
     *  In this instance, we're just using it to wait for CBCentralManagerStatePoweredOn, which indicates
     *  the Central is ready to be used.
     */
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // The state must be CBCentralManagerStatePoweredOn...
            // ... so start scanning
//            _ = autoConnection()
        }
        else if central.state == .poweredOff {
            disConnect()
        }
    }
    
    /** Scanning... Discover Device
     *
     */
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // Reject any where the value is above reasonable range
        if Int(RSSI) > -15 {
//            N.Log("Too Strong \(String(describing: peripheral.name)) at \(RSSI)")
            return
        }
        penConnectionStatus = .ScanStart

        let serviceUUIDs: [CBUUID]? = (advertisementData["kCBAdvDataServiceUUIDs"] as? [CBUUID])

        if !((serviceUUIDs?.contains(Pen.NEO_PEN_SERVICE_UUID))! || (serviceUUIDs?.contains(Pen2.NEO_PEN2_SERVICE_UUID))!) {
            return
        }
        
        for p in nPens{
            if p.peripheral.isEqual(peripheral){
                return
            }
        }
        let rssi = Int(RSSI) //rssiArray.append(RSSI)
        
        var tempPen = NPen(peripheral: peripheral, macAddress: "", name: "", subName: "", protocolVersion: "", rssi: rssi)
        
        if  let macAddrObj = advertisementData["kCBAdvDataManufacturerData"]{
            tempPen.macAddress = getMacAddr(fromString: macAddrObj) // String.init(describing: macAddrStr)// macAddrStr as! String
        }
//        N.Log("MAC after", tempPen.macAddress)

        if let localName = advertisementData["kCBAdvDataLocalName"] as? String {
            tempPen.name = localName
        }

        nPens.append(tempPen)
        self.penCommParser.penDelegate?.deviceService(.Discover, device: tempPen)
        
        if (serviceUUIDs?.contains(Pen.NEO_PEN_SERVICE_UUID))! {
            N.Log("found service 18F5")
        }
        else {
            N.Log("found service 19F0")
        }
//        N.Log("new discoveredPeripherals, rssi \(RSSI)")
    }

    /** If the connection fails for whatever reason, we need to deal with it.
     */
    private func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) throws {
        penConnectionStatusMsg = "NULL"
        penConnectionStatus = .Connect
//        if handleNewPeripheral {
//            DispatchQueue.main.async(execute: {() -> Void in
//                handleNewPeripheral.connectionResult(false)
//            })
//        }
        N.Log("Failed to connect to \(peripheral). (\(String(describing: error?.localizedDescription)))")
        cleanup()
    }
    
    /** We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
     */
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
//        N.Log("Peripheral Connected")
        
        // Make sure we get the discovery callbacks
        peripheral.delegate = self

        // Search only for services that match our UUID
        peripheral.discoverServices(supportedServices)
        nPen?.peripheral = peripheral

        #if AUDIO_BACKGROUND_FOR_BT
            let delegate: NJAppDelegate? = (UIApplication.shared.delegate as? NJAppDelegate)
            delegate?.audioController?.start(nil)
        #endif
//        if !isEmpty(handleNewPeripheral) {
//            DispatchQueue.main.async(execute: {() -> Void in
//                handleNewPeripheral.connectionResult(true)
//            })
//        }
    }
    /** The Service was discovered
     */

    /** Once the disconnection happens, we need to clean up our local copy of the peripheral
     */
    private func centralManager(_ central: CBCentralManager, didDisconnect peripheral: CBPeripheral, error: Error?) throws {
        N.Log("Peripheral Disconnected")
        nPen = nil
        penConnectionStatusMsg = "NULL"
        penCommParser.resetDataReady()
        penConnectionStatus = .Disconnect
//        #if AUDIO_BACKGROUND_FOR_BT
//            let delegate: NJAppDelegate? = (UIApplication.shared.delegate as? NJAppDelegate)
//            delegate?.audioController?.stop()
//        #endif
//        writeActiveState = false
//        if !isEmpty(handleNewPeripheral) {
//            DispatchQueue.main.async(execute: {() -> Void in
//                handleNewPeripheral.connectionResult(false)
//            })
//        }
    }
    
}
