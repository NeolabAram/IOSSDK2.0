//
//  PDFController.swift
//  n2sampleSwift
//
//  Created by Aram Moon on 2017. 6. 1..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation

class PDFController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let filePath = Bundle.main.path(forResource: "pdf601", ofType: "pdf"){
            print (filePath)
            var document:  CGPDFDocument!
            let url = NSURL.fileURL(withPath: filePath)
            let CFUrl = url as CFURL
            document =  CGPDFDocument(CFUrl)
            if let pdfImage = PDFtoImage(document, 1, CGRect(x: 250, y: 44, width: 500, height: 700)){
                let vv = UIImageView(image: pdfImage)
                self.view.addSubview(vv)
            }
        } else {
            print("Invalid PDF file path")
        }
        
        
        if let filePath = Bundle.main.path(forResource: "n601", ofType: "nproj"){
            print ("nproj \(filePath)")
            let url = NSURL.fileURL(withPath: filePath)
            var parser = XMLParser(contentsOf: url)
            parser?.delegate = self
            if let success = parser?.parse(){
                if success{
                    print("parsing success")
                }else{
                    print("parsing fail")
                }
            }
        } else {
            print("Invalid Nproj file path")
        }
    }
    
    func PDFtoImage(_ PdfDoc : CGPDFDocument,_ pageNumber : Int,_ Rect : CGRect) -> UIImage?{
        guard let page = PdfDoc.page(at: pageNumber) else {
            return nil
        }
        
        let pageRect = page.getBoxRect(.mediaBox)
        
        guard !pageRect.width.isZero && !pageRect.height.isZero else {
            return nil
        }
        
        if #available(iOS 10.0, *) {
            let renderer = UIGraphicsImageRenderer(size: Rect.size)
            
            let img = renderer.image { ctx in
                UIColor.white.set()
                ctx.fill(Rect)
                ctx.cgContext.translateBy(x: 0.0, y: Rect.height);
                let scaleX = Rect.width / pageRect.width
                let scaleY = Rect.height / pageRect.height
                ctx.cgContext.scaleBy(x: scaleX, y: -scaleY);
                ctx.cgContext.drawPDFPage(page);
            }
            return img
        } else {
            // Fallback on earlier versions
        }
        return nil
    }
    
    var version22 = true
    var xmlTag = ""
}

extension PDFController : XMLParserDelegate{
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        print("didStartElement", elementName, attributeDict)
        xmlTag = elementName
        switch elementName {
        case "nproj":
            version22 = (attributeDict["version"] == "2.2")
        case "book":
            print(attributeDict)
        default:
            print("not define")
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        print("elementName",elementName)
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch xmlTag {
        case "title":
            print(xmlTag,string)
        default:
            print("not define tag")
        }
        
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("parseErrorOccurred",parseError)
        
    }
    
}
