//
//  NJPageCanvasView.swift
//  n2sampleSwift
//
//  Created by Aram Moon on 2017. 5. 16..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation
import UIKit

let MAX_NODE : Int = 1024

class NJPageCanvasView : UIView{
    
    var location = CGPoint.zero
    var btlePeripheral: NJPageCanvasController?
    var nodes = [Any]()
    var page: NJPage?
    var tempPath: UIBezierPath!
    var renderingPath: UIBezierPath?
    var incrementalImage: UIImage?
    weak var scrollView: UIScrollView?
    var isPageChanging: Bool = false
    var isDataUpdating: Bool = false
    var penUIColor: UIColor?
    var penPenColor: UIColor?
    // Color from pen
    var screenScale: CGFloat = 0.0

    private var mX = [Float](repeating: 0.0, count: MAX_NODE)
    private var mY = [Float](repeating: 0.0, count: MAX_NODE)
    private var mFP = [Float](repeating: 0.0, count: MAX_NODE)
    private var mN: Int = 0
    private var point_x = [Float](repeating: 0.0, count: MAX_NODE)
    private var point_y = [Float](repeating: 0.0, count: MAX_NODE)
    private var point_p = [Float](repeating: 0.0, count: MAX_NODE)
    private var time_diff = [Int](repeating: 0, count: MAX_NODE)
    private var point_count: Int = 0
    
    var strokeRenderedIndex : Int = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = false
        backgroundColor = UIColor.black
        tempPath = UIBezierPath()
        tempPath.lineWidth = 1.2
        isPageChanging = true
        isDataUpdating = false
        scrollView = nil
        screenScale = 1.0
        penUIColor = UIColor.black
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setPage(page: NJPage) {
        self.page = page
        self.page?.bounds = bounds
        strokeRenderedIndex = Int((self.page?.strokes.count)!) - 1
        // pass nil for bgimage. This will generate bg imgage from pdf
        if !bounds.size.equalTo(CGSize.zero) {
            incrementalImage = self.page?.drawPage(image: nil, size: self.bounds, drawBG: true, opaque: true)
            //self.page?.draw(withImage: nil, image: &<#UIImage?#>, size: bounds, scale: <#Float#>, drawBG: true, opaque: true)
        }
        isPageChanging = false
        tempPath.removeAllPoints()
        print("canvas view page opened")
        
        
        setNeedsDisplay()
    }
    
    func setScrollView(scrollView: UIScrollView) {
        self.scrollView = scrollView
        self.scrollView?.scrollRectToVisible(CGRect(x: CGFloat(frame.origin.x), y: CGFloat(frame.origin.y), width: CGFloat((self.scrollView?.frame.size.width)!), height: CGFloat((self.scrollView?.frame.size.height)!)), animated: false)
    }
    
    func touchBeganX(_ x_coordinate: Float, y y_coordinate: Float) {
        var currentLocation: CGPoint = CGPoint()
        currentLocation.x = CGFloat(x_coordinate) * page!.screenRatio
        currentLocation.y = CGFloat(y_coordinate) * page!.screenRatio
        point_count = 0
        point_x[point_count] = Float(currentLocation.x)
        point_y[point_count] = Float(currentLocation.y)
        point_p[point_count] = 50.0
        time_diff[point_count] = Int(Date().timeIntervalSince1970)
        point_count += 1
        tempPath.move(to: currentLocation)
//        if scrollView != nil {
//            var start_x: CGFloat = CGFloat((currentLocation.x * screenScale) - scrollView!.frame.size.width / 2.0)
//            if start_x < 0.0 {
//                start_x = 0.0
//            }
//            var start_y: CGFloat = CGFloat((currentLocation.y * screenScale) - scrollView!.frame.size.height / 2.0)
//            if start_y < 0.0 {
//                start_y = 0.0
//            }
//            //NSLog(@"frame origin x %f, y %f", self.frame.origin.x, self.frame.origin.y);
//            scrollView?.scrollRectToVisible(CGRect(x: (start_x + frame.origin.x), y: (start_y + frame.origin.y), width: CGFloat((scrollView?.frame.size.width)!), height: CGFloat((scrollView?.frame.size.height)!)), animated: true)
//        }
    }
    
    func touchMovedX(_ x_coordinate: Float, y y_coordinate: Float) {
        var currentLocation: CGPoint = CGPoint()
        currentLocation.x = CGFloat(x_coordinate) * page!.screenRatio
        currentLocation.y = CGFloat(y_coordinate) * page!.screenRatio
        point_x[point_count] = Float(currentLocation.x)
        point_y[point_count] = Float(currentLocation.y)
        point_p[point_count] = 50.0
        time_diff[point_count] = Int(Date().timeIntervalSince1970)
        point_count += 1
        tempPath.addLine(to: currentLocation)
        setNeedsDisplay()
        print("touchMove \(x_coordinate)")
    }
    
    override func draw(_ rect: CGRect) {
        
        if isPageChanging || isDataUpdating {
            return
        }
        if (penUIColor != nil) {
            let strokeColor: UIColor? = (penPenColor != nil) ? penPenColor : penUIColor
            strokeColor?.setStroke()
        }
        incrementalImage?.draw(in: rect)
        tempPath.stroke()
        print("drawStroke")
    }
    
    func strokeUpdated() {
        
        UIColor.black.setStroke()
        tempPath.stroke()
        tempPath.removeAllPoints()
        return
        
        let penUIColor: UInt32 = 0x55555555//convertUIColor(toAlpahRGB: self.penUIColor!)
        let stroke = NJStroke(x: point_x, y: point_y, p: point_p, time: time_diff, penColor: penUIColor, penThickness: 0, start_at: Int(Date().timeIntervalSince1970), size: point_count, inputScale: Float((page?.inputScale)!))
        
        page?.addStrokes(stroke: stroke)
        let lastIndex = Int((page?.strokes.count)!) - 1
        if strokeRenderedIndex >= lastIndex {
            return
        }
        for i in strokeRenderedIndex + 1...lastIndex {
            let stroke: NJStroke? = (page?.strokes[i] as? NJStroke)
            let tempincrementalImage = UIImage()
            incrementalImage = page?.draw(stroke: stroke!, imageIn: tempincrementalImage, size: bounds, scale: 1.0, offsetX: 0.0, offsetY: 0.0, drawBG: true, opaque: true)
            print("self.incrementalImage:\((incrementalImage != nil) ? true : false)")
        }
        strokeRenderedIndex = lastIndex
        tempPath.removeAllPoints()
        setNeedsDisplay()
    }
    
    func drawAllStroke() {
        strokeRenderedIndex = (page?.strokes.count)! - 1
        let write_image: UIImage? = page?.drawPage(image: nil, size: bounds, drawBG: true, opaque: true)

            //page?.draw(withImage: nil, imageIn: <#UIImage?#>, size: bounds, drawBG: true, opaque: true)
        incrementalImage = write_image
        isPageChanging = false
        setNeedsDisplay()
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
        var penColor: UInt32 = (alpah << 24) | (red << 16) | (green << 8) | blue
        penColor = 0xff555555
        return penColor
    }
}
