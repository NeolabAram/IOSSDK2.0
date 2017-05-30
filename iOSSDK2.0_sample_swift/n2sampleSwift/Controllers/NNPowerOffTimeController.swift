//
//  NNPowerOffTimeController.swift
//  n2sampleSwift
//
//  Created by Aram Moon on 2017. 5. 26..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation

class NNPowerOffTimeController : UITableViewController {
    
    let kPwrOffTime1 = 10
    let kPwrOffTime2 = 20
    let kPwrOffTime3 = 40
    let kPwrOffTime4 = 60
    
    var menuList = ["10 minutes", "20 minutes", "40 minutes", "60 minutes", "If setting time is long, usable time of the is shorter."]

    var lastIndexPath: IndexPath?
    
    let header = "Shutdown Timer"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isEditing = false
        let tempImageView = UIImageView(image: UIImage(named: "bg_settings.png"))
        tempImageView.frame = self.view.frame
        tableView.backgroundView = tempImageView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        setAutoPwrOffTime()
        super.viewWillDisappear(animated)
    }
    
    func shouldShowMiniCanvas() -> Bool {
        return false
    }
    
    // MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (indexPath.row == 4) ? 65.0 : 54.5
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "TableviewCell")
        if indexPath.row == 4 {
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = UIColor(red: CGFloat(190 / 255.0), green: CGFloat(190 / 255.0), blue: CGFloat(190 / 255.0), alpha: CGFloat(1))
            cell.textLabel?.numberOfLines = 3
            cell.backgroundColor = UIColor.clear
            cell.textLabel?.highlightedTextColor = UIColor.black
            cell.textLabel?.font = UIFont.systemFont(ofSize: CGFloat(12.0))
            cell.textLabel?.text = menuList[indexPath.row]
        }
        else {
            cell.textLabel?.text = menuList[indexPath.row]
            cell.textLabel?.textColor = UIColor.white
            cell.backgroundColor = UIColor.clear
            let defaults = UserDefaults.standard
            let nAutoPwrOff = defaults.integer(forKey: "autoPwrOff")
            var index: Int
            switch nAutoPwrOff {
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
                cell.accessoryType = .checkmark
            }
            else {
                cell.accessoryType = .none
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHeader = header
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
    
    func setAutoPwrOffTime() {
        var autoPwrOff: UInt16
        switch lastIndexPath!.row {
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
    }
}
