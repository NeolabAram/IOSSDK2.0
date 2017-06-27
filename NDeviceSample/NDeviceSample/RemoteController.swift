//
//  RemoteController.swift
//  NDeviceSample
//
//  Created by Aram Moon on 2017. 6. 26..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation
import UIKit
import NDeviceSDK
import CoreBluetooth

class RemoteController: UIViewController {
    
    let device = DeviceController.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func sleep(_ sender: Any) {
        device.requestPlayerEvent(.Sleep)
    }
    
    @IBAction func repeatAction(_ sender: Any) {
        device.requestPlayerEvent(.Repeat)
    }
    
    @IBAction func mute(_ sender: Any) {
        device.requestPlayerEvent(.Mute)
    }
    
    @IBAction func volumeup(_ sender: Any) {
        device.requestPlayerEvent(.VolumeUp)
    }
    
    @IBAction func volumedown(_ sender: Any) {
        device.requestPlayerEvent(.VolumeDown)
    }
    
    @IBAction func left(_ sender: Any) {
        device.requestPlayerEvent(.Left)
    }
    @IBAction func up(_ sender: Any) {
        device.requestPlayerEvent(.Up)
    }
    @IBAction func right(_ sender: Any) {
        device.requestPlayerEvent(.Right)
    }
    @IBAction func down(_ sender: Any) {
        device.requestPlayerEvent(.Down)
    }
    
    @IBAction func playPause(_ sender: Any) {
        device.requestPlayerEvent(.PlayNPause)
    }
    
    @IBAction func prev(_ sender: Any) {
        device.requestPlayerEvent(.PreviousSeek)
    }
    
    @IBAction func next(_ sender: Any) {
        device.requestPlayerEvent(.NextSeek)
    }
    @IBAction func back(_ sender: Any) {
        device.requestPlayerEvent(.Return)
    }
    @IBAction func brightUp(_ sender: Any) {
        device.requestPlayerEvent(.BrightnessUp)
    }
    @IBAction func brightDown(_ sender: Any) {
        device.requestPlayerEvent(.BrightnessDown)
    }
    @IBAction func OSD(_ sender: Any) {
        device.requestPlayerEvent(.OSD)
    }
    
    @IBAction func varsion(_ sender: Any) {
        device.requestVersionInfo()
    }
    
    @IBAction func sync(_ sender: Any) {
        device.requestSyncContents()
    }
    
    @IBAction func directPlay(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "DirectPlayController") as! DirectPlayController
        self.navigationController?.pushViewController(viewController, animated: true)
    }

}

