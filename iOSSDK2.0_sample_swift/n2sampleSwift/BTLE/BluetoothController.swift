//
//  BluetoothController.swift
//  n2sampleSwift
//
//  Created by Aram Moon on 2017. 5. 18..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation
import CoreBluetooth

class BluetoothController: UIViewController, CBCentralManagerDelegate, UITableViewDelegate, CBPeripheralDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableview: UITableView!
    
    var centralManager : CBCentralManager!
    
    let PENCOMM_SERVICE_UUID = CBUUID(string: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961")
    let PENCOMM_READ_CHARACTERISTIC_UUID = CBUUID(string:"08590F7E-DB05-467E-8757-72F6FAEB13D4")
    let PENCOMM_WRITE_CHARACTERISTIC_UUID = CBUUID(string:"C0C0C0C0-DEAD-F154-1319-740381000000")
    
    var ad : [[String: Any]] = [[:]]
    var peripherals :[CBPeripheral] = []
    var ConnectedPerriperal :CBPeripheral?
    
    override func viewDidLoad() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        tableview.delegate = self
        tableview.dataSource = self
        supportedService.append(NEO_PEN2_SERVICE_UUID)
        supportedService.append(NEO_PEN2_SYSTEM_SERVICE_UUID)
        supportedService.append(NEO_PEN_SERVICE_UUID)
        supportedService.append(NEO_SYSTEM_SERVICE_UUID)
        supportedService.append(NEO_OFFLINE_SERVICE_UUID)
        supportedService.append(NEO_OFFLINE2_SERVICE_UUID)
        supportedService.append(NEO_UPDATE_SERVICE_UUID)
        supportedService.append(NEO_DEVICE_INFO_SERVICE_UUID)
        supportedService.append(NEO_SYSTEM2_SERVICE_UUID)

    }
    
    @IBAction func Scan(_ sender: Any) {
        print("SCAN start!!")
        let servviceuuid =  PENCOMM_SERVICE_UUID
        let servviceuuidn = NEO_PEN_SERVICE_UUID
        peripherals.removeAll()
        ad.removeAll()
        centralManager.scanForPeripherals(withServices: [servviceuuid,servviceuuidn], options: nil)
    }
    
    @IBAction func ScanStop(_ sender: Any) {
        print("SCAN stop!!")
        centralManager.stopScan()
    }
    
    @IBAction func disconnect(_ sender: Any) {
        
    }
    
    @IBAction func ScanService(_ sender: Any) {
        print("ScanService")
        if let perri = self.ConnectedPerriperal{
            print("ScanService start....")
            scanService(periperal: perri)
        }
    }
    
    @IBAction func DiscoverCharacter(_ sender: Any) {
        if let perri = self.ConnectedPerriperal{
            print("DiscoverCharacter start....")
            if let services = perri.services{
                for ser in services{
                    if ser.uuid.isEqual(NEO_PEN_SERVICE_UUID){
                        perri.discoverCharacteristics([STROKE_DATA_UUID,UPDOWN_DATA_UUID,ID_DATA_UUID], for: ser)
                    }else if ser.uuid.isEqual(NEO_PEN2_SYSTEM_SERVICE_UUID){
                        perri.discoverCharacteristics([PEN2_SET_DATA_UUID,PEN2_DATA_UUID], for: ser)
                    }
                }
            }
        }
        
    }
    
    //MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager){
        print("State: \(central.state)")
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        print("peripheral: \(peripheral) rss:  \(RSSI)")
        print("ad: \(advertisementData)")
        peripherals.append(peripheral)
        ad.append(advertisementData)
        //        if(Int(RSSI) > -15){
        //            print("Connect")
        //            self.centralManager.connect(peripheral, options: nil)
        //        }
        DispatchQueue.main.async() {
            self.tableview.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell  = UITableViewCell(style: .subtitle, reuseIdentifier: "Mycell")
        print("Update table \(indexPath.row)")
        cell.textLabel?.text = "NONE"
        if indexPath.row > ad.count - 1{
            return cell
        }
        if let title = ad[indexPath.row]["kCBAdvDataManufacturerData"] as? NSData{
            let data = String(describing:title)
//            print("bluetooth macaddress: \(data)")
            cell.textLabel?.text = data
            cell.detailTextLabel?.text = peripherals[indexPath.row].name
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return ad.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        print("select table \(indexPath.row)")
        if(peripherals.isEmpty) {
            return
        }
        if indexPath.row > peripherals.count {
            return
        }
        print("Connecting .....")
        let peripheral = peripherals[indexPath.row]
        self.centralManager.connect(peripheral, options: nil)
    }
    
    
    //성공시
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("연결 성공 \(peripheral)")
        ConnectedPerriperal =  peripheral
    }
    
    //실패시
    @objc(centralManager:didFailToConnectPeripheral:error:) func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("연결 실패 \(error)")
    }
    
    //
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?){
        print("dixconnect \(peripheral) error: \(String(describing: error))")
    }
    
    /* Pen2.0 Service UUID */
    let NEO_PEN2_SERVICE_UUID = CBUUID(string: "19F1")
    let NEO_PEN2_SYSTEM_SERVICE_UUID = CBUUID(string:"19F0")
    let PEN2_DATA_UUID = CBUUID(string:"2BA1")
    let PEN2_SET_DATA_UUID = CBUUID(string:"2BA0")
    /* Pen Service UUID */
    let NEO_PEN_SERVICE_UUID = CBUUID(string:"18F1")
    let STROKE_DATA_UUID = CBUUID(string:"2AA0")
    let ID_DATA_UUID = CBUUID(string:"2AA1")
    let UPDOWN_DATA_UUID = CBUUID(string:"2AA2")
    let SET_RTC_UUID = CBUUID(string:"2AB1")
    /* OFFLINE Data Service UUID
     */
    let NEO_OFFLINE_SERVICE_UUID = CBUUID(string:"18F2")
    let REQUEST_OFFLINE_FILE_LIST_UUID = CBUUID(string:"2AC1")
    let OFFLINE_FILE_LIST_UUID = CBUUID(string: "2AC2")
    let REQUEST_DEL_OFFLINE_FILE_UUID = CBUUID(string:"2AC3")
    /* OFFLINE2 Data Service UUID*/
    let NEO_OFFLINE2_SERVICE_UUID = CBUUID(string:"18F3")
    let REQUEST_OFFLINE2_FILE_UUID = CBUUID(string:"2AC7")
    let OFFLINE2_FILE_LIST_INFO_UUID = CBUUID(string:"2AC8")
    let OFFLINE2_FILE_INFO_UUID = CBUUID(string:"2AC9")
    let OFFLINE2_FILE_DATA_UUID = CBUUID(string:"2ACA")
    let OFFLINE2_FILE_ACK_UUID = CBUUID(string:"2ACB")
    let OFFLINE2_FILE_STATUS_UUID = CBUUID(string:"2ACC")
    /* Update Service UUID */
    let NEO_UPDATE_SERVICE_UUID = CBUUID(string:"18F4")
    let UPDATE_FILE_INFO_UUID = CBUUID(string:"2AD1")
    let REQUEST_UPDATE_FILE_UUID = CBUUID(string:"2AD2")
    let UPDATE_FILE_DATA_UUID = CBUUID(string:"2AD3")
    let UPDATE_FILE_STATUS_UUID = CBUUID(string:"2AD4")
    /* System Service UUID
     */
    let NEO_SYSTEM_SERVICE_UUID = CBUUID(string:"18F5")
    let PEN_STATE_UUID = CBUUID(string:"2AB0")
    let SET_PEN_STATE_UUID = CBUUID(string:"2AB1")
    let SET_NOTE_ID_LIST_UUID = CBUUID(string:"2AB2")
    let REQUEST_CALIBRATION_UUID  = CBUUID(string: "2AB3")
    let READY_EXCHANGE_DATA_UUID = CBUUID(string:"2AB4")
    let READY_EXCHANGE_DATA_REQUEST_UUID = CBUUID(string:"2AB5")
    /* System2 Service UUID
     */
    let NEO_SYSTEM2_SERVICE_UUID = CBUUID(string:"18F6")
    let PEN_PASSWORD_REQUEST_UUID = CBUUID(string:"2AB7")
    let PEN_PASSWORD_RESPONSE_UUID = CBUUID(string:"2AB8")
    let PEN_PASSWORD_CHANGE_REQUEST_UUID = CBUUID(string:"2AB9")
    let PEN_PASSWORD_CHANGE_RESPONSE_UUID = CBUUID(string:"2ABA")
    /* device information Service UUID
     */
    let NEO_DEVICE_INFO_SERVICE_UUID = CBUUID(string:"180A")
    let FW_VERSION_UUID = CBUUID(string:"2A26")
    
    var supportedService :[CBUUID] = []

    func scanService(periperal: CBPeripheral){
        periperal.delegate = self
        periperal.discoverServices(supportedService)
    }
    
    func peripheral(_ periperal: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = periperal.services else {
            print("오류")
            return
        }
        print("\(services.count) 개의 서비스를 발견함! \(services)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            print("\(characteristics.count)개의 캐릭터리스틱을 발견함. \(characteristics)")
            for ch in service.characteristics!{
                peripheral.setNotifyValue(true, for: ch)
            }
        }

        if service.isEqual(NEO_PEN2_SERVICE_UUID){
            print("set neo pen2 service")

        }else if service.isEqual(NEO_PEN_SERVICE_UUID){
            print("set neo pen service")
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        print("characteristic \(characteristic) ")
    }

}
