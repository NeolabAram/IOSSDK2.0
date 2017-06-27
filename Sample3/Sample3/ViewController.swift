//
//  ViewController.swift
//  Sample3
//
//  Created by Aram Moon on 2017. 5. 31..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import UIKit
import NISDK3
import CoreBluetooth


class ViewController: UIViewController {


    let pen = NISDK3.PenController.sharedInstance
    
    var Penstatus: PenStatus = PenStatus.None
    
    var penList: [NPenInfo] = []
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setDelegate()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - EXAMPLE -
    @IBAction func showPenDemo(_ sender: Any) {
        
        let alertAction = UIAlertController(title: "Menu", message: nil, preferredStyle: .alert)
        alertAction.popoverPresentationController?.sourceView = self.view
        
        //Connect
        let connectAction = UIAlertAction(title: "Connect" , style: .default, handler: { (UIAlertAction) in
            self.pen.autoConnection()
            print("Auto Connetction")
        })
        alertAction.addAction(connectAction)
        
        
        //SCAN
        let scan = UIAlertAction(title: "ScanStart", style: .destructive, handler: { (UIAlertAction) in
            self.penList.removeAll()
            self.pen.scan(durationTime: 5.0)
            print("Start Scan")

        })
        alertAction.addAction(scan)
        
        //SCAN Stop
        let scanStop = UIAlertAction(title: "ScanStop", style: .destructive, handler: { (UIAlertAction) in
            self.pen.scan(durationTime: 5.0)
            print("Start Scan")
            
        })
        alertAction.addAction(scanStop)
        
        
        if self.Penstatus == .Connect {
            
            //Disconnect
            let disconnectAction = UIAlertAction(title: "Disconnect", style: .destructive, handler: { (UIAlertAction) in
                self.pen.disConnect()
            })
            alertAction.addAction(disconnectAction)
            
            
            //Setting
            let settingAction = UIAlertAction(title: "Setting Pen", style: .destructive, handler: { (UIAlertAction) in
//                if self.btStatus == .CONNECTED {
//                    self.pencommManager.setPenStatusDelegate(self)
//                    let mainStoryboard = UIStoryboard(name: "MainSwift", bundle: nil)
//                    let penInfoViewController = mainStoryboard.instantiateViewController(withIdentifier: "NJSettingPenController") as! NJSettingPenController
//                    self.navigationController?.pushViewController(penInfoViewController, animated: false)
//                }
            })
            alertAction.addAction(settingAction)
            
            //Offline Note List
            let offlineNoteListAction = UIAlertAction(title: "Offline Note list", style: .destructive, handler: { (UIAlertAction) in
                self.pen.requestOfflineNoteList()
                //                if self.btStatus == .CONNECTED {
//                    let mainStoryboard = UIStoryboard(name: "MainSwift", bundle: nil)
//                    let offlineSyncViewController: NJOfflineSyncViewController = mainStoryboard.instantiateViewController(withIdentifier: "OffSyncVC") as! NJOfflineSyncViewController
//                    self.navigationController?.pushViewController(offlineSyncViewController, animated: false)
//                }
            })
            alertAction.addAction(offlineNoteListAction)
            
            //Offline Page List
            let offlinePageListAction = UIAlertAction(title: "Offline Page list", style: .destructive, handler: { (UIAlertAction) in
                self.pen.requestOfflinePageList(3, 27, 601)

            })
            alertAction.addAction(offlinePageListAction)
            
            //Offline data
            let offlineDataAction = UIAlertAction(title: "Offline Data", style: .destructive, handler: { (UIAlertAction) in
                self.pen.requestOfflineData(3, 27, 601)
            })
            alertAction.addAction(offlineDataAction)
            
            
            //Offline data
            let offlineDeleteAction = UIAlertAction(title: "Offline Delete", style: .destructive, handler: { (UIAlertAction) in
                self.pen.requestDeleteOfflineData(3, 27, [601,602])
                
            })
            alertAction.addAction(offlineDeleteAction)
            
            // pen Firmaware Update
            let firmwareUpdateAction = UIAlertAction(title: "Pen Firmware Update", style: .destructive, handler: { (UIAlertAction) in
//                if self.btStatus == .CONNECTED {
//                    let mainStoryboard = UIStoryboard(name: "MainSwift", bundle: nil)
//                    let fwUpdateViewController = mainStoryboard.instantiateViewController(withIdentifier: "FWUpdateVC") as! NJFWUpdateViewController
//                    self.navigationController?.pushViewController(fwUpdateViewController, animated: false)
//                }
            })
            alertAction.addAction(firmwareUpdateAction)
            
            // Pen Status
            let penStatusAction = UIAlertAction(title: "Pen Status", style: .destructive, handler: { (UIAlertAction) in
//                if self.btStatus == .CONNECTED {
//                    self.pencommManager.setPenStatusDelegate(self)
//                    self.pencommManager.setPenState()
//                }
            })
            
            alertAction.addAction(penStatusAction)
            
            // Transferable Note ID
            let transferalbeNoteAction = UIAlertAction(title: "Transferable Note ID", style: .destructive, handler: { (UIAlertAction) in
//                if self.btStatus == .CONNECTED {
//                    let notebookId: Int = 610
//                    let sectionId: Int = 3
//                    let ownerId: Int = 27
//                    NPPaperManager.sharedInstance().reqAdd(usingNote: UInt(notebookId), section: UInt(sectionId), owner: UInt(ownerId))
//                    self.pencommManager.setNoteIdListFromPList()
//                }
            })
            alertAction.addAction(transferalbeNoteAction)
            
            let canvasAction = UIAlertAction(title: "Change canvas Color", style: .destructive, handler: { (UIAlertAction) in
//                if self.btStatus == .CONNECTED {
//                    self.color = UIColor.red
//                }
            })
            alertAction.addAction(canvasAction)
            
            //Pen Tip Color
            let pentipAction = UIAlertAction(title: "Pen Tip Color", style: .destructive, handler: { (UIAlertAction) in
//                if self.btStatus == .CONNECTED {
//                    let penColor: UInt32 = self.convertUIColor(toAlpahRGB: UIColor.blue)
//                    self.pencommManager.setPenStateWithRGB(penColor)
//                }
            })
            alertAction.addAction(pentipAction)
            
            // Battery and Memory
            let batteryMemoryNoteAction = UIAlertAction(title: "Battery Level and Memory Space", style: .destructive, handler: { (UIAlertAction) in
//                if self.btStatus == .CONNECTED {
//                    self.getPenBatteryLevelAndMemoryUsedSpace()
//                }
            })
            alertAction.addAction(batteryMemoryNoteAction)
            }
        
        // Cancel
        let cancel = UIAlertAction(title: "cancel", style: .cancel, handler: nil)
        alertAction.addAction(cancel)
        present(alertAction, animated: false, completion: nil)
    }
    
    var firstDot = false

}

extension ViewController: PenDelegate {
    
    func setDelegate(){
        self.pen.setPenDelegate(self)
    }
    
    //MARK: - DeviceDelegate - 
    func penData(_ type: DotType, _ data: Any?) {
        switch type {
        case .UpDown:
            if let updown = data as? PenUpDown{
                if updown.upDown == .Down{
                    firstDot = true
                }
            }
        case .Type1:
            if firstDot {
                print(data as Any)
                firstDot = false
            }
        default:
            print(type, data as Any)

        }
    }

    
    func penMessage(_ msg: PenMessage) {
        guard let type = msg.messageType else{
            return
        }
        switch type {
        case .PEN_STATUS:
            print("pen msg", type, msg.data as Any)

        default:
            print("pen msg", type, msg.data as Any)
        }
    }
    
    func penBluetooth(_ status: PenStatus, _ data: Any?) {
        print(status, data as Any)
        self.Penstatus = status
        switch self.Penstatus {
        case .Discover:
            if let dev = data as? NPenInfo{
                self.penList.append(dev)
            }
            break
        case .Connect:
            self.view.setNeedsDisplay()
            self.pen.setAllNoteIdList()
        case .Disconnect:
            self.view.setNeedsDisplay()
            break
        case .None:
            break
        case .ScanStart:
            break
        }

    }
    
}

