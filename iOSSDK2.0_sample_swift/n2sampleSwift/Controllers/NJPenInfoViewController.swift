//
//  NJPenInfoViewController.swift
//  n2sampleSwift
//
//  Created by Aram Moon on 2017. 5. 16..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation
import UIKit


//class NJPenInfoCustomTableViewCell:  UITableViewCell {
//    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}

class NJPenInfoViewController :UITableViewController{
    /*
    let kViewTag = 1
    let kAlertViewPenInfo = 3
    private var kSectionTitleKey: String = "sectionTitleKey"
    private var kRow1LabelKey: String = "row1LabelKey"
    private var kRow2LabelKey: String = "row2LabelKey"
    private var kRow3LabelKey: String = "row3LabelKey"
    private var kRow4LabelKey: String = "row4LabelKey"
    private var kRow5LabelKey: String = "row5LabelKey"
    private var kRow1DetailLabelKey: String = "row1DetailLabelKey"
    private var kRow2DetailLabelKey: String = "row2DetailLabelKey"
    private var kRow1SourceKey: String = "row1SourceKey"
    private var kRow2SourceKey: String = "row2SourceKey"
    private var kRow3SourceKey: String = "row3SourceKey"
    private var kRow4SourceKey: String = "row4SourceKey"
    private var kRow1ViewKey: String = "row1ViewKey"
    private var kRow2ViewKey: String = "row2ViewKey"
    private var kRow3ViewKey: String = "row3ViewKey"
    private var kViewController1Key: String = "viewController1"
    private var kViewController2Key: String = "viewController2"
    private var kViewController3Key: String = "viewController3"
    private var kSwitchCellId: String = "SwitchCell"
    private var kControlCellId: String = "ControlCell"
    private var kDisplayCellId: String = "DisplayCell"
    private var kSourceCellId: String = "SourceCell"
    
    var menuList = [String :String]()
    
    var isPenConnected: Bool = false
    
    var pencommManager: NJPenCommManager?
    
    
    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: Bundle!) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        // Custom initialization
        tableView = UITableView()
        let tempImageView = UIImageView(image: UIImage(named: "bg_settings.png"))
        tempImageView.frame = (tableView?.frame)!
        tableView?.backgroundView = tempImageView
        tableView?.delegate = self
        tableView?.dataSource = self
        tableView?.separatorStyle = .singleLine
        tableView?.separatorInset = UIEdgeInsets.zero//UIEdgeInsetsZero
        tableView?.separatorColor = UIColor(patternImage: UIImage(named: "line_navidrawer.png")!)
        let defaults = UserDefaults.standard
        defaults.synchronize()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        pencommManager = NJPenCommManager.sharedInstance()
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        //back
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        navigationController?.navigationBar.layer.mask = roundedCornerNavigationBar()
        // Do any additional setup after loading the view.
        menuList = [String: String]()
        self.isEditing = false
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let changePasswordViewController: NJChangePasswordViewController? = mainStoryboard.instantiateViewController(withIdentifier: "changePWVC") as? NJChangePasswordViewController
        let penAutoPwrOffTimeViewController = NJPenAutoPwrOffTimeViewController(nibName: nil, bundle: nil)
        let penSensorCalViewController = NJPenSensorCalViewController(nibName: nil, bundle: nil)
        menuList = [kSectionTitleKey: "Setting"
            ,kRow1LabelKey:"Change Password"
            ,kRow2LabelKey: "Auto Power"
            , kRow3LabelKey: "Shutdown Timer"
            , kRow4LabelKey: "Sound"
            , kRow5LabelKey: "Pen Sensor Pressure Tuning"
            , kRow1SourceKey: "Power on Automatically"
            , kRow2SourceKey: "Save battery without using pen"
            , kRow3SourceKey: "Alarm in a new event or warning"
            , kRow4SourceKey: "Pen Pressure Cal Descript"
            , kRow1ViewKey: "p Switch" //pSwitchCtl()
            , kRow2ViewKey: "d Switch" //dSwitchCtl()
            , kViewController1Key: "changePasswordViewController"
            , kViewController2Key: "penAutoPwrOffTimeViewController"
            , kViewController3Key: "penSensorCalViewController"]
//        tableView.tableFooter = UIView(frame: CGRect.zero)
        tableView?.frame = view.bounds
        
        
        
        view.addSubview(tableView!)
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
    
    func roundedCornerNavigationBar() -> CAShapeLayer {
        let maskPath = UIBezierPath(roundedRect: (navigationController?.navigationBar.bounds)!, byRoundingCorners: ([.topLeft, .topRight]), cornerRadii: CGSize(width: CGFloat(5.0), height: CGFloat(5.0)))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = (navigationController?.navigationBar.bounds)!
        maskLayer.path = maskPath.cgPath
        return maskLayer
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UITableViewDelegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        return menuList.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height: CGFloat
        if indexPath.row == 0 {
            height = 54.5
        }
        else {
            height = 74.5
        }
        return height
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> NJPenInfoCustomTableViewCell {
        var cell: NJPenInfoCustomTableViewCell? = nil
        if indexPath.row == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: kControlCellId) as! NJPenInfoCustomTableViewCell
            if cell == nil {
                cell = NJPenInfoCustomTableViewCell(style: .value1, reuseIdentifier: kControlCellId)
            }
            let kRowLabelKey: String = "row\(Int(indexPath.row + 1))LabelKey"
            cell?.textLabel?.text = menuList[kRowLabelKey]
            cell?.textLabel?.textColor = UIColor.white
            cell?.backgroundColor = UIColor.clear
            cell?.accessoryType = .disclosureIndicator
            cell?.selectionStyle = .none
        }
        else {
            cell = tableView.dequeueReusableCell(withIdentifier: kSwitchCellId) as! NJPenInfoCustomTableViewCell
            if cell == nil {
                cell = NJPenInfoCustomTableViewCell(style: .subtitle, reuseIdentifier: kSwitchCellId)
            }
            let kTitleKey: String = "row\(Int(indexPath.row + 1))LabelKey"
            cell?.textLabel?.text = menuList[kTitleKey]
            cell?.textLabel?.textColor = UIColor.white
            cell?.detailTextLabel?.textColor = UIColor(red: CGFloat(190 / 255.0), green: CGFloat(190 / 255.0), blue: CGFloat(190 / 255.0), alpha: CGFloat(1))
            cell?.detailTextLabel?.numberOfLines = 3
            cell?.textLabel?.highlightedTextColor = UIColor.black
            cell?.detailTextLabel?.font = UIFont.systemFont(ofSize: CGFloat(12.0))
            let kSourceKey: String = "row\(Int(indexPath.row))SourceKey"
            cell?.detailTextLabel?.text = menuList[kSourceKey]
            cell?.backgroundColor = UIColor.clear
            cell?.selectionStyle = .none
            var kViewKey: String
            if indexPath.row == 1 {
                kViewKey = "row\(Int(indexPath.row))ViewKey"
            }
            else if indexPath.row == 3 {
                kViewKey = "row\(Int(indexPath.row - 1))ViewKey"
            }
            else if (indexPath.row == 2) || (indexPath.row == 4) {
                cell?.accessoryType = .disclosureIndicator
                
            }
            
            //TODO
//            let control: UIControl? = menuList[kViewKey] as? UIControl
//            var newFrame: CGRect? = control?.frame
//            newFrame?.origin.x = (cell?.contentView.frame.width)! - (newFrame?.width)! - 15.0
//            control?.frame = newFrame!
//            control?.autoresizingMask = .flexibleLeftMargin
//            cell?.contentView.addSubview(control!)
        }
        return cell!
    }
    
    override func tableView(_
        tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let kViewControllerKey: String = "viewController\(Int(indexPath.row + 1))"
            let targetViewController: UIViewController? = menuList[kViewControllerKey] as? UIViewController
            navigationController?.pushViewController(targetViewController!, animated: true)
            tableView.deselectRow(at: indexPath, animated: true)
        }
        else if indexPath.row == 2 {
            let kViewControllerKey: String = "viewController\(Int(indexPath.row))"
            let targetViewController: UIViewController? = menuList[kViewControllerKey] as? UIViewController
            navigationController?.pushViewController(targetViewController!, animated: true)
            tableView.deselectRow(at: indexPath, animated: true)
        }
        else if indexPath.row == 4 {
            let kViewControllerKey: String = "viewController\(Int(indexPath.row - 1))"
            let targetViewController: UIViewController? = menuList[kViewControllerKey] as? UIViewController
            navigationController?.pushViewController(targetViewController!, animated: true)
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
    }
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHeader: String? = menuList[kSectionTitleKey]
        let view = UIView(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(self.view.bounds.size.width), height: CGFloat(24)))
        let label = UILabel(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(self.view.bounds.size.width), height: CGFloat(24)))
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.white
        label.text = sectionHeader
        label.textAlignment = .center
        label.font = label.font.withSize(CGFloat(21.0))
        let separatorLowerLineView = UIView(frame: CGRect(x: CGFloat(0), y: CGFloat(40), width: CGFloat(self.view.bounds.size.width), height: CGFloat(0.5)))
        separatorLowerLineView.backgroundColor = UIColor(patternImage: UIImage(named: "line_navidrawer.png")!)
        view.addSubview(separatorLowerLineView)
        view.addSubview(label)
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    var pSwitch : UISwitch?
    
    func pSwitchCtl() -> UISwitch {
        if pSwitch == nil {
            let defaults = UserDefaults.standard
            let frame = CGRect(x: CGFloat(239.0), y: CGFloat(12.0), width: CGFloat(66.0), height: CGFloat(32.0))
            pSwitch = UISwitch(frame: frame)
            pSwitch?.addTarget(self, action: #selector(self.switchAction), for: .valueChanged)
            // in case the parent view draws with a custom color or gradient, use a transparent color
            let penAutoPower: Bool = defaults.bool(forKey: "penAutoPower")
            if penAutoPower {
                pSwitch?.isOn = true
            }
            else {
                pSwitch?.isOn = false
            }
            pSwitch?.backgroundColor = UIColor.clear
            pSwitch?.tag = kViewTag
        }
        return pSwitch!
    }
    var dSwitch : UISwitch?

    func dSwitchCtl() -> UISwitch {
        if dSwitch == nil {
            let defaults = UserDefaults.standard
            let frame = CGRect(x: CGFloat(239.0), y: CGFloat(12.0), width: CGFloat(66.0), height: CGFloat(32.0))
            dSwitch = UISwitch(frame: frame)
            dSwitch?.addTarget(self, action: #selector(self.dSwitchAction), for: .valueChanged)
            // in case the parent view draws with a custom color or gradient, use a transparent color
            dSwitch?.backgroundColor = UIColor.clear
            let penSound: Bool = defaults.bool(forKey: "penSound")
            if penSound {
                dSwitch?.isOn = true
            }
            else {
                dSwitch?.isOn = false
            }
            dSwitch?.tag = kViewTag
        }
        return dSwitch!
    }
    
    let ON = 1
    let OFF = 2
    func switchAction(_ sender: Any) {
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
            pSwitchCtl().isOn = true
        }
        else {
            penAutoPower = false
            defaults.set(penAutoPower, forKey: "penAutoPower")
            defaults.synchronize()
            pSwitchCtl().isOn = false
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
            dSwitchCtl().isOn = true
        }
        else {
            penSound = false
            defaults.set(penSound, forKey: "penSound")
            defaults.synchronize()
            dSwitchCtl().isOn = false
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
        return
    }
    
    func startStopAdvertizing(_ sender: Any) {
    }
    */
}
