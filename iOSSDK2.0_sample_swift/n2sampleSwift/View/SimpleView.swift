//
//  SimpleView.swift
//  n2sampleSwift
//
//  Created by Aram Moon on 2017. 5. 22..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

public class SimpleView: UIView {
    
    var tempPath :UIBezierPath!
    var lines : [CGPoint] = []
    
    var path :UIBezierPath!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        isMultipleTouchEnabled = false
        UIGraphicsBeginImageContext(frame.size)
        tempPath = UIBezierPath(rect: self.frame)
        UIColor.red.setStroke()
        tempPath.lineWidth = 1.5
        path = UIBezierPath(rect: self.frame)

    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let scale :CGFloat = 10
    public func begin(_ x: CGFloat, _ y: CGFloat) {
        var currentLocation: CGPoint = CGPoint()
        currentLocation.x = x * scale
        currentLocation.y = y * scale
        print("dotData move : \(currentLocation)")
        lines.append(currentLocation)
        tempPath.move(to: currentLocation)
    }
    
    public func move(_ x: CGFloat, _ y: CGFloat) {
        var currentLocation: CGPoint = CGPoint()
        currentLocation.x = x * scale
        currentLocation.y = y * scale
        print("dotData addLine: \(currentLocation)")
        lines.append(currentLocation)
        tempPath.addLine(to: currentLocation)
        setNeedsDisplay()
    }
    
    public func end(){
        print("dotData End")
//        draw(self.frame)
//        tempPath.stroke()
//        tempPath.removeAllPoints()
        setNeedsDisplay()
        return
    }
    
    public override func draw(_ rect: CGRect) {
        print("dotData draw line")
        drawlinewithrealtime()
    }
    
    func drawlinewithrealtime(){
        tempPath.stroke()
    }
    
    func drawline(){
        if let context = UIGraphicsGetCurrentContext(){
            context.setStrokeColor(UIColor.red.cgColor)
            context.setLineWidth(4)
            for (i, point) in lines.enumerated(){
                if i == 0{
                    context.move(to: point)
                }else{
                    context.addLine(to: point)
                }
            }
            context.strokePath()
            lines.removeAll()
        }else{
            print("UIGraphicsGetCurrentContext is null")
            
        }
    }
    

    func drawline2(){
        for (i, point) in lines.enumerated(){
            if i == 0{
                path.move(to: point)
            }else{
                path.addLine(to: point)
            }
        }
        path.stroke()
        lines.removeAll()
        
    }
    
    
}
