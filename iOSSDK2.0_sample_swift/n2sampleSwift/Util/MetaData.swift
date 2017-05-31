//
//  MetaData.swift
//  n2sampleSwift
//
//  Created by Aram Moon on 2017. 5. 30..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation

class MetaData {
    static func processStepInstallNewNotebookInfos(){
        DispatchQueue.global(qos: .default).async(execute: {() -> Void in
            let notebookInfos = Bundle.main.paths(forResourcesOfType: "zip", inDirectory: "books_2016_02")
            for path in notebookInfos {
                let fileURL = URL(fileURLWithPath: path )
                let fileNameWithEX: String = (path as AnyObject).lastPathComponent
                let filename : String = (NSURL(fileURLWithPath: fileNameWithEX).deletingPathExtension?.relativePath)!
                
                //(path as AnyObject).lastPathComponent.deletingPathExtension
                if !filename.hasPrefix("note_") {
                    continue
                }
                var notebookId: Int = 0
                let tokens: [String] = filename.components(separatedBy: "_")
                var shouldDeleteExisiting: Bool = true
                if tokens.count > 3 || tokens.count < 2 {
                    continue
                }
                if tokens.count == 3 {
                    shouldDeleteExisiting = (Int(tokens[2]) == 0) ? true : false
                    notebookId = Int(tokens[1])!
                }
                else if tokens.count == 2 {
                    notebookId = Int(tokens[1])!
                }
                
                if notebookId <= 0 {
                    continue
                }
                var section: Int = 3
                var owner: Int = 27
                (section,owner) = NJPage.SectionOwner(fromNotebookId: notebookId)
                print("Usenote id \(notebookId)")
                print("Usenote section: + \(section) owner \(owner)" )
                
                let keyName: String = NPPaperManager.keyName(forNotebookId: UInt(notebookId), section: UInt(section), owner: UInt(owner))
                NPPaperManager.sharedInstance().installNotebookInfo(forKeyName: keyName, zipFilePath: fileURL, deleteExisting: shouldDeleteExisiting)
            }
        })
    }

}
