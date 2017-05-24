//
//  NJViewController.swift
//  n2sampleSwift
//
//  Created by Aram Moon on 2017. 5. 16..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit
import MessageUI

enum BT_STATUS : Int {
    case DISCONNECTED = 0
    case CONNECTING = 1
    case CONNECTED = 2
    case UNREGISTERED = 3
}

class NJViewController: UIViewController, NJPenStatusDelegate, NJPenPasswordDelegate, NJPenCommParserStartDelegate, NJPenCommParserCommandHandler, NJPenCommManagerNewPeripheral, MFMailComposeViewControllerDelegate {
    
    
    @IBOutlet weak var statusMessage: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progressLabel: UILabel!
    
    
    var isCanvasCloseBtnPressed: Bool = false
    var pageCanvasController: UIViewController?
    
    var pencommManager: NJPenCommManager!
    var btStatus: BT_STATUS = BT_STATUS.UNREGISTERED
    var activeNotebookId: Int = 0
    var activePageNumber: Int = 0
    var cPage: NJPage?
    var timer: Timer?
    var discoveredPeripherals = [Any]()
    var macArray = [Any]()
    var serviceIdArray = [Any]()
    var color: UIColor?
    var useHover: UInt16 = 0
    var isNoteInfoInstalled: Bool = false
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.pencommManager = NJPenCommManager.sharedInstance()
        isCanvasCloseBtnPressed = false
        let menuBtn = UIButton(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(46), height: CGFloat(44)))
        //-20
        menuBtn.setImage(UIImage(named: "btn_Navigation Drawer.png"), for: .normal)
        menuBtn.addTarget(self, action: #selector(self.menuBtnPressed), for: .touchUpInside)
        let menuButtonView = UIView(frame: CGRect(x: CGFloat(0.0), y: CGFloat(0.0), width: CGFloat(46.0), height: CGFloat(44.0)))
        menuButtonView.addSubview(menuBtn)
        
        let revealMenuBarButtonItem = UIBarButtonItem(customView: menuButtonView)
        navigationItem.leftBarButtonItem = revealMenuBarButtonItem
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        
        processStepInstallNewNotebookInfos()
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.writingOnCanvasStart), name: NSNotification.Name(rawValue:"NJPenCommParserPageChangedNotification"), object: nil)
        nc.addObserver(self, selector: #selector(self.btStatusChanged), name: NSNotification.Name(rawValue: "NJPenCommManagerPenConnectionStatusChangeNotification"), object: nil)
        nc.addObserver(self, selector: #selector(self.penPasswordCompareSuccess), name: NSNotification.Name(rawValue: "NJPenCommParserPenPasswordSutupSuccess"), object: nil)
        if (pencommManager.hasPenRegistered) {
            statusMessage.text = "Neo Pen is not connected."
        }
        else {
            statusMessage.text = "Neo Pen is not registered."
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.pencommManager.setPenCommParserStartDelegate(self)
        self.pencommManager.setPenCommParserCommandHandler(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func processStepInstallNewNotebookInfos() {
        if isNoteInfoInstalled {
            isNoteInfoInstalled = true
            return
        }
        progressView.isHidden = false
        progressLabel.isHidden = false
        progressView.progress = 0.0
        DispatchQueue.global(qos: .default).async(execute: {() -> Void in
            let notebookInfos = Bundle.main.paths(forResourcesOfType: "zip", inDirectory: "books_2016_02")
            let tot: Int = notebookInfos.count
            var count: Int = 0
            for path in notebookInfos {
                let fileURL = URL(fileURLWithPath: path )
                let fileNameWithEX: String = (path as AnyObject).lastPathComponent
                let filename : String = (NSURL(fileURLWithPath: fileNameWithEX).deletingPathExtension?.relativePath)!

                    //(path as AnyObject).lastPathComponent.deletingPathExtension
                if !filename.hasPrefix("note_") {
                    continue
                }
                var notebookId: Int = 0
                let tokens: [String] = filename.components(separatedBy: "_")
                var shouldDeleteExisiting: Bool = true
                if tokens.count > 3 || tokens.count < 2 {
                    continue
                }
                if tokens.count == 3 {
                    shouldDeleteExisiting = (Int(tokens[2]) == 0) ? true : false
                    notebookId = Int(tokens[1])!
                }
                else if tokens.count == 2 {
                    notebookId = Int(tokens[1])!
                }
                
                if notebookId <= 0 {
                    continue
                }
                var section: Int = 3
                var owner: Int = 27
                (section,owner) = NJPage.SectionOwner(fromNotebookId: notebookId)
                print("Usenote id \(notebookId)")
                print("Usenote section: + \(section) owner \(owner)" )

                let keyName: String = NPPaperManager.keyName(forNotebookId: UInt(notebookId), section: UInt(section), owner: UInt(owner))
                NPPaperManager.sharedInstance().installNotebookInfo(forKeyName: keyName, zipFilePath: fileURL, deleteExisting: shouldDeleteExisiting)
                DispatchQueue.main.sync(execute: {() -> Void in
                    count += 1
                    let progressValue = Float(count)/Float(tot)
                    self.progressView.setProgress(progressValue, animated: false)
                    if self.progressView.progress == 1.0 {
                        self.progressView.isHidden = true
                        self.progressLabel.isHidden = true
                    }
                })
            }
        })
    }
    
    func setBtStatus(btStatus: BT_STATUS) {
        switch btStatus {
        case .DISCONNECTED:
//            connectButton.setTitle("Connect", for: .normal)
            statusMessage.text = "Neo Pen is not connected."
        case .CONNECTING:
//            connectButton.setTitle("Connecting", for: .normal)
            statusMessage.text = "Scanning Neo Pen."
        case .CONNECTED:
//            connectButton.setTitle("Disconnect", for: .normal)
            let mac: String = pencommManager.regUuid
            let protocolVersion: String = pencommManager.protocolVersion
            let subName: String = pencommManager.subName
            statusMessage.text = "Neo Pen is connected."
            print("mac : \(mac) portocolVersion \(protocolVersion) subName: \(subName) ")
        case .UNREGISTERED:
//            connectButton.setTitle("Register", for: .normal)
            statusMessage.text = "Neo Pen is not registered."
        default:
            break
        }
        self.btStatus = btStatus
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
//    @IBAction func actionButton(_ sender: Any) {
//        let actionSheet = UIActionSheet(title: "Menu", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: "Do something else", otherButtonTitles: "connect", "disconnect")
//        actionSheet.show(from: sender as! UIBarButtonItem, animated: true)
//        if (btStatus == .DISCONNECTED) || (btStatus == .UNREGISTERED) {
//            pencommManager?.btStart()
//            btStatus = .CONNECTING
//        }
//        else if btStatus == .CONNECTED {
//            pencommManager?.disConnect()
//        }
//        
//    }
    
    //MARK: Notification
    func writingOnCanvasStart(notification: Notification) {
        print("writingOnCanvasStart")
        if isCanvasCloseBtnPressed {
            pageCanvasController = nil
            isCanvasCloseBtnPressed = false
        }
        if pageCanvasController == nil {
            print("pageCanvasController present")
//            pageCanvasController = NJPageCanvasController(nibName: nil, bundle: nil)
//            pageCanvasController?.parentController = self
//            pageCanvasController?.activeNotebookId = activeNotebookId
//            pageCanvasController?.activePageNumber = activePageNumber
//            pageCanvasController?.canvasPage = cPage
            if (color != nil) {
//                pageCanvasController?.penColor = convertUIColor(toAlpahRGB: color!)
            }
            pageCanvasController = SimpleViewController(nibName: nil, bundle: nil)
            present(pageCanvasController!, animated: true, completion: nil)
        }
    }
    
    func btStatusChanged(notification: Notification) {
        let penConnctionStatus = notification.userInfo?["info"] as? Int
        checkBtStatus(penConnctionStatus!)
        print("btStatusChanged \(String(describing: notification.userInfo?["info"]))")
    }
    
    func checkBtStatus(_ penConnectionStatus: Int) {
        if penConnectionStatus == NJPenCommManPenConnectionStatus.connected.rawValue{
            btStatus = .CONNECTED
            self.pencommManager.setAllNoteIdList()
        }
        else if penConnectionStatus == NJPenCommManPenConnectionStatus.scanStarted.rawValue{
            btStatus = .CONNECTING
        }
        else {
            if pencommManager.hasPenRegistered {
                btStatus = .DISCONNECTED
            }
            else {
                btStatus = .UNREGISTERED
            }
        }
        
    }
    
    func menuBtnPressed(_ sender: UIBarButtonItem) {
        let alertAction = UIAlertController(title: "Menu", message: nil, preferredStyle: .alert)
        alertAction.popoverPresentationController?.sourceView = self.view
        var firstTitle = pencommManager.hasPenRegistered ? "Connect" :"Register"

        //Connect
        let connectAction = UIAlertAction(title: firstTitle, style: .default, handler: { (UIAlertAction) in
            self.pencommManager.handleNewPeripheral = nil
            self.pencommManager.setPenPasswordDelegate(self)
            self.pencommManager.btStart()
            self.btStatus = .CONNECTING
        })
        alertAction.addAction(connectAction)
        
        //Disconnect
        let disconnectAction = UIAlertAction(title: "Disconnect", style: .destructive, handler: { (UIAlertAction) in
            self.pencommManager.disConnect()
            self.pencommManager.setPenPasswordDelegate(nil)
            self.btStatus = .DISCONNECTED
        })
        alertAction.addAction(disconnectAction)
        
        //Unregster
        let unregistAction = UIAlertAction(title: "Pen Unregistration", style: .destructive, handler: { (UIAlertAction) in
            self.pencommManager.resetPenRegistration()
            self.btStatus = .UNREGISTERED
        })
        alertAction.addAction(unregistAction)
        
        //TODO: Blue Test
        let btAction = UIAlertAction(title: "Bluetooth", style: .default, handler: { (UIAlertAction) in
            let story = UIStoryboard(name: "BTLEStoryboard", bundle: nil)
            let vc = story.instantiateViewController(withIdentifier: "BluetoothController") as! BluetoothController
            self.navigationController?.pushViewController(vc, animated: true)
        })
        alertAction.addAction(btAction)
        
        // Pen Status
        let penStatusAction = UIAlertAction(title: "Pen Status", style: .destructive, handler: { (UIAlertAction) in
            if self.btStatus == .CONNECTED {
                self.pencommManager.setPenStatusDelegate(self)
                self.pencommManager.setPenState()
            }
        })
        alertAction.addAction(penStatusAction)
        
        // Transferable Note ID
        let transferalbeNoteAction = UIAlertAction(title: "Transferable Note ID", style: .destructive, handler: { (UIAlertAction) in
            if self.btStatus == .CONNECTED {
                let notebookId: Int = 610
                let sectionId: Int = 3
                let ownerId: Int = 27
                NPPaperManager.sharedInstance().reqAdd(usingNote: UInt(notebookId), section: UInt(sectionId), owner: UInt(ownerId))
                self.pencommManager.setNoteIdListFromPList()
            }
        })
        alertAction.addAction(transferalbeNoteAction)

        let canvasAction = UIAlertAction(title: "Change canvas Color", style: .destructive, handler: { (UIAlertAction) in
            if self.btStatus == .CONNECTED {
                self.color = UIColor.red
            }
        })
        alertAction.addAction(canvasAction)

        //Pen Tip Color
        let pentipAction = UIAlertAction(title: "Pen Tip Color", style: .destructive, handler: { (UIAlertAction) in
            if self.btStatus == .CONNECTED {
                let penColor: UInt32 = self.convertUIColor(toAlpahRGB: UIColor.blue)
                self.pencommManager.setPenStateWithRGB(penColor)
            }
        })
        alertAction.addAction(pentipAction)
        
        //BT list
        let btlistAction = UIAlertAction(title: "BT List", style: .destructive, handler: { (UIAlertAction) in
            self.pencommManager.handleNewPeripheral = self
            self.pencommManager.setPenPasswordDelegate(self)
            self.pencommManager.btStartForPeripheralsList()
            self.startScanTimer(3.0)
        })
        alertAction.addAction(btlistAction)

        // Battery and Memory
        let batteryMemoryNoteAction = UIAlertAction(title: "Battery Level and Memory Space", style: .destructive, handler: { (UIAlertAction) in
            if self.btStatus == .CONNECTED {
                self.getPenBatteryLevelAndMemoryUsedSpace()
            }
        })
        alertAction.addAction(batteryMemoryNoteAction)

        //BT ID
        let btidAction = UIAlertAction(title: "BT ID", style: .destructive, handler: { (UIAlertAction) in
            let btIDList: [Any] = ["NWP-F110", "NWP-F120"]
            self.pencommManager.setBTIDForPenConnection(btIDList)
        })
        alertAction.addAction(btidAction)

        // Cancel
        let cancel = UIAlertAction(title: "cancel", style: .cancel, handler: nil)
        alertAction.addAction(cancel)
        present(alertAction, animated: false, completion: nil)
    }
    
    func actionSheet(_ actionSheet: UIActionSheet, clickedButtonat buttonIndex: Int) {
        let choice: String = actionSheet.buttonTitle(at: buttonIndex)!
        if buttonIndex == actionSheet.destructiveButtonIndex {
            
        }
        else if (choice == "Connect") || (choice == "Register") {
            pencommManager.handleNewPeripheral = nil
            pencommManager.setPenPasswordDelegate(self)
            pencommManager.btStart()
            btStatus = .CONNECTING
        }
        else if (choice == "Disconnect") {
            pencommManager.disConnect()
            pencommManager.setPenPasswordDelegate(nil)
            btStatus = .DISCONNECTED
        }
        else if (choice == "Pen Unregistration") {
            pencommManager.resetPenRegistration()
            btStatus = .UNREGISTERED
        }
        else if (choice == "Setting") {
            if btStatus == .CONNECTED {
                pencommManager.setPenStatusDelegate(self)
                let penInfoViewController = NJPenInfoViewController(nibName: nil, bundle: nil)
                navigationController?.pushViewController(penInfoViewController, animated: false)
            }
        }
        else if (choice == "OfflineData list") {
//            if btStatus == .CONNECTED {
//                let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
//                let offlineSyncViewController: NJOfflineSyncViewController = mainStoryboard.instantiateViewController(withIdentifier: "OffSyncVC") as! NJOfflineSyncViewController
//                offlineSyncViewController.isShowOfflineFileList = true
//                navigationController?.pushViewController(offlineSyncViewController, animated: false)
//            }
        }
        else if (choice == "Show OfflineData") {
//            if btStatus == .CONNECTED {
//                var mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
//                var offlineSyncViewController: NJOfflineSyncViewController = mainStoryboard.instantiateViewController(withIdentifier: "OffSyncVC") as! NJOfflineSyncViewController
//                offlineSyncViewController.isShowOfflineFileList = false
//                offlineSyncViewController.parentController = self
//                navigationController?.pushViewController(offlineSyncViewController, animated: false)
//            }
        }
        else if (choice == "Pen Firmware Update") {
//            if btStatus == .CONNECTED {
//                var mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
//                var fwUpdateViewController: NJFWUpdateViewController = mainStoryboard.instantiateViewController(withIdentifier: "FWUpdateVC") as! NJFWUpdateViewController
//                navigationController?.pushViewController(fwUpdateViewController, animated: false)
//            }
        }
    }
    
    func startScanTimer(_ duration: CGFloat) {
        if timer == nil {
            timer = Timer(timeInterval: TimeInterval(duration), target: self, selector: #selector(self.discoveredPeripheralsAndConnect), userInfo: nil, repeats: false)
            RunLoop.main.add(timer!, forMode: .defaultRunLoopMode)
        }
    }
    
    func stopScanTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func discoveredPeripheralsAndConnect() {
        var foundPeripheral: CBPeripheral?
        var penName: String
        stopScanTimer()
        print("discoveredPeripheralsAndConnect")
        discoveredPeripherals = pencommManager.discoveredPeripherals as! [Any]
        macArray = pencommManager.macArray as! [Any]
        serviceIdArray = pencommManager.serviceIdArray as! [Any]
        if discoveredPeripherals.count > 0 {
            //example, if index 0 of discoveredPeripherals should be connected
            let index: Int = 0
            var serviceUUID: String = ""
            if serviceIdArray.count > 0 {
                serviceUUID = (serviceIdArray[0] as? String)!
            }
            // 1.try macAddr first
            foundPeripheral = discoveredPeripherals[0] as! CBPeripheral
            penName = (foundPeripheral?.name)!
            if (serviceUUID == "19F0") || (serviceUUID == "19F1") {
                print("Pen SDK2.0")
            }
            else {
                print("Pen SDK1.0")
            }
            pencommManager.connectPeripheral(at: index)
        }
    }
    
    func connectionResult(_ success: Bool) {
        pencommManager.btStop()
        if success {
            print("Pen connection success")
        }
        else {
            print("Pen connection failure or pen disconnection")
        }
    }
    
    func penStatusData(_ data: UnsafeMutablePointer<PenStateStruct>!) {
        print("penStatusData :")
    }
    
    func penStatusData(penStatus: PenStateStruct) {
        NSLog("viewController penstatus")
        NSLog("penStatus \(penStatus.penStatus), timezoneOffset \(penStatus.timezoneOffset), timeTick \(penStatus.timeTick)")
        NSLog("pressureMax \(penStatus.pressureMax), battery \(penStatus.battLevel), memory \(penStatus.memoryUsed)")
        NSLog("autoPwrOffTime \(penStatus.autoPwrOffTime), penPressure \(penStatus.penPressure)")
        let timeInMiliseconds: TimeInterval = Date().timeIntervalSince1970 * 1000
        let localTimeZone = NSTimeZone.local
        let millisecondsFromGMT: Int = localTimeZone.secondsFromGMT() * 1000 + Int(localTimeZone.daylightSavingTimeOffset()) * 1000
        if pencommManager.isPenSDK2 {
            if (fabs(Double(penStatus.timeTick - UInt64(timeInMiliseconds))) > 2000) {
                pencommManager.setPenStateWithTimeTick()
            }
        }
        else {
            if (fabs(Double(penStatus.timeTick - UInt64(timeInMiliseconds))) > 2000) || ( penStatus.timezoneOffset != Int32(millisecondsFromGMT)) {
                pencommManager.setPenStateWithTimeTick()
            }
        }
        var penAutoPower: Bool = true
        var penSound: Bool = true
        if pencommManager.isPenSDK2 {
            if penStatus.usePenTipOnOff == 1 {
                penAutoPower = true
            }
            else if penStatus.usePenTipOnOff == 0 {
                penAutoPower = false
            }
            
            if penStatus.beepOnOff == 1 {
                penSound = true
            }
            else if penStatus.beepOnOff == 0 {
                penSound = false
            }
        }
        else {
            if penStatus.usePenTipOnOff == 1 {
                penAutoPower = true
            }
            else if penStatus.usePenTipOnOff == 2 {
                penAutoPower = false
            }
            
            if penStatus.beepOnOff == 1 {
                penSound = true
            }
            else if penStatus.beepOnOff == 2 {
                penSound = false
            }
        }
        
        var defaults = UserDefaults.standard
        var savedPenAutoPower: Bool = defaults.bool(forKey: "penAutoPower")
        if penAutoPower != savedPenAutoPower {
            defaults.set(penAutoPower, forKey: "penAutoPower")
            defaults.synchronize()
        }
        var savedPenSound: Bool = defaults.bool(forKey: "penSound")
        if penSound != savedPenSound {
            defaults.set(penSound, forKey: "penSound")
            defaults.synchronize()
        }
        var penPressure = Int(penStatus.penPressure)
        var savedPenPressure = defaults.object(forKey: "penPressure") as! Int
        if savedPenPressure != penPressure {
            defaults.set(penPressure, forKey: "penPressure")
            defaults.synchronize()
        }
        var autoPwrOff = Int(penStatus.autoPwrOffTime)
        var savedAutoPwrOff = defaults.object(forKey: "autoPwrOff") as! Int
        if savedAutoPwrOff != autoPwrOff {
            defaults.set(autoPwrOff, forKey: "autoPwrOff")
            defaults.synchronize()
        }
        if pencommManager.isPenSDK2 {
            if (penStatus.battLevel & 0x80) == 0x80 {
                if (penStatus.battLevel & 0x7f) == 100 {
                    print("Battery is fully charged")
                }
                print("Battery is being charged")
                return
            }
        }
        
    }
    
    func getPenBatteryLevelAndMemoryUsedSpace() {
        pencommManager.getPenBattLevelAndMemoryUsedSize({(_ remainedBattery: UInt8, _ usedMemory: UInt8) -> Void in
            let battery: UInt8 = remainedBattery
            let memory: UInt8 = 100 - usedMemory
            print("Battery Remainder: \(battery), Unused Memory Space: \(memory)")
        })
    }
    
    //NJPenPasswordDelegate
    func penPasswordRequest(_ data: UnsafeMutablePointer<PenPasswordRequestStruct>!) {

        let request : PenPasswordRequestStruct = PenPasswordRequestStruct()//data as PenPasswordRequestStruct
        var password: String = MyFunctions.loadPasswd()
        let resetCount = Int(request.resetCount)
        let retryCount = Int(request.retryCount)
        let count: Int = resetCount - retryCount
        if count <= 1 {
            // last attempt was failed we delete registration and disconnect pen
            pencommManager.setBTComparePassword("0000")
            pencommManager.resetPenRegistration()
            DispatchQueue.main.async(execute: {() -> Void in
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: NJPenCommParserPenPasswordValidationFail), object: nil, userInfo: nil)
            })
            return
        }
        if (password == "") {
            password = "0000"
            MyFunctions.saveIntoKeyChain(withPasswd: password)
            pencommManager.setBTComparePassword(password)
        }
        else {
            if request.retryCount == 0 {
                pencommManager.setBTComparePassword(password)
            }
            else {
                let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let inputPasswordViewController: NJInputPasswordViewController? = mainStoryboard.instantiateViewController(withIdentifier: "inputPWVC") as! NJInputPasswordViewController
                present(inputPasswordViewController!, animated: true, completion: { _ in })
            }
        }
    }

    
    func penPasswordCompareSuccess(_ notification: Notification) {
        print("setBTComparePassword success")
    }
    
    func convertUIColor(toAlpahRGB color: UIColor) -> UInt32 {
        let components: [CGFloat] = color.cgColor.components!
        print("Red: \(components[0])")
        print("Green: \(components[1])")
        print("Blue: \(components[2])")
        print("Alpha: \(color.cgColor.alpha)")
        let colorRed: CGFloat = components[0]
        let colorGreen: CGFloat = components[1]
        let colorBlue: CGFloat = components[2]
        let colorAlpah: CGFloat = 1.0
        let alpah = UInt32(colorAlpah * 255) & 0x000000ff
        let red = UInt32(colorRed * 255) & 0x000000ff
        let green = UInt32(colorGreen * 255) & 0x000000ff
        let blue = UInt32(colorBlue * 255) & 0x000000ff
        let penColor: UInt32 = (alpah << 24) | (red << 16) | (green << 8) | blue
        return penColor
    }

    //NJPenCommParserStartDelegate
    
    func activeNoteId(forFirstStroke noteId: Int32, pageNum pageNumber: Int32, sectionId section: Int32, ownderId owner: Int32) {
        print("NJPenCommParserStartDelegate")
    }
    
    func activeNoteIdForFirstStroke(noteId: Int, pageNumber: Int, sectionId section: Int, owner: Int) {
        print("noteID:\(noteId), page number:\(pageNumber), sectionId:\(section), ownerId:\(owner)")
        activeNotebookId = noteId
        activePageNumber = pageNumber
        cPage = NJPage(notebookId: noteId, andPageNumber: pageNumber)
    }
    
    func setPenCommNoteIdList() {
        let notebookId: Int = 625
        let sectionId: Int = 3
        let ownerId: Int = 27
        NPPaperManager.sharedInstance().reqAdd(usingNote: UInt(notebookId), section: UInt(sectionId), owner: UInt(ownerId))
        NJPenCommManager.sharedInstance().setNoteIdListFromPList()
    }
    
    //NJPenCommParserCommandHandler
    func findApplicableSymbols(param: String, action: String, andName name: String) {
        //NSLog(@"param:%@, action:%@, name:%@",param, action, name);
    }
    
    func sendEmailWithPdf() {
        if MFMailComposeViewController.canSendMail() {
            let mc = MFMailComposeViewController()
            mc.mailComposeDelegate = self
            mc.setSubject("iOS SDK sample")
            mc.setMessageBody("<h>Created with <a href='http://www.neosmartpen.com'>Neo smartpen</a> and sent from <a href='http://www.neosmartpen.com'>iOS Sample App</a> </h>", isHTML: true)
            DispatchQueue.main.async(execute: {() -> Void in
                self.dismiss(animated: true, completion: {() -> Void in
                    self.present(mc, animated: true, completion: { _ in })
                })
            })
        }
    }
    
    func penConnected(byOtherApp penConnected: Bool) {
        if penConnected {
            let alert = UIAlertController(title: "", message: "Your pen has been connected by the one of other apps. Please disconnect it from the app and please try again", preferredStyle: .alert)
            
            let OKAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) in
                NSLog("Connected")
            }
            alert.addAction(OKAction)
            
            self.present(alert, animated: true, completion:nil)

        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result {
        case .cancelled:
            print("Mail cancelled")
        case .saved:
            print("Mail saved")
        case .sent:
            print("Mail sent")
        case .failed:
            print("Mail sent failure: \(String(describing: error?.localizedDescription))")
        default:
            break
        }
        
        dismiss(animated: true, completion: {() -> Void in
            self.isCanvasCloseBtnPressed = true
            NJPenCommManager.sharedInstance().penCommParser.shouldSendPageChangeNotification = true
        })
    }
}



