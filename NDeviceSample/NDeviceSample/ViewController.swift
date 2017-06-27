//
//  ViewController.swift
//  NDeviceSample
//
//  Created by Aram Moon on 2017. 6. 26..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import UIKit
import CoreBluetooth
import NDeviceSDK

class ViewController: UIViewController {

    var device: DeviceController! = nil
    var deviceList: [CBPeripheral] = []
    @IBOutlet weak var tableView: UITableView!

    var autoConnect = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        device = DeviceController.sharedInstance
    }
    
    override func viewWillAppear(_ animated: Bool) {
        device.setDelegate(self)
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func Scan(_ sender: Any) {
        deviceList.removeAll()
        device.scan(durationTime: 3.0)
    }
    
    @IBAction func Stop(_ sender: Any) {
        device.scanStop()
    }

    @IBAction func AutoConn(_ sender: Any) {
        deviceList.removeAll()
        autoConnect = true
        device.scan(durationTime: 3.0)
    }
    
    @IBAction func Remote(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "RemoteController") as! RemoteController
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
}
extension CBPeripheralState{
    func simpleDescription()-> String{
        switch self {
        case .connected:
            return "connected"
        case .connecting:
            return "connecting"
        case .disconnected:
            return "disconnected"
        case .disconnecting:
            return "disconnecting"
        }
    }
}
extension ViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return deviceList.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let height: CGFloat = 80
        return height
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell : UITableViewCell
        cell = UITableViewCell(style: .subtitle, reuseIdentifier: "deviceInfo")
        cell.textLabel?.text = deviceList[indexPath.row].name
        cell.detailTextLabel?.text = String(describing: deviceList[indexPath.row].state.simpleDescription())
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        print("touch")
        if deviceList[indexPath.row].state == .connected{
            deviceList.removeAll()
            device.disConnect()
            tableView.reloadData()
        }else if deviceList[indexPath.row].state == .disconnected{
            device.connectPeripheral(deviceList[indexPath.row])
        }
    }

}

extension ViewController: DeviceDelegate{
    func deviceMessage(_ msg: DeviceMessage){
        guard let type = msg.messageType else{
            print("Mssage Type Error")
            return
        }
        switch type {
        case .Autorize:
            DispatchQueue.main.async {
                print("Autorized")
                self.tableView.reloadData()
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let viewController = storyboard.instantiateViewController(withIdentifier: "RemoteController") as! RemoteController
                self.navigationController?.pushViewController(viewController, animated: true)
            }
        case .Contents:
            print("Need to Change contents updata", msg.data)
        case .PowerOff:
            print("device power off")
            device.disConnect()
            DispatchQueue.main.async {
                self.deviceList.removeAll()
                self.tableView.reloadData()
            }
        }
    }
    
    func bluetoothStatus(_ status: BTStatus, _ peripheral: CBPeripheral?){
        switch status {
        case .Discover:
            if let per = peripheral{
                DispatchQueue.main.async {
                    self.deviceList.append(per)
                    print("discover beam", peripheral?.name ?? "No name")
                    self.tableView.reloadData()
                }

            }
        case .StopScan:
            print("End Scan")
            if autoConnect{
                connectFirstDiscover()
            }
        case .Connect:
            print("Connected Beam")
        case .ScanStart:
            print("Start Scan")
        default:
            print(device)

        }
    }
    
    func connectFirstDiscover(){
        if deviceList.count > 0{
            device.connectPeripheral(deviceList[0])
        }
    }
}
