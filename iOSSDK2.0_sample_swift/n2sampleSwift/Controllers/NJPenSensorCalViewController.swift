//
//  NJPenSensorCalViewController.swift
//  n2sampleSwift
//
//  Created by Aram Moon on 2017. 5. 16..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation
import UIKit

class NJPenSensorCalViewController : UIViewController { //, UITableViewDataSource, UITableViewDelegate {

    /*
     
     let kPenPressureValue1 = 4
     let kPenPressureValue2 = 3
     let kPenPressureValue3 = 2
     let kPenPressureValue4 = 1
     let kPenPressureValue5 = 0
     private var kSectionTitleKey: String = "sectionTitleKey"
     private var kSourceKey: String = "sourceKey"
     private var kRow1LabelKey: String = "row1LabelKey"
     private var kRow2LabelKey: String = "row2LabelKey"
     private var kRow3LabelKey: String = "row3LabelKey"
     private var kRow4LabelKey: String = "row4LabelKey"
     private var kRow5LabelKey: String = "row5LabelKey"
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
        navigationController?.navigationBar?.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        //back
        navigationController?.navigationBar?.setBackgroundImage(UIImage(), for: UIBarMetricsDefault)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.translucent = true
        menuList = [Any]()
        isEditing = false
        tableView.tableFooter = UIView(frame: CGRect.zero)
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: kCheckCellID)
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: kSourceCellID)
        tableView?.frame = view.bounds
        view.addSubview(tableView!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if menuList.count {
            menuList.removeAll()
        }
        menuList.append([kSectionTitleKey: NSLocalizedString("Pen Sensor Pressure Tuning", comment: ""), kSourceKey: NSLocalizedString("Pen pressure is more insensitive as close as level 1.", comment: ""), kRow1LabelKey: NSLocalizedString("Level 1", comment: ""), kRow2LabelKey: NSLocalizedString("Level 2", comment: ""), kRow3LabelKey: NSLocalizedString("Level 3", comment: ""), kRow4LabelKey: NSLocalizedString("Level 4", comment: ""), kRow5LabelKey: NSLocalizedString("Level 5 (The most sensitive)", comment: "")])
        tableView?.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        setPenPressureCalibration()
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
        return 6
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (indexPath.row == 5) ? 65.0 : 54.5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = nil
        if indexPath.row == 5 {
            cell = tableView.dequeueReusableCell(withIdentifier: kSourceCellID, for: indexPath)
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
            cell = tableView.dequeueReusableCell(withIdentifier: kCheckCellID, for: indexPath)
            let kLabelKey: String = "row\(Int(indexPath.row + 1))LabelKey"
            cell?.textLabel?.text = menuList[0][kLabelKey]
            cell?.textLabel?.textColor = UIColor.white
            cell?.backgroundColor = UIColor.clear
            let defaults = UserDefaults.standard
            let nPenPressure = defaults.object(forKey: "penPressure")
            let penPressure: UInt16 = CInt(nPenPressure)
            var index: Int
            switch penPressure {
            case kPenPressureValue1:
                index = 0
            case kPenPressureValue2:
                index = 1
            case kPenPressureValue3:
                index = 2
            case kPenPressureValue4:
                index = 3
            case kPenPressureValue5:
                index = 4
            default:
                index = 4
            }
            
            if indexPath.row == index {
                lastIndexPath = indexPath
                cell.accessoryType = .checkmark
            }
            else {
                cell.accessoryType = []
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row != 5 {
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

    func setPenPressureCalibration() {
        var penPressure: UInt16
        switch lastIndexPath?.row {
        case 0:
            penPressure = kPenPressureValue1
        case 1:
            penPressure = kPenPressureValue2
        case 2:
            penPressure = kPenPressureValue3
        case 3:
            penPressure = kPenPressureValue4
        case 4:
            penPressure = UInt16(kPenPressureValue5)
        default:
            penPressure = UInt16(kPenPressureValue5)
        }
        
        NJPenCommManager.sharedInstance().setPenStateWithPenPressure(penPressure)
        let defaults = UserDefaults.standard
        defaults.set(Int(penPressure), forKey: "penPressure")
        defaults.synchronize()
    }
*/

}
