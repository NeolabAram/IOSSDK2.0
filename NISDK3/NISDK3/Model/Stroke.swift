//
//  Stroke.swift
//  NISDK3
//
//  Created by Aram Moon on 2017. 6. 19..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation
import UIKit


class NJStroke: NSObject {
    var nodes = [Node]()
    var dataCount: Int = 0
    var inputScale: Float = 0.0
    var targetScale: Float = 0.0
    var penColor: UInt32 = 0
    var penThickness: Int = 0
    
    public var point_x = [Float]()
    public var point_y = [Float]()
    public var point_p = [Float]()
    public var time_stamp = [Int]()
    public var start_time: Int = 0
    
    var renderingPath: UIBezierPath?
    
    private var colorRed: Float = 0.0
    private var colorGreen: Float = 0.0
    private var colorBlue: Float = 0.0
    private var colorAlpah: Float = 0.0
    override init() {
        penThickness = 0;
    }
    
    convenience init( x: [Float], y: [Float], p: [Float], time: [Int], penColor: UInt32, penThickness thickness: Int, start_at: Int, size: Int){
        self.init()
        var time_lapse: Int = 0
        var _: Int = 0
        dataCount = size
        point_x = x
        point_y = y
        point_p = p
        time_stamp = time
        if size < 3 {
            for i in size..<3 {
                point_x[i] = x[size - 1]
                point_y[i] = y[size - 1]
                point_p[i] = p[size - 1]
                time_stamp[i] = 0
            }
            dataCount = 3
        }
        start_time = start_at
        penThickness = thickness - 1
        for i in 0..<dataCount {
            time_lapse += time[i]
            time_stamp[i] = start_at + time_lapse
        }
        inputScale = 1
        if penColor == 0 {
            initColor()
        }
        else {
            self.penColor = penColor
        }
    }
    
    convenience init( x: [Float], y: [Float], p: [Float], time: [Int], penColor: UInt32, penThickness thickness: Int, start_at: Int, size: Int, inputScale: Float){
        self.init(x: x,y: y,p: p,time: time,penColor: penColor,penThickness: thickness,start_at: start_at, size: size)
        self.inputScale = inputScale;
        
    }
    
    func setPenColor(penColor: UInt32) {
        self.penColor = penColor
        colorAlpah = Float(penColor >> 24) / 255.0
        colorRed = Float((penColor >> 16) & 0x000000ff) / 255.0
        colorGreen = Float((penColor >> 8) & 0x000000ff) / 255.0
        colorBlue = Float(penColor & 0x000000ff) / 255.0
    }
    
    func initColor() {
        colorRed = 0.2
        colorGreen = 0.2
        colorBlue = 0.2
        colorAlpah = 1.0
        let alpah = UInt32(colorAlpah * 255) & 0x000000ff
        let red = UInt32(colorRed * 255) & 0x000000ff
        let green = UInt32(colorGreen * 255) & 0x000000ff
        let blue = UInt32(colorBlue * 255) & 0x000000ff
        penColor = (alpah << 24) | (red << 16) | (green << 8) | blue
    }
    
    func GetRenderingPath() -> UIBezierPath {
        if renderingPath == nil {
            renderingPath = UIBezierPath()
            renderingPath?.lineWidth = 1.0
            renderingPath?.fill()
        }
        return renderingPath!
    }
    
    func render(withScale scale: CGFloat) {
        var pts = [CGPoint](repeating: CGPoint.zero, count: 5)
        // we now need to keep track of the four points of a Bezier segment and the first control point of the next segment
        var ctr: Int = 0
        renderingPath?.removeAllPoints()
        if dataCount < 5 {
            var p = CGPoint(x: CGFloat(point_x[0] * Float(scale)), y: CGFloat(point_y[0] * Float(scale)))
            renderingPath?.move(to: p)
            for i in 1..<dataCount {
                p = CGPoint(x: CGFloat(point_x[i] * Float(scale)), y: CGFloat(point_y[i] * Float(scale)))
                renderingPath?.addLine(to: p)
            }
            return
        }
        for i in 0..<dataCount {
            let p = CGPoint(x: CGFloat(point_x[i] * Float(scale)), y: CGFloat(point_y[i] * Float(scale)))
            if i == 0 {
                pts[0] = p
                continue
            }
            ctr += 1
            pts[ctr] = p
            if ctr == 4 {
                pts[3] = CGPoint(x: CGFloat((pts[2].x + pts[4].x) / 2.0), y: CGFloat((pts[2].y + pts[4].y) / 2.0))
                // move the endpoint to the middle of the line joining the second control point of
                // the first Bezier segment and the first control point of the second Bezier segment
                renderingPath?.move(to: pts[0])
                renderingPath?.addCurve(to: pts[3], controlPoint1: pts[1], controlPoint2: pts[2])
                // add a cubic Bezier from pt[0] to pt[3], with control points pt[1] and pt[2]
                // replace points and get ready to handle the next segment
                pts[0] = pts[3]
                pts[1] = pts[4]
                ctr = 1
            }
            
            if (i == (dataCount - 1)) && (ctr > 0) && (ctr < 4) {
                var ctr1 = CGPoint.zero
                var ctr2 = CGPoint.zero
                if ctr == 1 {
                    renderingPath?.addLine(to: pts[ctr])
                }
                else {
                    ctr1 = pts[ctr - 2]
                    ctr2 = pts[ctr - 2]
                    if ctr == 3 {
                        ctr2 = pts[ctr - 1]
                    }
                    renderingPath?.addCurve(to: pts[ctr], controlPoint1: ctr1, controlPoint2: ctr2)
                }
            }
        }
        renderingPath?.stroke()
        
    }
}
