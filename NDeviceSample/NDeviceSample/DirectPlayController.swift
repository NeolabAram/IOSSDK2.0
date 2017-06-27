//
//  DirectPlayController.swift
//  NDeviceSample
//
//  Created by Aram Moon on 2017. 6. 27..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation
import UIKit
import NDeviceSDK

class DirectPlayController: UITableViewController {
    var playSampleList:[(UInt16,UInt16,UInt16,String)] = [(1000,10002, 11001,"세계명작1")
        ,(1000,10002,11003,"이솝창작동화3")
        ,(1000,10004,13024,"영어동화")
        ,(1000,10005,14018,"마더구즈동화")
        ,(1000,10006,15026,"명화갤러리")
        ,(1000,10007,16028, "전래동화")
        ,(1000,10008,17038, "뮤지컬동화")
        ,(1000,10009,18041, " 영어로노래시작")
        ,(1000,10010,19012," 종이접기")
        ,(1001,10101,21032,"자장가")
        ,(1001,10114,34024,"캐럴")
        ,(1002,10203,52011, "색깔모양놀이")]

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playSampleList.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let height: CGFloat = 80
        return height
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell : UITableViewCell
        cell = UITableViewCell(style: .default, reuseIdentifier: "deviceInfo")
        cell.textLabel?.text = playSampleList[indexPath.row].3
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let (mainId,subId,contentsId,name) = playSampleList[indexPath.row]
        print("play", name)
        DeviceController.sharedInstance.requestDirectPlay(mainId, subId, contentsId)
    }
    
}
