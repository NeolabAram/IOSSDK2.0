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
//enum OfflineData : Int {
//    case Start
//    case Progressing
//    case End
//    case Fail
//}
//enum FirmWareUpdate : Int {
//    case Start
//    case Progressing
//    case End
//    case Fail
//}

//enum PenService : String{
//    case UUID = "E20A39F4-73F5-4BC4-A12F-17D1AD07A961"
//}

//enum PenCharacteristic : String{
//    case ReadUUID = "08590F7E-DB05-467E-8757-72F6FAEB13D4"
//    case WriteUUID = "C0C0C0C0-DEAD-F154-1319-740381000000"
//}

let NOTIFY_MTU = 20

public struct NPenInfo{
    var peripheral: CBPeripheral
    var macAddress: String = ""
    var name: String = ""
    var subName: String = ""
    var protocolVersion: String = ""
    var rssi: Int = -90
}

public class PenController: NSObject {
    
    public static let sharedInstance = PenController()
    weak var penDelegate: PenDelegate?
    var centralManager: CBCentralManager!
    var penCommParser: PenCommParser!
    var pen2CommParser : Pen2CommParser!
    
    //SCAN
    fileprivate var nPens = [NPenInfo]()
    private var timer: Timer?

    //Connecte Pen
    var nPen: NPenInfo?
    var penConnectionStatus :PenStatus  = .None
    private var verInfoTimer: Timer?
    
    //SDK Version
    public var isPenSDK2: Bool = false
    
    // Pen SDK2.0 Service
    var pen2Service: CBService?
    var pen2Characteristics: [CBUUID] = [Pen2.PEN2_DATA_UUID,Pen2.PEN2_SET_DATA_UUID]
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

    var bt_write_dispatch_queue: DispatchQueue!
    var bt_parsing_dispach_queue: DispatchQueue!
    
    var penConnectionStatusMsg = ""
    
    var isAutoConnection = false
    
    var MTU = 0 //Maximum Transmission Unit
    
    private override init() {
        super.init()
        bt_write_dispatch_queue = DispatchQueue(label: "bt_write_dispatch_queue")
        bt_parsing_dispach_queue = DispatchQueue(label: "data_paser_dispach_queue")
        
        initBluetooth()
        
        //Protocol V2 Setting
        pen2CommParser = Pen2CommParser(penCommController: self)
        
        //Protocol V1 Setting
        initCharacteristics()
        penCommParser = PenCommParser(penCommController: self)
    }
    
    public func setPenDelegate(_ delegate: PenDelegate) {
        self.penDelegate = delegate
        penCommParser?.penDelegate = delegate
        pen2CommParser?.penDelegate = delegate
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
                            self.penDelegate?.penBluetooth(.Connect, nil)
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
        var maxRssiPen: NPenInfo?

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

    
    // MARK: - Public API
    public func requestSetPenColor(_ color: UIColor) {
        if isPenSDK2 {
            pen2CommParser.setPenStatePenLEDColor(color)
        }
        else {
            penCommParser.setPenStateWithRGB(color)
        }
    }
    
    public func requestSetPenPressure(_ penPressure: UInt16) {
        if isPenSDK2 {
            pen2CommParser.requestSetPenPressure(penPressure)
        }
        else {
            penCommParser.setPenStateWithPenPressure(penPressure)
        }
    }
    
    public func setPenStateWithAutoPwrOffTime(_ minute: UInt16) {
        if isPenSDK2 {
            pen2CommParser.requestSetPenAutoPowerOffTime(minute)
        }
        else {
            penCommParser.setPenStateWithAutoPwrOffTime(minute)
        }
    }
    
    public func setPenStateAutoPower(_ onoff: OnOff) {
        if isPenSDK2 {
            pen2CommParser.requestSetPenAutoPowerOn(onoff)
        }
        else {
            penCommParser.setPenStateAutoPower(onoff)
        }
    }
    
    public func requestSetPenAutoPowerSound(_ onoff: OnOff){
        if isPenSDK2 {
            pen2CommParser.requestSetPenBeep(onoff)
        }
        else {
            penCommParser.requestSetPenAutoPowerSound(onoff)
        }
    }
    
    public func setPenStateWithHover(_ onOff: OnOff) {
        if isPenSDK2 {
            pen2CommParser.requestSetPenHober(onOff)
        }
        else {
            penCommParser.setPenStateWithHover(onOff)
        }
    }
    
    public func setPenStateWithTimeTick() {
        if isPenSDK2 {
            pen2CommParser.requestSetPenTime()
        }
        else {
            penCommParser.setPenStateWithTimeTick()
        }
    }
    
    /// Offline
    public func requestOfflineNoteList(){
        self.pen2CommParser.requestOfflineNoteList()
    }
    
    /// Not support Protocol 1.0
    public func requestOfflinePageList(_ section : UInt8,_ owner : UInt32,_ note: UInt32){
        if isPenSDK2{
            self.pen2CommParser.requestOfflinePageList(section, owner, note)
        }else{
            N.Log("Not support")
        }
    }
    
    public func requestOfflineData(_ section : UInt8,_ owner : UInt32,_ note: UInt32) {
        if isPenSDK2
        {
           pen2CommParser.requestOfflineData(section, owner, note, nil)
        }
        else {
             penCommParser.requestOfflineData(SectionOwner: owner, [note])
        }
    }
    
    public func requestDeleteOfflineData(_ section : UInt8,_ owner : UInt32,_ note: [UInt32]){
        if isPenSDK2{
            pen2CommParser.requestDeleteOfflineData(section, owner, note)
        }
    }
    
    public func setPenThickness(_ thickness: Int) {
        penCommParser.penThickness = thickness
    }
    
    public func setPassword(_ pinNumber: String) {
        if isPenSDK2 {
            pen2CommParser.requestPasswordSDK2(pinNumber)
        }
        else {
            penCommParser.setPassword(pinNumber)
        }
    }
    
    public func requestchangePassword(from curNumber: String, to pinNumber: String) {
        if isPenSDK2 {
            pen2CommParser.requestChangePasswordSDK2From(curNumber, to: pinNumber)
        }
        else {
            penCommParser.changePassword(from: curNumber, to: pinNumber)
        }
    }
    
    public func requestComparePassword(_ pinNumber: String) {
        if isPenSDK2 {
            pen2CommParser.requestComparePasswordSDK2(pinNumber)
        }
        else {
            penCommParser.setBTComparePassword(pinNumber)
        }
    }
    
    public func sendUpdateFileInfoAtUrl(toPen fileUrl: URL) {
        if isPenSDK2 {
//            pen2CommParser.sendUpdateFileInfo2(at: (fileUrl as? URL)!)
        }
        else {
            penCommParser.sendUpdateFileInfoAtUrl(toPen: (fileUrl as? URL)!)
        }
    }
    
    public func setCancelFWUpdate(_ cancelFWUpdate: Bool) {
        if isPenSDK2 {
            pen2CommParser.cancelFWUpdate = cancelFWUpdate
        }else{
            penCommParser.cancelFWUpdate = cancelFWUpdate
        }
    }
    
    /// Offline cancel
    public func setCancelOfflineSync(_ cancelOfflineSync: Bool) {
        if isPenSDK2 {
            pen2CommParser.cancelOfflineSync = cancelOfflineSync
        }else{
            penCommParser.cancelOfflineSync = cancelOfflineSync
        }
    }
    
    public func getPenBattLevelAndMemoryUsedSize() {
        if isPenSDK2 {
            pen2CommParser.requestPenSettingInfo()
        }
        else {
            penCommParser.setPenStateWithTimeTick()
        }
    }

    public func setPenState() {
        if isPenSDK2 {
            pen2CommParser.requestPenSettingInfo()
        }
        else {
            penCommParser.setPenState()
        }
    }
    
    public func requestUsingNote(SectionOwnerNoteList list :[(UInt8,UInt32,UInt32)]) {
        if isPenSDK2 {
//            pen2CommParser.requestUsingNote(list)
        }
        else {
//            penCommParser.setUsingNotes(list[2])
        }
    }
    
    /// Using Note Set
    public func setAllNoteIdList() {
        if isPenSDK2 {
            pen2CommParser.requestUsingAllNote()
        }
        else {
            penCommParser.setAllNoteIdList()
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
    public func requestVersionInfo() {
        stopTimerForVerInfoReq()
        pen2CommParser.requestVersionInfo()
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
                isPenSDK2 = true
                pen2Service = service
                peripheral.discoverCharacteristics(pen2Characteristics, for: service)
            }
            else if service.uuid.isEqual(Pen.NEO_SYSTEM_SERVICE_UUID) {
                systemService = service
                peripheral.discoverCharacteristics(systemCharacteristics, for: service)
            }
            else if service.uuid.isEqual(Pen.NEO_SYSTEM2_SERVICE_UUID) {
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
            else if service.uuid.isEqual(Pen.NEO_OFFLINE2_SERVICE_UUID) {
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
                    else if characteristic.uuid.isEqual(Pen.OFFLINE2_FILE_INFO_UUID) {
                        N.Log("offlineFileInfoUuid")
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                    else if characteristic.uuid.isEqual(Pen.OFFLINE2_FILE_DATA_UUID) {
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
                    if characteristic.uuid.isEqual(Pen.PEN_PASSWORD_REQUEST_UUID) {
                        N.Log("penPasswordRequestUuid")
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                    else if characteristic.uuid.isEqual(Pen.PEN_PASSWORD_RESPONSE_UUID) {
                        N.Log("penPasswordResponseUuid")
                        penPasswordResponseCharacteristic = characteristic
                    }
                    else if characteristic.uuid.isEqual(Pen.PEN_PASSWORD_CHANGE_REQUEST_UUID) {
                        N.Log("penPasswordChangeRequestUuid")
                        penPasswordChangeRequestCharacteristic = characteristic
                    }
                    else if characteristic.uuid.isEqual(Pen.PEN_PASSWORD_CHANGE_RESPONSE_UUID) {
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
                    if characteristic.uuid.isEqual(Pen.OFFLINE2_FILE_INFO_UUID) {
                        N.Log("offlineFileInfoUuid")
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                    else if characteristic.uuid.isEqual(Pen.OFFLINE2_FILE_DATA_UUID) {
                        N.Log("offlineFileDataUuid")
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                    else if characteristic.uuid.isEqual(Pen.OFFLINE2_FILE_LIST_INFO_UUID) {
                        N.Log("offlineFileListInfoUuid")
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                    else if characteristic.uuid.isEqual(Pen.REQUEST_OFFLINE2_FILE_UUID) {
                        N.Log("requestOfflineFileUuid")
                        requestOfflineFileCharacteristic = characteristic
                    }
                    else if characteristic.uuid.isEqual(Pen.OFFLINE2_FILE_STATUS_UUID) {
                        N.Log("offlineFileStatusUuid")
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                    else if characteristic.uuid.isEqual(Pen.OFFLINE2_FILE_ACK_UUID) {
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
        switch characteristic.uuid {
        case Pen2.PEN2_DATA_UUID:
            //N.Log("Received: pen2DataUuid data");
            bt_parsing_dispach_queue.async{
                self.pen2CommParser.parsePen2Data(packet, withLength: dataLength)
            }
        default:
            receiveDataV1(characteristic.uuid, packet)
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
            self.penDelegate?.penBluetooth(.Connect, self.nPen)
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
//            N.Log("Pen2.0 Data Write successful")
            if #available(iOS 9.0, *) {
                MTU = peripheral.maximumWriteValueLength(for: .withoutResponse)
            } else {
                // Fallback on earlier versions
            }
        }else{
            subscribeCharacteristicV1(characteristic)
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

       guard let serviceUUIDs = (advertisementData["kCBAdvDataServiceUUIDs"] as? [CBUUID]) else{
            return
        }

        if !(serviceUUIDs.contains(Pen.NEO_PEN_SERVICE_UUID) || serviceUUIDs.contains(Pen2.NEO_PEN2_SERVICE_UUID)) {
            return
        }
        
        for p in nPens{
            if p.peripheral.isEqual(peripheral){
                return
            }
        }
        let rssi = Int(RSSI)
        
        var tempPen = NPenInfo(peripheral: peripheral, macAddress: "", name: "", subName: "", protocolVersion: "", rssi: rssi)
        
        if  let macAddrObj = advertisementData["kCBAdvDataManufacturerData"]{
            tempPen.macAddress = getMacAddr(fromString: macAddrObj)
        }
//        N.Log("MAC after", tempPen.macAddress)

        if let localName = advertisementData["kCBAdvDataLocalName"] as? String {
            tempPen.name = localName
        }

        nPens.append(tempPen)
        self.penDelegate?.penBluetooth(.Discover, tempPen as AnyObject)
        
        if serviceUUIDs.contains(Pen.NEO_PEN_SERVICE_UUID) {
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
        
        let msg = PenMessage.init(.PEN_DISCONNECTED, data: nil)
        penDelegate?.penMessage(msg)
    
    }
    
}
