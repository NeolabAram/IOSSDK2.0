//
//  SimpleViewController.swift
//  n2sampleSwift
//
//  Created by Aram Moon on 2017. 5. 22..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation
import UIKit

class SimpleViewController: UIViewController,NJPenCommParserStrokeHandler {
    
    var page : NJPage?
    var pencommManager :NJPenCommManager!
    var myview : SimpleView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        pencommManager = NJPenCommManager.sharedInstance()
        NJPenCommManager.sharedInstance().setPenCommParserStrokeHandler(self)
        NJPenCommManager.sharedInstance().setPenCommParserStartDelegate(nil)
        myview = SimpleView(frame : self.view.frame)
        self.view.addSubview(myview)
        
        let closeBtn = UIButton(type: .custom)
        closeBtn.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(46), height: CGFloat(44))
        closeBtn.setBackgroundImage(UIImage(named: "btn_back.png"), for: .normal)
        closeBtn.addTarget(self, action: #selector(self.closeBtnPressed), for: .touchUpInside)
        view.addSubview(closeBtn)
    }
    
    func closeBtnPressed(){
        NJPenCommManager.sharedInstance().requestNewPageNotification()
        dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let p = page{
            myview.offPage = p
            myview.drawAllStroke()
        }
    }
    
    func activeNoteId(_ noteId: Int32, pageNum pageNumber: Int32, sectionId section: Int32, ownderId owner: Int32) {
        print("activeNoteId")
        
    }
    
    func setPenColor() -> UInt32{
        print("setPenColor")
        return 0xff555555
    }

    func notifyPageChanging(){
        print("activeNoteId")
    }
    
    var isFirstEntry = true
    
    func processStroke(_ stroke: [AnyHashable: Any]) {
        var penDown: Bool = false
        var startNode: Bool = false
        let type: String? = (stroke["type"] as? String)
        if (type == "stroke") {
            if isFirstEntry {
                penDown = true
                startNode = true
                isFirstEntry = false
            }
            if penDown == false {
            }
            let node: NJNode? = (stroke["node"] as? NJNode)
            let x: Float? = node?.x
            let y: Float? = node?.y
            if startNode == false {
                myview.move(CGFloat(x!), CGFloat(y!))
            }
            else {
                myview.begin(CGFloat(x!), CGFloat(y!))
                startNode = false
            }
        }
        else if (type == "updown") {
            let status: String? = (stroke["status"] as? String)
            if (status == "down") {
                penDown = true
                startNode = true
            }
            else {
                isFirstEntry = true
                myview.end()
            }
        }
        
    }
}
