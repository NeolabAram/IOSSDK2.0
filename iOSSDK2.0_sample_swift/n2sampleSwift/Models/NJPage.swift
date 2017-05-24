//
//  NJPage.swift
//  n2sampleSwift
//
//  Created by Aram Moon on 2017. 5. 16..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

let MAX_NODE_NUMBER = 1024

class NJPage: NSObject {
    var strokes = [Any]()
    var isPageHasChanged: Bool = false
    var bounds = CGRect.zero
    var image: UIImage?
    var paperSize = CGSize.zero
    //notebook size
    var screenRatio: CGFloat = 10.0
    var notebookId: Int = 0
    var pageNumber: Int = 0
    var inputScale: CGFloat = 0.0
    var penColor: UInt32 = 0
    var startX: CGFloat = 0.0
    var startY: CGFloat = 0.0
    var paperInfo: NPPaperInfo!
    
    var renderingPath: UIBezierPath?
    var page_x: CGFloat = 0.0
    var page_y :CGFloat = 0.0

    var section : Int = 3
    var owner : Int = 27
    
    deinit {
//        strokes = nil
        renderingPath = nil
        paperInfo = nil
    }
    
    init(notebookId: Int, andPageNumber pageNumber: Int) {
        super.init()
        self.notebookId = notebookId
        self.pageNumber = pageNumber
        strokes = [Any]()
        (section,owner) = NJPage.SectionOwner(fromNotebookId: notebookId)
        //from both plist and nproj
        paperInfo = NJNotebookPaperInfo.sharedInstance().getNoteForNotebook( Int32(notebookId), pageNum: Int32(Int(pageNumber)), section: Int32(Int(section)), owner: Int32(Int(owner)))
        page_x = (paperInfo.width)
        page_y = (paperInfo.height)
        startX = (paperInfo.startX)
        startY = (paperInfo.startY)
        var paperSize: CGSize = CGSize()
        paperSize.width = CGFloat(page_x)
        paperSize.height = CGFloat(page_y)
        /* set paper size and input scale. Input scale is used to nomalize stroke data */
        self.paperSize = paperSize
        isPageHasChanged = false
    }

    
    func setPaperSize(paperSize: CGSize) {
        self.paperSize = paperSize
        inputScale = max(paperSize.width, paperSize.height)
    }
    
    func addStrokes(stroke: NJStroke) {
        strokes.append(stroke)
        isPageHasChanged = true
    }
    
    func getBackgroundImage() -> UIImage {
        var image: UIImage? = nil
        let noteId: Int = notebookId
        var pageNum: Int = pageNumber
        (section,owner) = NJPage.SectionOwner(fromNotebookId: notebookId)
        //from nproj
        image = NPPaperManager.sharedInstance().getDefaultBackGroundImage(forPageNum: UInt(pageNum), notebookId: UInt(noteId), section: UInt(section), owner: UInt(owner))
        if isEmpty(image) {
            //from plist
            let pdfFileName: String? = NJNotebookPaperInfo.sharedInstance().backgroundFileName(forSection: 0, owner: 0, note: UInt32(noteId))
            if pdfFileName != nil {
                let pdfURL: URL? = Bundle.main.url(forResource: pdfFileName, withExtension: nil)
                var PDFDocRef: CGPDFDocument? = CGPDFDocument((pdfURL as CFURL?)!)
                if PDFDocRef != nil {
                    if pageNum < 1 {
                        pageNum = 1
                    }
                    let pages: Int = PDFDocRef!.numberOfPages
                    if pageNum > pages {
                        pageNum = pages
                    }
                    let pdfPage: CGPDFPage? = (PDFDocRef?.page(at: pageNum))!
                    if pdfPage == nil {
                        // TODO: need to fix
//                        CGPDFDocumentRelease(PDFDocRef!)
                        PDFDocRef = nil
                    }
                    image = PDFPageConverter.convertPDFPage(toImage: pdfPage, withResolution: 144)
                }
            }
        }
        if image == nil{
            image = UIImage(named: "settings_number_4_press")
        }
        return image!
    }


    func drawPage(image: UIImage?, size bounds: CGRect, drawBG: Bool, opaque: Bool) -> UIImage {
        var tempImage = image
        var imageBounds: CGRect = bounds
        if tempImage == nil {
            if drawBG {
                tempImage = getBackgroundImage()
            }
        }
        else {
            // For drawInRect, if the image size does not fit it will resize image.
            imageBounds.size = (image?.size)!
        }
        autoreleasepool { () -> UIImage in
            UIGraphicsBeginImageContextWithOptions(bounds.size, opaque, 0.0)
            if (tempImage != nil) {
                tempImage?.draw(in: imageBounds)
            }
            else {
                if opaque {
                    let rectpath = UIBezierPath(rect: bounds)
                    UIColor(white: CGFloat(0.95), alpha: CGFloat(1)).setFill()
                    rectpath.fill()
                }
            }
            let paperSize: CGSize = self.paperSize
            let xRatio: Float = Float(bounds.size.width / paperSize.width)
            let yRatio: Float = Float(bounds.size.height / paperSize.height)
            let screenRatio: Float = (xRatio > yRatio) ? yRatio : xRatio
            for i in 0..<strokes.count {
                let stroke: NJStroke? = strokes[i] as! NJStroke
                stroke?.render(withScale: CGFloat(screenRatio))
            }
            let newImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage!
        }
        return tempImage!
    }
    
    func draw(stroke: NJStroke, imageIn: UIImage?, size bounds: CGRect, scale: Float, offsetX offset_x: Float, offsetY offset_y: Float, drawBG: Bool, opaque: Bool) -> UIImage {
        var image = imageIn
        var imageBounds: CGRect = bounds
        if image == nil {
            if drawBG {
                image = getBackgroundImage()
            }
        }
        else {
            // For drawInRect, if the image size does not fit it will resize image.
            imageBounds.size = bounds.size
        }
        autoreleasepool { () -> UIImage in 
            // autoreleasepool added by namSSan 2015-02-13 - refer to
            //http://stackoverflow.com/questions/19167732/coregraphics-drawing-causes-memory-warnings-crash-on-ios-7
            //UIGraphicsBeginImageContextWithOptions(bounds.size, YES, 0.0);
            UIGraphicsBeginImageContextWithOptions(bounds.size, opaque, 0.0)
            if (image != nil) {
                image?.draw(in: imageBounds)
            }
            else {
                if opaque {
                    let rectpath = UIBezierPath(rect: bounds)
                    UIColor(white: CGFloat(0.95), alpha: CGFloat(1)).setFill()
                    rectpath.fill()
                }
            }
            let paperSize: CGSize = self.paperSize
            let xRatio: Float = Float(bounds.size.width / paperSize.width)
            let yRatio: Float = Float(bounds.size.height / paperSize.height)
            let screenRatio: Float = (xRatio > yRatio) ? yRatio : xRatio
            stroke.render(withScale: CGFloat(inputScale))
            let newImg: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImg!
        }
        return image!
    }

    
    func imageSize(size: Int) -> CGRect {
        let targetShortSize: CGFloat = CGFloat((size == 0) ? 1024 : size)
        var ratio: CGFloat = 1
        var shortSize: CGFloat
        if page_x < page_y {
            shortSize = page_x
        }
        else {
            shortSize = page_y
        }
        ratio = targetShortSize / shortSize
        var retSize: CGSize = CGSize()
        retSize.width = CGFloat(page_x * ratio)
        retSize.height = CGFloat(page_y * ratio)
        var ret: CGRect = CGRect()
        ret.size = retSize
        let origin: CGPoint = CGPoint(x: 0, y: 0)
        ret.origin = origin
        return ret
    }
    
    static func SectionOwner(fromNotebookId notebookId: Int) -> (Int, Int) {
        var tempSection : Int = 3
        var tempOwner : Int = 27
        if (notebookId == 605) || (notebookId == 606) || (notebookId == 608) {
            tempSection = 0
        }
        if (notebookId == 101) || (notebookId == 6) {
            tempSection = 5
            tempOwner = 6
        }
        return (tempSection, tempOwner)
    }

}
