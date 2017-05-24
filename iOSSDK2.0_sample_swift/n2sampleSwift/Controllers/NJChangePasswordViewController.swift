//
//  NJChangePasswordViewController.swift
//  n2sampleSwift
//
//  Created by Aram Moon on 2017. 5. 16..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation
import UIKit

class NJChangePasswordViewController: UIViewController {
    /*
    var currentPin: String = ""
    var savedPin: String = ""
    var changeNewPin: String = ""
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        currentPin = ""
        savedPin = ""
        changeNewPin = ""
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
        NotificationCenter.default.addObserver(self, selector: #selector(self.passwordSetupSuccess), name: NSNotification.Name(rawValue: NJPenCommParserPenPasswordSutupSuccess), object: nil)
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
        if (changeNewPin == "") {
            changeNewPin = currentPin
            currentPin = ""
            numberDot1.image = UIImage(named: "field_settings_empty.png")
            numberDot2.image = UIImage(named: "field_settings_empty.png")
            numberDot3.image = UIImage(named: "field_settings_empty.png")
            numberDot4.image = UIImage(named: "field_settings_empty.png")
            passwordGuide.text = NSLocalizedString("Please re-enter to confirm", comment: "")
        }
        else {
            if (currentPin == changeNewPin) {
                processPin()
            }
            else {
                currentPin = ""
                numberDot1.image = UIImage(named: "field_settings_empty.png")
                numberDot2.image = UIImage(named: "field_settings_empty.png")
                numberDot3.image = UIImage(named: "field_settings_empty.png")
                numberDot4.image = UIImage(named: "field_settings_empty.png")
                passwordGuide.text = NSLocalizedString("Please re-enter to confirm", comment: "")
                passwordSetupFail()
            }
        }
    }
    
    func processPin() {
        savedPin = MyFunctions.loadPasswd()
        if (savedPin == "") {
            savedPin = "0000"
        }
        NJPenCommManager.sharedInstance().changePassword(from: savedPin, to: currentPin)
        numberDot1.image = UIImage(named: "field_settings_empty.png")
        numberDot2.image = UIImage(named: "field_settings_empty.png")
        numberDot3.image = UIImage(named: "field_settings_empty.png")
        numberDot4.image = UIImage(named: "field_settings_empty.png")
    }
    
    func passwordSetupSuccess(_ notification: Notification) {
        let passwordChangeResult: Bool = ((notification.userInfo)!["result"] != nil)
        if (currentPin == "") {
            return
        }
        if passwordChangeResult {
            MyFunctions.saveIntoKeyChain(withPasswd: currentPin)
            currentPin = ""
            navigationController?.popViewController(animated: false)
            let alertC = UIAlertController(title: "Password changed", message: "The pen password has been successfully changed.", preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertC.addAction(defaultAction)
            
            present(alertC, animated: true, completion: nil)

        }
        else {
            navigationController?.popViewController(animated: false)
            let alert = UIAlertView(title: "", message: NSLocalizedString("Failed to change password. \nPlease try again.", comment: ""), delegate: nil, cancelButtonTitle: NSLocalizedString("OK", comment: ""), otherButtonTitles: "")
            alert.show()
        }
    }
    
    func passwordSetupFail() {
        navigationController?.popViewController(animated: false)
        let alert = UIAlertView(title: "", message: NSLocalizedString("Failed to change password. \nPlease try again.", comment: ""), delegate: nil, cancelButtonTitle: NSLocalizedString("OK", comment: ""), otherButtonTitles: "")
        alert.show()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
 */
}
