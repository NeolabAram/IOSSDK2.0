//
//  NNSensorController.swift
//  n2sampleSwift
//
//  Created by Aram Moon on 2017. 5. 26..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation

class NNSensorController: UITableViewController {
    let kPenPressureValue1 = 4
    let kPenPressureValue2 = 3
    let kPenPressureValue3 = 2
    let kPenPressureValue4 = 1
    let kPenPressureValue5 = 0
    
    let headerTitle = "Pen Sensor Pressure Tuning"
    var menuList = ["Level 1", "Level 2", "Level 3", "Level 4","Level 5 (The most sensitive)", "Pen pressure is more insensitive as close as level 1."]
    
    var lastIndexPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tempImageView = UIImageView(image: UIImage(named: "bg_settings.png"))
        tempImageView.frame = (tableView?.frame)!
        tableView.backgroundView = tempImageView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        setPenPressureCalibration()
        super.viewWillDisappear(animated)
    }
    
    // MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (indexPath.row == 5) ? 65.0 : 54.5
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.textLabel?.text = menuList[indexPath.row]
        if indexPath.row == 5 {
            cell.selectionStyle = .none
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = UIColor(red: CGFloat(190 / 255.0), green: CGFloat(190 / 255.0), blue: CGFloat(190 / 255.0), alpha: CGFloat(1))
            cell.textLabel?.numberOfLines = 3
            cell.backgroundColor = UIColor.clear
            cell.textLabel?.highlightedTextColor = UIColor.black
            cell.textLabel?.font = UIFont.systemFont(ofSize: CGFloat(12.0))
        }
        else {
            cell.textLabel?.textColor = UIColor.white
            cell.backgroundColor = UIColor.clear
            let defaults = UserDefaults.standard
            let nPenPressure = defaults.integer(forKey: "penPressure")
            var index: Int
            switch nPenPressure {
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
                cell.accessoryType = .none
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row != 5 {
            if lastIndexPath?.row != indexPath.row {
                let newCell: UITableViewCell? = tableView.cellForRow(at: indexPath)
                newCell?.accessoryType = .checkmark
                let oldCell: UITableViewCell? = tableView.cellForRow(at: lastIndexPath!)
                oldCell?.accessoryType = .none
                lastIndexPath = indexPath
            }
            else {
                let newCell: UITableViewCell? = tableView.cellForRow(at: indexPath)
                newCell?.accessoryType = .checkmark
            }
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHeader: String? = headerTitle
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
    
    func setPenPressureCalibration() {
        var penPressure: Int
        switch lastIndexPath!.row {
        case 0:
            penPressure = kPenPressureValue1
        case 1:
            penPressure = kPenPressureValue2
        case 2:
            penPressure = kPenPressureValue3
        case 3:
            penPressure = kPenPressureValue4
        case 4:
            penPressure = kPenPressureValue5
        default:
            penPressure = kPenPressureValue5
        }
        
        NJPenCommManager.sharedInstance().setPenStateWithPenPressure(UInt16(penPressure))
        let defaults = UserDefaults.standard
        defaults.set(penPressure, forKey: "penPressure")
    }

}
