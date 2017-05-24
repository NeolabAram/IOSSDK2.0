//
//  NJPenAutoPwrOffTimeViewController.swift
//  n2sampleSwift
//
//  Created by Aram Moon on 2017. 5. 16..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation
import UIKit


class NJPenAutoPwrOffTimeViewController :UIViewController { //, UITableViewDataSource, UITableViewDelegate {
    /*
    let kPwrOffTime1 = 10
    let kPwrOffTime2 = 20
    let kPwrOffTime3 = 40
    let kPwrOffTime4 = 60
    private var kSectionTitleKey: String = "sectionTitleKey"
    private var kSourceKey: String = "sourceKey"
    private var kRow1LabelKey: String = "row1LabelKey"
    private var kRow2LabelKey: String = "row2LabelKey"
    private var kRow3LabelKey: String = "row3LabelKey"
    private var kRow4LabelKey: String = "row4LabelKey"
    private var kCheckCellID: String = "kCheckCellID"
    private var kSourceCellID: String = "SourceCellID"
    
    var tableView: UITableView?
    var menuList = [Any]()
    var lastIndexPath: IndexPath?
    
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
        tableView?.separatorInset = UIEdgeInsetsZero
        tableView?.separatorColor = UIColor(patternImage: UIImage(named: "line_navidrawer.png")!)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        navigationController?.navigationBar?.setBackgroundImage(UIImage(), for: UIBarMetricsDefault)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.translucent = true
        menuList = [Any]()
        isEditing = false
        tableView.tableFooter = UIView(frame: CGRect.zero)
        tableView?.frame = view.bounds
        view.addSubview(tableView!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if menuList.count {
            menuList.removeAll()
        }
        menuList.append([kSectionTitleKey: NSLocalizedString("Shutdown Timer", comment: ""), kSourceKey: NSLocalizedString("If setting time is long, usable time of the is shorter.", comment: ""), kRow1LabelKey: NSLocalizedString("10 minutes", comment: ""), kRow2LabelKey: NSLocalizedString("20 minutes", comment: ""), kRow3LabelKey: NSLocalizedString("40 minutes", comment: ""), kRow4LabelKey: NSLocalizedString("60 minutes", comment: "")])
        tableView?.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        setAutoPwrOffTime()
        super.viewWillDisappear(animated)
    }
    
    func shouldShowMiniCanvas() -> Bool {
        return false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return menuList.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }

    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (indexPath.row == 4) ? 65.0 : 54.5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = nil
        if indexPath.row == 4 {
            cell = tableView.dequeueReusableCell(withIdentifier: kSourceCellID)
            if cell == nil {
                cell = UITableViewCell(style: .value1, reuseIdentifier: kSourceCellID)
            }
            cell?.selectionStyle = []
            cell?.textLabel?.textAlignment = .center
            cell?.textLabel?.textColor = UIColor(red: CGFloat(190 / 255.0), green: CGFloat(190 / 255.0), blue: CGFloat(190 / 255.0), alpha: CGFloat(1))
            cell?.textLabel?.numberOfLines = 3
            cell?.backgroundColor = UIColor.clear
            cell?.textLabel?.highlightedTextColor = UIColor.black
            cell?.textLabel?.font = UIFont.systemFont(ofSize: CGFloat(12.0))
            cell?.textLabel?.text = (menuList[0] as AnyObject).value(forKey: kSourceKey)
        }
        else {
            cell = tableView.dequeueReusableCell(withIdentifier: kCheckCellID)
            if cell == nil {
                cell = UITableViewCell(style: .value1, reuseIdentifier: kCheckCellID)
            }
            let kLabelKey: String = "row\(Int(indexPath.row) + 1)LabelKey"
            cell?.textLabel?.text = menuList[0][kLabelKey]
            cell?.textLabel?.textColor = UIColor.white
            cell?.backgroundColor = UIColor.clear
            let defaults = UserDefaults.standard
            let nAutoPwrOff = defaults.object(forKey: "autoPwrOff")
            let autoPwrOff: UInt16 = CInt(nAutoPwrOff)
            var index: Int
            switch autoPwrOff {
            case kPwrOffTime1:
                index = 0
            case kPwrOffTime2:
                index = 1
            case kPwrOffTime3:
                index = 2
            case kPwrOffTime4:
                index = 3
            default:
                index = 1
            }
            
            if indexPath.row == index {
                lastIndexPath = indexPath
                cell?.accessoryType = .checkmark
            }
            else {
                cell?.accessoryType = []
            }
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if lastIndexPath?.row != indexPath.row {
            let newCell: UITableViewCell? = tableView.cellForRow(at: indexPath)
            newCell?.accessoryType = .checkmark
            let oldCell: UITableViewCell? = tableView.cellForRow(at: lastIndexPath!)
            oldCell?.accessoryType = []
            lastIndexPath = indexPath
        }
        else {
            let newCell: UITableViewCell? = tableView.cellForRow(at: indexPath)
            newCell?.accessoryType = .checkmark
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHeader: String? = ((menuList[section] as? String)?[kSectionTitleKey] as? String)
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
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func setAutoPwrOffTime() {
        var autoPwrOff: UInt16
        switch lastIndexPath?.row {
        case 0:
            autoPwrOff = UInt16(kPwrOffTime1)
        case 1:
            autoPwrOff = UInt16(kPwrOffTime2)
        case 2:
            autoPwrOff = UInt16(kPwrOffTime3)
        case 3:
            autoPwrOff = UInt16(kPwrOffTime4)
        default:
            autoPwrOff = UInt16(kPwrOffTime2)
        }
        
        NJPenCommManager.sharedInstance().setPenStateWithAutoPwrOffTime(autoPwrOff)
        let defaults = UserDefaults.standard
        defaults.set(Int(autoPwrOff), forKey: "autoPwrOff")
        defaults.synchronize()
    }
    */
}
