//
//  NJPageCanvasController.swift
//  n2sampleSwift
//
//  Created by Aram Moon on 2017. 5. 16..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation
import UIKit

class NJPageCanvasController: UIViewController, UIAlertViewDelegate,NJPenCommParserStrokeHandler, UIActionSheetDelegate, UIPopoverControllerDelegate, UIScrollViewDelegate {

    var offlineSyncViewController: NJOfflineSyncViewController?
    var isCloseBtnPressedStatus: Bool = false
    var parentController: NJViewController?
    var canvasPage: NJPage?
    var activeNotebookId: Int = 0
    var activePageNumber: Int = 0
    var penColor: UInt32 = 0

    var pageCanvas: NJPageCanvasView?
    var advertizeBarButton: UIBarButtonItem?
    var discoveredPeripherals = [Any]()
    var pencommManager: NJPenCommManager?
    var button: UIButton?
    var menuAniButtonView: UIImageView?
    var layer: CALayer?
    var stopTimer: Timer?
    var startDate: Date?
    var isMenuBtnToggle: Bool = false
    var lineView: UIView?
    var isFirstEntry: Bool = false
    var scrollView: UIScrollView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        navigationController?.navigationBar.layer.mask = roundedCornerNavigationBar()
        pencommManager = NJPenCommManager.sharedInstance()
        view.backgroundColor = UIColor(white: CGFloat(0.95), alpha: CGFloat(1))
        pageCanvas = NJPageCanvasView(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(0), height: CGFloat(0)))
        scrollView = UIScrollView(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(view.frame.size.width), height: CGFloat(view.frame.size.height)))
        scrollView?.contentSize = (pageCanvas?.bounds.size)!
        view = scrollView
        scrollView?.backgroundColor = UIColor(white: CGFloat(0.95), alpha: CGFloat(1))
        view.addSubview(pageCanvas!)
        pageCanvas?.scrollView = scrollView
        let closeBtn = UIButton(type: .custom)
        closeBtn.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(46), height: CGFloat(44))
        closeBtn.setBackgroundImage(UIImage(named: "btn_back.png"), for: .normal)
        
        closeBtn.addTarget(self, action: #selector(self.closeBtnPressed), for: .touchUpInside)
        view.addSubview(closeBtn)
        startDate = Date()
        isFirstEntry = true
        scrollView?.minimumZoomScale = 1.0
        scrollView?.maximumZoomScale = 6.0
        scrollView?.isPagingEnabled = true
        scrollView?.delegate = self
        scrollView?.isUserInteractionEnabled = true
        let singleFingerTap = UIPanGestureRecognizer(target: self, action: #selector(self.handleSingleTap))
        scrollView?.addGestureRecognizer(singleFingerTap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //disable phone sleep mode
        UIApplication.shared.isIdleTimerDisabled = true
        if (offlineSyncViewController != nil) {
            pageCanvas?.page = canvasPage
            adjustCanvasView()
            pageCanvas?.drawAllStroke()
            offlineSyncViewController = nil
        }
        else {
            print("setPenCommParserStrokeHandler")
            NJPenCommManager.sharedInstance().setPenCommParserStrokeHandler(self)
            NJPenCommManager.sharedInstance().setPenCommParserStartDelegate(nil)
            if (canvasPage != nil) {
                pageCanvas?.page = canvasPage
            }
            else {
                let page = NJPage(notebookId: Int(activeNotebookId), andPageNumber: Int(activePageNumber))
                pageCanvas?.page = page
            }
            adjustCanvasView()
        }
        pageCanvas?.penUIColor = convertUIColor(fromIntColor: penColor)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //disable phone sleep mode
        UIApplication.shared.isIdleTimerDisabled = false
    
        NJPenCommManager.sharedInstance().setPenCommParserStrokeHandler(nil)
        lineView?.removeFromSuperview()
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func adjustCanvasView() {
        let frame: CGRect = view.frame
        let paperSize: CGSize = pageCanvas!.page!.paperSize
        if paperSize.equalTo(CGSize.zero) {
            print("paperSize == 0")
        }
        let xRatio: CGFloat = (frame.size.width / paperSize.width)
        let yRatio: CGFloat = (frame.size.height / paperSize.height)
        let ratio: CGFloat = min(yRatio, xRatio)
        pageCanvas?.page?.screenRatio = ratio
        let xSize: CGFloat = ratio * paperSize.width
        let ySize: CGFloat = ratio * paperSize.height
        let xMargin: CGFloat = (frame.size.width - xSize) / 2
        let yMargin: CGFloat = (frame.size.height - ySize) / 2
        let canvasPoint: CGPoint = CGPoint(x: frame.origin.x + xMargin, y: frame.origin.y + yMargin)
        let canvasSize: CGSize = CGSize(width: xSize, height: ySize)
        let canvasFrame: CGRect = CGRect(origin: canvasPoint, size: canvasSize)
        if pageCanvas == nil {
            pageCanvas = NJPageCanvasView(frame: canvasFrame)
            view.addSubview(pageCanvas!)
        }
        else {
            pageCanvas?.frame = canvasFrame
        }
        pageCanvas?.backgroundColor = UIColor(white: CGFloat(0.95), alpha: CGFloat(1))
        lineView = UIView(frame: CGRect(x: CGFloat(0), y: CGFloat(frame.origin.y + yMargin), width: CGFloat(320), height: CGFloat(0.5)))
        lineView?.backgroundColor = UIColor.lightGray
        view.addSubview(lineView!)
    }
    
    
    func activeNoteId(_ noteId: Int32, pageNum pageNumber: Int32, sectionId section: Int32, ownderId owner: Int32) {
        print("noteID:\(noteId), page number:\(pageNumber), section Id:\(section), owner Id:\(owner)")
        if (activeNotebookId != Int(noteId)) || (activePageNumber != Int(pageNumber)) {
            activeNotebookId = Int(noteId)
            activePageNumber = Int(pageNumber)
            pageCanvas?.page = NJPage(notebookId: Int(noteId), andPageNumber: Int(pageNumber))
            adjustCanvasView()
            view.setNeedsDisplay()
        }
    }
    
    func handleSingleTap(_ recognizer: UITapGestureRecognizer) {
        print("single tap detected...")
    }
    
    func processStroke(_ stroke: [AnyHashable: Any]) {
        print("ProcessStroke")
        var penDown: Bool = false
        var startNode: Bool = false
        let type: String? = (stroke["type"] as? String)
        if (type == "stroke") {
            if isFirstEntry {
                penDown = true
                startNode = true
                isFirstEntry = false
                print("firsstEntry")
            }
            if penDown == false {
                //return
            }
            let node: NJNode? = (stroke["node"] as? NJNode)
            let x: Float? = node?.x
            let y: Float? = node?.y
//            print("processStroke X \(x), Y \(y), startX \(pageCanvas?.page?.paperInfo.startX), startY \(pageCanvas?.page?.paperInfo.startY)")
            if startNode == false {
                pageCanvas?.touchMovedX(x!, y: y!)
            }
            else {
                pageCanvas?.touchBeganX(x!, y: y!)
                startNode = false
            }
//            findApplicableSymbolsX(CGFloat(x!), andY: CGFloat(y!))
        }
        else if (type == "updown") {
            let status: String? = (stroke["status"] as? String)
            if (status == "down") {
                penDown = true
                startNode = true
                pageCanvas?.setPage(page:NJPage(notebookId: 601, andPageNumber: 0 ))
            }
            else {
                print("pen up")
                isFirstEntry = true
                pageCanvas?.strokeUpdated()
            }
        }
        
    }
    
    func findApplicableSymbolsX(_ x: CGFloat, andY y: CGFloat) {
        if let paperInfo = pageCanvas?.page?.paperInfo {
            var found: Bool = false
            let cmdType: PUICmdType = .none
            var xx = x + paperInfo.startX
            var yy = y + paperInfo.startY
            let pui: NPPUIInfo? = paperInfo.puiArray[0] as! NPPUIInfo
            
            for pi in (paperInfo.puiArray)! {
                var padding: CGFloat = 0.0;
                if ((pi as AnyObject).width > 5.0) && ((pi as AnyObject).height > 5.0){
                    padding = min((pi as AnyObject).width,(pi as AnyObject).height) * 0.1
                }
                
                if xx < ((pi as! NPPUIInfo).startX + padding) {
                    continue
                }
                if yy < ((pi as! NPPUIInfo).startY + padding) {
                    continue
                }
                if xx > ((pi as! NPPUIInfo).startX + (pi as! NPPUIInfo).width - padding) {
                    continue
                }
                if yy > ((pi as! NPPUIInfo).startY + (pi as! NPPUIInfo).height - padding) {
                    continue
                }
                
                found = true
                break;
            }
            
            if cmdType == .none {
                return
            }
            print("param:\(String(describing: pui?.param)), action:\(String(describing: pui?.action)), name:\(String(describing: pui?.name))")
            print("Symbol X \(x), Y \(y), startX \(String(describing: paperInfo.startX)), startY \(String(describing: paperInfo.startY))")
        }
    }
    
    
    func notifyPageChanging() {
        pageCanvas?.isPageChanging = true
    }
    
    func notifyDataUpdating(_ updating: Bool) {
    }
    
    func closeBtnPressed() {
        NJPenCommManager.sharedInstance().requestNewPageNotification()
        dismiss(animated: true, completion: {() -> Void in
            self.parentController?.isCanvasCloseBtnPressed = true
        })
    }
    
    func roundedCornerNavigationBar() -> CAShapeLayer {
        let maskPath = UIBezierPath(roundedRect: (navigationController?.navigationBar.bounds)!, byRoundingCorners: ([.topLeft, .topRight]), cornerRadii: CGSize(width: CGFloat(5.0), height: CGFloat(5.0)))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = (navigationController?.navigationBar.bounds)!
        maskLayer.path = maskPath.cgPath
        return maskLayer
    }
    
    func didColorChanged(_ color: UIColor?) {
        if color != nil {
            print("color ===> \(color)")
            penColor = convertUIColor(toAlpahRGB: color!)
            pageCanvas?.penUIColor = color
            let colorData = NSKeyedArchiver.archivedData(withRootObject: color)
            UserDefaults.standard.set(colorData, forKey: "penColor")
            NJPenCommManager.sharedInstance().setPenStateWithRGB(penColor)
        }
    }
    
    func didThicknessChanged(_ thickness: Int) {
        // line thickness changed...
        // value between 1~3 levels;
        print("line thickness --> \(Int(thickness))")
    }
    
    func setPenColor() -> UInt32 {
        let colorRed: UInt32 = UInt32(0.2)
        let colorGreen: UInt32 = UInt32(0.2)
        let colorBlue: UInt32 = UInt32(0.2)
        let colorAlpah: UInt32 = UInt32(1.0)
        let alpah = UInt32(colorAlpah * 255) & 0x000000ff
        let red = UInt32(colorRed * 255) & 0x000000ff
        let green = UInt32(colorGreen * 255) & 0x000000ff
        let blue = UInt32(colorBlue * 255) & 0x000000ff
        var color: UInt32 = (alpah << 24) | (red << 16) | (green << 8) | blue
        if penColor != 0 {
            color = penColor
        }
        return color
    }
    
    func convertUIColor(toAlpahRGB color: UIColor) -> UInt32 {
        let components: [CGFloat] = color.cgColor.components!
        print("Red: \(components[0])")
        print("Green: \(components[1])")
        print("Blue: \(components[2])")
        print("Alpha: \(color.cgColor.alpha)")
        let colorRed: CGFloat = components[0]
        let colorGreen: CGFloat = components[1]
        let colorBlue: CGFloat = components[2]
        let colorAlpah: CGFloat = 1.0
        let alpah = UInt32(colorAlpah * 255) & 0x000000ff
        let red = UInt32(colorRed * 255) & 0x000000ff
        let green = UInt32(colorGreen * 255) & 0x000000ff
        let blue = UInt32(colorBlue * 255) & 0x000000ff
        let penColor: UInt32 = (alpah << 24) | (red << 16) | (green << 8) | blue
        return penColor
    }
    
    func convertUIColor(fromIntColor intColor: UInt32) -> UIColor {
        let colorA: Float = Float(intColor >> 24) / 255.0
        let colorR: Float = Float((intColor >> 16) & 0x000000ff) / 255.0
        let colorG: Float = Float((intColor >> 8) & 0x000000ff) / 255.0
        let colorB: Float = Float(intColor & 0x000000ff) / 255.0
        return UIColor(red: CGFloat(colorR), green: CGFloat(colorG), blue: CGFloat(colorB), alpha: CGFloat(colorA))
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return pageCanvas
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        for gestureRecognizer: UIGestureRecognizer in (self.scrollView?.gestureRecognizers!)! {
            if (gestureRecognizer is UIPanGestureRecognizer) {
                let panGR: UIPanGestureRecognizer? = (gestureRecognizer as? UIPanGestureRecognizer)
                panGR?.minimumNumberOfTouches = 1
            }
        }
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        pageCanvas?.screenScale = scale
        if scale == 1.0 {
            self.scrollView?.contentSize = (pageCanvas?.bounds.size)!
        }
    }
    
}
