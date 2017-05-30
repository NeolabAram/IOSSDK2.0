//
//  NJInputPasswordViewController.swift
//  n2sampleSwift
//
//  Created by Aram Moon on 2017. 5. 16..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation
import UIKit

class NJInputPasswordViewController: UIViewController {
    
    var currentPin: String = ""
    var savePin: String = ""

    @IBOutlet var numberDot1: UIImageView!
    @IBOutlet var numberDot2: UIImageView!
    @IBOutlet var numberDot3: UIImageView!
    @IBOutlet var numberDot4: UIImageView!
    @IBOutlet var numberBtn1: UIButton!
    @IBOutlet var numberBtn2: UIButton!
    @IBOutlet var numberBtn3: UIButton!
    @IBOutlet var numberBtn4: UIButton!
    @IBOutlet var numberBtn5: UIButton!
    @IBOutlet var numberBtn6: UIButton!
    @IBOutlet var numberBtn7: UIButton!
    @IBOutlet var numberBtn8: UIButton!
    @IBOutlet var numberBtn9: UIButton!
    @IBOutlet var numberBtn0: UIButton!
    @IBOutlet var backSpace: UIButton!
    @IBOutlet var passwordGuide: UITextView!
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        //back
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        currentPin = ""
        numberBtn1.setImage(UIImage(named: "settings_number_1_press.png"), for: .highlighted)
        numberBtn2.setImage(UIImage(named: "settings_number_2_press.png"), for: .highlighted)
        numberBtn3.setImage(UIImage(named: "settings_number_3_press.png"), for: .highlighted)
        numberBtn4.setImage(UIImage(named: "settings_number_4_press.png"), for: .highlighted)
        numberBtn5.setImage(UIImage(named: "settings_number_5_press.png"), for: .highlighted)
        numberBtn6.setImage(UIImage(named: "settings_number_6_press.png"), for: .highlighted)
        numberBtn7.setImage(UIImage(named: "settings_number_7_press.png"), for: .highlighted)
        numberBtn8.setImage(UIImage(named: "settings_number_8_press.png"), for: .highlighted)
        numberBtn9.setImage(UIImage(named: "settings_number_9_press.png"), for: .highlighted)
        numberBtn0.setImage(UIImage(named: "settings_number_0_press.png"), for: .highlighted)
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.penPasswordCompareSuccess), name: NSNotification.Name.NJPenCommManagerPenConnectionStatusChange, object: nil)
        nc.addObserver(self, selector: #selector(self.penPasswordValidationFail), name: NSNotification.Name(rawValue: NJPenCommParserPenPasswordValidationFail), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    

    func startTimer() {
        if !(timer != nil) {
            timer = Timer(timeInterval: 0.3, target: self, selector: #selector(self.completeFourthDot), userInfo: nil, repeats: true)
            RunLoop.main.add(timer!, forMode: RunLoopMode.defaultRunLoopMode)
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    @IBAction func numberBtnPressed(_ sender: UIButton) {
        let tag: Int = sender.tag
        print("numberBtn \(tag) Pressed")
        newPinSelected(tag)
    }
    
    @IBAction func backSpacePressed(_ sender: Any) {
        print("backSpacePressed")
        if currentPin.length == 0 {
            return
        }
        if currentPin.length == 1 {
            numberDot1.image = UIImage(named: "field_settings_empty.png")
        }
        else if currentPin.length == 2 {
            numberDot2.image = UIImage(named: "field_settings_empty.png")
        }
        else if currentPin.length == 3 {
            numberDot3.image = UIImage(named: "field_settings_empty.png")
        }
        
        currentPin = (currentPin as NSString).substring(with: NSRange(location: 0, length: currentPin.length - 1))
    }
    
    let PIN_LENGTH = 4
    func newPinSelected(_ pinNumber: Int) {
        if currentPin.length >= PIN_LENGTH {
            return
        }
        currentPin = "\(currentPin)\(Int(pinNumber))"
        if currentPin.length == 1 {
            numberDot1.image = UIImage(named: "field_settings_fill.png")
        }
        else if currentPin.length == 2 {
            numberDot2.image = UIImage(named: "field_settings_fill.png")
        }
        else if currentPin.length == 3 {
            numberDot3.image = UIImage(named: "field_settings_fill.png")
        }
        else if currentPin.length == PIN_LENGTH {
            numberDot4.image = UIImage(named: "field_settings_fill.png")
            startTimer()
        }
        
    }
    
    func completeFourthDot() {
        stopTimer()
        processPin()
    }
    
    func processPin() {
        NJPenCommManager.sharedInstance().setBTComparePassword(currentPin)
        savePin = currentPin
        currentPin = ""
        numberDot1.image = UIImage(named: "field_settings_empty.png")
        numberDot2.image = UIImage(named: "field_settings_empty.png")
        numberDot3.image = UIImage(named: "field_settings_empty.png")
        numberDot4.image = UIImage(named: "field_settings_empty.png")
    }
    
    func penPasswordCompareSuccess(_ notification: Notification) {
        if (savePin != nil) && (!(savePin == "")) {
            MyFunctions.saveIntoKeyChain(withPasswd: savePin)
            modalTransitionStyle = .crossDissolve
            dismiss(animated: true, completion: { _ in })
            let alert = UIAlertView(title: "", message: NSLocalizedString("Pen Password Input Success", comment: ""), delegate: nil, cancelButtonTitle: NSLocalizedString("OK", comment: ""), otherButtonTitles: "")
            alert.show()
        }
        savePin = ""
    }
    
    func penPasswordValidationFail(_ notification: Notification) {
        navigationController?.popViewController(animated: false)
        let alert = UIAlertView(title: "", message: NSLocalizedString("PEN_PW_CHANGE_POPUP_FAIL", comment: ""), delegate: nil, cancelButtonTitle: NSLocalizedString("PEN_PW_SETTING_POPUP_OK", comment: ""), otherButtonTitles: "")
        alert.show()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
