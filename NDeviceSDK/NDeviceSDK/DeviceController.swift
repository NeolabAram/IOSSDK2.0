//
//  DeviceController.swift
//  NDeviceSDK
//
//  Created by Aram Moon on 2017. 6. 26..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation
import CoreBluetooth


/// Device Controller for Neolab Device.
public class DeviceController: NSObject {
    
    //MARK: - Init Device Controller -
    ///Device Data Handling
    public static let sharedInstance = DeviceController()
    weak var deviceDelegate: DeviceDelegate?
    var dataParser: DataParser!

    //Bluetooth LE
    var centralManager: CBCentralManager!
    var btStatus: BTStatus = .None
    private var timer: Timer?
    private var verInfoTimer: Timer?

    
    //Service UUID
    let NEO_PEN2_SERVICE_UUID = CBUUID(string :"19F1" )
    let NEO_PEN2_SYSTEM_SERVICE_UUID = CBUUID(string :"19F0")
    
    ///CharaCharacteristic UUID
    let PEN2_DATA_UUID = CBUUID(string :"2BA1")
    let PEN2_SET_DATA_UUID = CBUUID(string :"2BA0")
    
    var deviceService: CBService?
    var deviceCharacteristics: [CBUUID] = []
    var pen2SetDataCharacteristic: CBCharacteristic?
    var peripheral: CBPeripheral?
    
    var bt_write_dispatch_queue: DispatchQueue!
    var bt_parsing_dispach_queue: DispatchQueue!

    
    var MTU = 20 //Maximum Transmission Unit
    
    private override init() {
        super.init()
        bt_write_dispatch_queue = DispatchQueue(label: "bt_write_dispatch_queue")
        bt_parsing_dispach_queue = DispatchQueue(label: "data_paser_dispach_queue")
        
        centralManager = CBCentralManager(delegate: self, queue: (DispatchQueue(label: "kr.neolab.penBT")), options: [CBCentralManagerOptionShowPowerAlertKey: true])
        deviceCharacteristics = [PEN2_DATA_UUID,PEN2_SET_DATA_UUID]

        dataParser = DataParser()
    }
    
    /// If you want callback, Need to Set Delegate
    public func setDelegate(_ delegate: DeviceDelegate) {
        self.deviceDelegate = delegate
        dataParser?.deviceDelegate = delegate
    }
    
    /// DeviceSDK Log Hide ann show.
    public func showLog(_ flag : Bool){
        N.isDebug = flag
    }
    
    //MARK: - Public Bluetooth -
    /// Scan for peripherals - specifically for our service's 128bit CBUUID
    /// if time = 0 default scan Time
    public func scan(durationTime second : CGFloat) {
        N.Log("Scanning started")
        centralManager.stopScan()
        btStatus = .ScanStart
        centralManager.scanForPeripherals(withServices: [NEO_PEN2_SERVICE_UUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        if !second.isZero{
            startScanTimer(second)
        }
    }
    
    /// scanStop call after scan time of can use maually
    public func scanStop() {
        timer = nil
        if centralManager.state == .poweredOn {
            if btStatus == .ScanStart {
                centralManager.stopScan()
                N.Log("stop scanning")
                btStatus = .StopScan
                deviceDelegate?.bluetoothStatus(btStatus, nil)
            }
        }
    }
    
    /// Connect Device
    public func connectPeripheral(_ peripheral: CBPeripheral) {
        N.Log("Connecting to peripheral \(String(describing: peripheral))")
        centralManager.connect(peripheral, options: nil)
    }
    
    /// Disconnect current connected peripheral.
    public func disConnect() {
        // Give some time to pen, before actual disconnect.
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double((Int64)(500 * NSEC_PER_MSEC)) / Double(NSEC_PER_SEC), execute: {() -> Void in
            self.disConnectInternal()
        })
    }
    
    private func disConnectInternal() {
        N.Log("disconnect current peripheral \(String(describing: peripheral))")
        cleanup()
        btStatus = .Disconnect
        deviceDelegate?.bluetoothStatus(btStatus, peripheral)
    }
    
    
    //MARK: - private Bluetooth -
    private func startScanTimer(_ duration: CGFloat) {
        if timer == nil {
            timer = Timer(timeInterval: TimeInterval(duration), target: self, selector: #selector(self.scanStop), userInfo: nil, repeats: false)
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
    
    /// Call this when things either go wrong, or you're done with the connection.
    /// This cancels any subscriptions if there are any, or straight disconnects if not.
    /// (didUpdateNotificationStateForCharacteristic will cancel the connection if a subscription is involved)
    func cleanup() {
        N.Log("[PenCommMan] cleanup()")
        // Don't do anything if we're not connected
        if peripheral?.state != .connected {
            return
        }
        // See if we are subscribed to a characteristic on the peripheral
        if let services = peripheral?.services {
            for services in services {
                if let characteristics = services.characteristics {
                    for characteristic in characteristics{
                        if characteristic.isNotifying {
                            // It is notifying, so unsubscribe
                            peripheral?.setNotifyValue(false, for: characteristic)
                            // And we're done.
                            btStatus = .Disconnect
                            return
                        }
                        
                    }
                }
            }
        }
        // If we've got this far, we're connected, but we're not subscribed,
        // so we just disconnect
        if let peri = peripheral{
            centralManager.cancelPeripheralConnection(peri)
        }
    }
    
    //MARK: - Write to Pen
    func writeDataToDevice(_ data: Data) {
        bt_write_dispatch_queue.async {
            if let per = self.peripheral, let character = self.pen2SetDataCharacteristic{
                per.writeValue(data, for: character, type: .withResponse)
            }else{
                N.Log("peripheral or pen2SetDataCharacteristic is nil")
            }
        }
    }
    
    
    // MARK: - Public API
    /// Remotcontroller Event
    public func requestPlayerEvent(_ playType: PlayType) {
        var request = REQ_Player.init()
        request.playType = playType
        request.playData = 0
        let data = request.toUInt8Array().toData()
        writeDataToDevice(data)
    }
    
    /// Direct Play Contents List
    public func requestDirectPlay(_ mainId:UInt16, _ subId: UInt16, _ contentsId: UInt16){
        var request = REQ_Player.init()
        request.playType = .DirectPlay
        request.playData = (UInt64(mainId) << 32) + (UInt64(subId) << 16) + UInt64(contentsId)
        let data = request.toUInt8Array().toData()
        writeDataToDevice(data)
    }
    
    /// Request modified Contents
    public func requestSyncContents(){
        let request = REQ_SyncContents()
        let data = request.toUInt8Array().toData()
        writeDataToDevice(data)
    }
    
    /// Device version Infomation
    public func requestVersionInfo(){
        let request = REQ_VersionInfo()
        let data = request.toUInt8Array().toData()
        writeDataToDevice(data)
    }
    
}

extension DeviceController: CBPeripheralDelegate {
    
    // MARK: - CBPeripheralDelegate -
    /// Step1. After connected, discoverCharacteristics.
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
            if service.uuid.isEqual(NEO_PEN2_SERVICE_UUID) {
                deviceService = service
                peripheral.discoverCharacteristics(deviceCharacteristics, for: service)
            }
        }
    }

    /// Step2. After discovered Service(discoverCharacteristics),setNotify Characteristic.
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
        if service == deviceService {
            // Again, we loop through the array, just in case.
            for characteristic: CBCharacteristic in characters {
                // And check if it's the right one
                if deviceCharacteristics.contains(characteristic.uuid) {
                    if characteristic.uuid.isEqual(PEN2_DATA_UUID) {
                        //NSLog(@"pen2DataUuid");
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                    else if characteristic.uuid.isEqual(PEN2_SET_DATA_UUID) {
                        N.Log("pen2SetDataUuid", characteristic )
                        pen2SetDataCharacteristic = characteristic
                        let msg = DeviceMessage.init(.Autorize, data: nil)
                        deviceDelegate?.deviceMessage(msg)
//                        startTimerForVerInfoReq()
                    }
                }
                else {
                    N.Log("Unknown characteristic \(service.uuid) for service \(characteristic.uuid)")
                }
            }
        }
        // Once this is complete, we just need to wait for the data to come in.
    }
    /// Step3. After setNotify.
    /// This callback lets us know more data has arrived via notification on the characteristic
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            N.Log("Error discovering characteristics: \(String(describing: error?.localizedDescription))")
            return
        }
        guard let received_data = characteristic.value else {
            N.Log("Data is empty")
            return
        }
        
        let packet = [UInt8](received_data)
        //        N.Log("Pen Data", packet[1], CMD(rawValue: packet[1]))
        switch characteristic.uuid {
        case PEN2_DATA_UUID:
            bt_parsing_dispach_queue.async{
                self.dataParser.parseData(packet)
            }
        default:
            N.Log("UnKnow characteristic", characteristic.uuid)
        }
    }
    
    /// The peripheral letting us know whether our subscribe/unsubscribe happened or not
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            N.Log("Error changing notification state: \(String(describing: error?.localizedDescription)) characteristic : \(characteristic.uuid)")
        }
        // Notification has started
        if characteristic.isNotifying {
            N.Log("Notification began on \(characteristic)")
//            self.deviceDelegate?.bluetoothStatus(.Connect, peripheral)
        }
        else {
            // so disconnect from the peripheral
            N.Log("Notification stopped on \(characteristic).  Disconnecting")
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    /// Callback after writting data for device
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            N.Log("Error WriteValueForCharacteristic: \(String(describing: error?.localizedDescription)) characteristic : \(characteristic.uuid)")
            return
        }
        if characteristic == pen2SetDataCharacteristic {
            if #available(iOS 9.0, *) {
                MTU = peripheral.maximumWriteValueLength(for: .withoutResponse)
//                N.Log("MTU",MTU)
            } else {
                // Fallback on earlier versions
            }
        }
    }
}

extension DeviceController: CBCentralManagerDelegate {
    // MARK: - CBCentralManagerDelegate -
    
    /// centralManagerDidUpdateState is a required protocol method.
    ///  Usually, you'd check for other states to make sure the current device supports LE, is powered on, etc.
    ///  In this instance, we're just using it to wait for CBCentralManagerStatePoweredOn, which indicates
    ///  the Central is ready to be used.
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
    
    /// Scanning... Discover Device
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // Reject any where the value is above reasonable range
        if Int(RSSI) > -15 {
            //            N.Log("Too Strong \(String(describing: peripheral.name)) at \(RSSI)")
            return
        }
        guard let serviceUUIDs = (advertisementData["kCBAdvDataServiceUUIDs"] as? [CBUUID]) else{
            return
        }
        
        if !(serviceUUIDs.contains(NEO_PEN2_SERVICE_UUID)) {
            return
        }

        let macAddrObj = advertisementData["kCBAdvDataManufacturerData"] ?? ""
        let localName = advertisementData["kCBAdvDataLocalName"] as? String ?? ""
        N.Log("MACADDRESS and local Name" ,getMacAddr(fromString: macAddrObj), localName)

        if localName.contains("BEAM"){
            deviceDelegate?.bluetoothStatus(.Discover, peripheral)
        }
    }
    
    /// If the connection fails for whatever reason, we need to deal with it.
    private func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) throws {
        N.Log("Failed to connect to \(peripheral). (\(String(describing: error?.localizedDescription)))")
        cleanup()
        btStatus = .Disconnect
        deviceDelegate?.bluetoothStatus(btStatus, peripheral)
    }
    
    /// We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([NEO_PEN2_SERVICE_UUID,NEO_PEN2_SYSTEM_SERVICE_UUID])
        self.peripheral = peripheral
        btStatus = .Connect
        deviceDelegate?.bluetoothStatus(btStatus, peripheral)
    }
    
    /// The Service was discovered
    /// Once the disconnection happens, we need to clean up our local copy of the peripheral
    private func centralManager(_ central: CBCentralManager, didDisconnect peripheral: CBPeripheral, error: Error?) throws {
        N.Log("Peripheral Disconnected")
        self.peripheral = nil
        btStatus = .Disconnect
        deviceDelegate?.bluetoothStatus(btStatus, peripheral)
        
    }
    
}
