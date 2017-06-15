//
//  Common.swift
//  NISDK3
//
//  Created by Aram Moon on 2017. 6. 7..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation

class Common {
    static let sharedInstance = Common()
    
    private let passwordKey = "N2PenPassword"
    private let penRegister = "N2PenRegister"
    private let kPenCommMan_Pen_Register = "penRegister"
    private let kPenCommMan_Pen_Reg_UUID = "regUuid"
    private let kPenCommMan_Pen_Name = "penName"
    private let kPenCommMan_IsPenSDK2 = "isPenSDK2"
    private let kPenCommMan_Device_Name = "deviceName"
    private let kPenCommMan_fw_Ver_Server = "fwVerServer"
    private let kPenCommMan_Sub_Name = "subName"
    private let kPenCommMan_Mtu = "mtu"
    
    private init(){
        
    }
    
    func setPassword(password: String){
        UserDefaults.standard.set(password, forKey: passwordKey)
    }
    
    func getPassword() -> String{
        if let pw = UserDefaults.standard.string(forKey: passwordKey){
            return pw
        }
        return "0000"
    }
    
    func hasPenRegistered() -> Bool {
        return !regUuid().isEmpty
    }
    
    func regUuid() -> String {
        if !UserDefaults.standard.dictionaryRepresentation().keys.contains(kPenCommMan_Pen_Reg_UUID) {
            return ""
        }
        guard let uuid = UserDefaults.standard.string(forKey: kPenCommMan_Pen_Reg_UUID) else {
            return ""
        }
        return uuid
    }
    
    func setRegUuid(_ regUuid: String) {
        UserDefaults.standard.set(regUuid, forKey: kPenCommMan_Pen_Reg_UUID)
    }
    
    func upRegUuid(){
        UserDefaults.standard.removeObject(forKey: kPenCommMan_Pen_Reg_UUID)
    }
    
    func penName() -> String {
        if !UserDefaults.standard.dictionaryRepresentation().keys.contains(kPenCommMan_Pen_Name) {
            return ""
        }
        
        guard let name = UserDefaults.standard.string(forKey: kPenCommMan_Pen_Name) else {
            return ""
        }
        return name
    }
    
    func setPenName(_ penName: String) {
        UserDefaults.standard.set(penName, forKey: kPenCommMan_Pen_Name)
    }
    
    func isPenSDK2() -> Bool {
        if !UserDefaults.standard.dictionaryRepresentation().keys.contains(kPenCommMan_IsPenSDK2) {
            return false
        }
        return UserDefaults.standard.bool(forKey: kPenCommMan_IsPenSDK2)
    }
    
    func setIsPenSDK2(_ isPenSDK2: Bool) {
        UserDefaults.standard.set(isPenSDK2, forKey: kPenCommMan_IsPenSDK2)
    }
    
    func deviceName() -> String {
        if !UserDefaults.standard.dictionaryRepresentation().keys.contains(kPenCommMan_Device_Name) {
            return ""
        }
        return UserDefaults.standard.object(forKey: kPenCommMan_Device_Name)! as! String
    }
    
    func setDeviceName(_ deviceName: String) {
        UserDefaults.standard.set(deviceName, forKey: kPenCommMan_Device_Name)
    }
    
    func subName() -> String {
        if !UserDefaults.standard.dictionaryRepresentation().keys.contains(kPenCommMan_Sub_Name) {
            return ""
        }
        guard let name = UserDefaults.standard.string(forKey: kPenCommMan_Sub_Name) else {
            return ""
        }
        return name
    }
    
    func setSubName(_ subName: String) {
        UserDefaults.standard.set(subName, forKey: kPenCommMan_Sub_Name)
    }
    
    func fwVerServer() -> String {
        guard UserDefaults.standard.dictionaryRepresentation().keys.contains(kPenCommMan_fw_Ver_Server) else {
            return ""
        }
        guard let fwVer = UserDefaults.standard.string(forKey: kPenCommMan_fw_Ver_Server) else {
            return ""
        }
        return fwVer
    }
    
    func setFwVerServer(_ fwVerServer: String) {
        UserDefaults.standard.set(fwVerServer, forKey: kPenCommMan_fw_Ver_Server)
    }
    
    func mtu() -> Int {
        guard UserDefaults.standard.dictionaryRepresentation().keys.contains(kPenCommMan_Mtu) else {
            return 0
        }
        return UserDefaults.standard.integer(forKey: kPenCommMan_Mtu)
    }
    
    func setMtu(_ mtu: Int) {
        UserDefaults.standard.set(mtu, forKey: kPenCommMan_Mtu)
    }
}

