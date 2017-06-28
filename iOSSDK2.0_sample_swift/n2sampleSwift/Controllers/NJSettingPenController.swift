//
//  NJSettingPenController.swift
//  n2sampleSwift
//
//  Created by Aram Moon on 2017. 5. 25..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation

class NJSettingPenController: UITableViewController {

    var menuList:  [String]  = []
    var detail :[String] = []
    
    var isPenConnected: Bool = false
    
    var pencommManager: NJPenCommManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        let tempImageView = UIImageView(image: UIImage(named: "bg_settings.png"))
        tempImageView.frame = (tableView?.frame)!
        tableView?.backgroundView = tempImageView
        
        pencommManager = NJPenCommManager.sharedInstance()

        self.isEditing = false
        menuList = ["Change Password", "Auto Power","Shutdown Timer","Sound","Pen Sensor Pressure Tuning"]
        detail = ["Password", "Power on Automatically","Save battery without using pen", "Alarm in a new event or warning"
            , "Pen Pressure Cal Descript"]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView?.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func shouldShowMiniCanvas() -> Bool {
        return false
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let height: CGFloat = 80
        return height
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell : UITableViewCell
        cell = UITableViewCell(style: .subtitle, reuseIdentifier: "SettingInfocell")
        cell.textLabel?.text = menuList[indexPath.row]
        cell.detailTextLabel?.text = detail[indexPath.row]
        
        cell.textLabel?.textColor = UIColor.white
        cell.backgroundColor = UIColor.clear

        cell.detailTextLabel?.numberOfLines = 3
        cell.textLabel?.highlightedTextColor = UIColor.black
        cell.detailTextLabel?.textColor = UIColor.lightText
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: CGFloat(12.0))
        cell.selectionStyle = ((indexPath.row % 2) == 1) ? .none : .default
            
        if indexPath.row == 1 {
            pSwitch = UISwitch(frame: CGRect(x: 0, y: 0, width: 100, height: 80))
            cell.accessoryView = pSwitch
            pSwitch?.addTarget(self, action: #selector(self.pSwitchAction) , for: .valueChanged)
            pSwitch?.setOn(UserDefaults.standard.bool(forKey: "penAutoPower")
, animated: true)
        }
        else if indexPath.row == 3 {
            dSwitch = UISwitch(frame: CGRect(x: 0, y: 0, width: 100, height: 80))
            dSwitch?.addTarget(self, action: #selector(self.dSwitchAction) , for: .valueChanged)
            cell.accessoryView = dSwitch
            dSwitch?.setOn(UserDefaults.standard.bool(forKey: "penSound")
                , animated: true)
        }
        else {
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
    
    override func tableView(_
        tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == 0 {
            let mainStoryboard = UIStoryboard(name: "MainSwift", bundle: nil)
            let changePasswordViewController = mainStoryboard.instantiateViewController(withIdentifier: "changePWVC") as! NJChangePasswordViewController
            navigationController?.pushViewController(changePasswordViewController, animated: true)
        }
        else if indexPath.row == 2 {
            let mainStoryboard = UIStoryboard(name: "MainSwift", bundle: nil)
            let penAutoPwrOffTimeViewController = mainStoryboard.instantiateViewController(withIdentifier: "NNPowerOffTimeController") as! NNPowerOffTimeController
            self.navigationController?.pushViewController(penAutoPwrOffTimeViewController, animated: false)
        }
        else if indexPath.row == 4 {
            let mainStoryboard = UIStoryboard(name: "MainSwift", bundle: nil)
            let penSensor = mainStoryboard.instantiateViewController(withIdentifier: "NNSensorController") as! NNSensorController
            self.navigationController?.pushViewController(penSensor, animated: false)
        }
        
    }
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHeader = "Setting"
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat(self.view.bounds.size.width), height: 24))
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.white
        label.text = sectionHeader
        label.textAlignment = .center
        label.font = label.font.withSize(CGFloat(21.0))
        return label
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    var pSwitch : UISwitch?
    var dSwitch : UISwitch?
    
    let ON = 1
    let OFF = 2
    func pSwitchAction(_ sender: Any) {
        let defaults = UserDefaults.standard
        var penAutoPower: Bool
        let penConnected: Bool = NJPenCommManager.sharedInstance().isPenConnected
        let penRegister: Bool = NJPenCommManager.sharedInstance().hasPenRegistered
        if !penConnected || !penRegister {
            return
        }
        if (sender as AnyObject).isOn {
            penAutoPower = true
            defaults.set(penAutoPower, forKey: "penAutoPower")
            defaults.synchronize()
        }
        else {
            penAutoPower = false
            defaults.set(penAutoPower, forKey: "penAutoPower")
            defaults.synchronize()
        }
        var pAutoPwer: UInt8 = UInt8(penAutoPower ? ON : OFF)
        var pSound: UInt8
        if !NJPenCommManager.sharedInstance().isPenSDK2 {
            let penSound: Bool = defaults.bool(forKey: "penSound")
            pSound = UInt8(penSound ? ON : OFF)
        }
        else {
            pAutoPwer = penAutoPower ? 0 : 1
            pSound = 0xff
        }
        NJPenCommManager.sharedInstance().setPenStateAutoPower(pAutoPwer, sound: pSound)
        return
    }
    
    func dSwitchAction(_ sender: Any) {
        let defaults = UserDefaults.standard
        var penSound: Bool
        let penConnected: Bool = NJPenCommManager.sharedInstance().isPenConnected
        let penRegister: Bool = NJPenCommManager.sharedInstance().hasPenRegistered
        if !penConnected || !penRegister {
            return
        }
        if (sender as AnyObject).isOn {
            penSound = true
            defaults.set(penSound, forKey: "penSound")
            defaults.synchronize()
        }
        else {
            penSound = false
            defaults.set(penSound, forKey: "penSound")
            defaults.synchronize()
        }
        var pSound: UInt8 = UInt8(penSound ? ON : OFF)
        var pAutoPwer: UInt8
        if !NJPenCommManager.sharedInstance().isPenSDK2 {
            let penAutoPower: Bool = defaults.bool(forKey: "penAutoPower")
            pAutoPwer = UInt8(penAutoPower ? ON : OFF)
        }
        else {
            pAutoPwer = 0xff
            pSound = penSound ? 0 : 1
            
        }
        NJPenCommManager.sharedInstance().setPenStateAutoPower(pAutoPwer, sound: pSound)
    }
    
    func startStopAdvertizing(_ sender: Any) {
        
    }
}
