//
//  NJFWUpdateViewController.swift
//  n2sampleSwift
//
//  Created by Aram Moon on 2017. 5. 16..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation
import UIKit

var kURL_NEOLAB_FW20: String = "http://one.neolab.kr/resource/fw20"
var kURL_NEOLAB_FW20_JSON: String = "/protocol2.0_firmware.json"
var kURL_NEOLAB_FW20_F50_JSON: String = "/protocol2.0_firmware_f50.json"

class NJFWUpdateViewController: UIViewController {//,UIAlertViewDelegate, NJFWUpdateDelegate, URLSessionDataDelegate, URLSessionDelegate, URLSessionTaskDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate {
    /*
    @IBOutlet var indicator: UIActivityIndicatorView!
    @IBOutlet var penVersionLabel: UILabel!
    @IBOutlet var progressView: UIView!
    @IBOutlet var progressViewLabel: UILabel!
    @IBOutlet var progressBar: UIProgressView!

    var penFWVersion: String = ""
    var counter: Int = 0
    var responseData: Data?
    var connection: NSURLConnection?
    var fwVerServer: String = ""
    var fwLoc: String = ""
    var dataToDownload: Data?
    var downloadSize: Float = 0.0
    
    
    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: Bundle!) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        initVC()
        updatePenFWVerision()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        requestPage()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelTask()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initVC() {
        progressView.alpha = 0.0
        progressViewLabel.text = ""
        animateProgressView(true, with: "")
        progressBar.progress = 0.0
        NJPenCommManager.sharedInstance().setFWUpdateDelegate(self)
    }
    
    func updatePenFWVerision() {
        let internalFWVersion: String = NJPenCommManager.sharedInstance().getFWVersion()
        let array: [Any] = internalFWVersion.components(separatedBy: ".")
        penFWVersion = "\(array[0]).\(array[1])"
        penVersionLabel.text = "Current Version :   v.\(penFWVersion)"
    }
    
    func cancelTask() {
        NJPenCommManager.sharedInstance().cancelFWUpdate = true
        progressBar.progress = 0.0
    }
    
    func fwUpdateDataReceive(_ status: FW_UPDATE_DATA_STATUS, percent: Float) {
        if status == FW_UPDATE_DATA_RECEIVE_END {
            indicator.stopAnimating()
            animateProgressView(true, with: "")
            let alert = UIAlertView(title: "Firmware Update", message: "Firmware Update has been completed successfully!", delegate: nil, cancelButtonTitle: "OK", otherButtonTitles: "")
            alert.show()
        }
        else if status == FW_UPDATE_DATA_RECEIVE_FAIL {
            animateProgressView(true, with: "")
            cancelTask()
            indicator.stopAnimating()
            let alert = UIAlertView(title: "Firmware Update", message: "Firmware Update has been failed! Please try it again.", delegate: nil, cancelButtonTitle: "OK", otherButtonTitles: "")
            alert.show()
        }
        else {
            progressBar.progress = (percent / 100.0)
            counter += 1
            if ((counter % 10) == 5) {
                progressViewLabel.text = String(format: "Updating pen firmware (%2d%%)", Int(percent))
            }
        }
        
    }
    
    func animateProgressView(_ hide: Bool, with message: String) {
        if !hide {
            progressViewLabel.text = message
        }
        UIView.animate(withDuration: 0.3, delay: (0.1), options: [.curveLinear, .allowUserInteraction], animations: {(_: Void) -> Void in
            if !hide {
                self.progressView.alpha = 1.0
            }
            else {
                self.progressView.alpha = 0.0
            }
        }, completion: {(_ finished: Bool) -> Void in
        })
    }
    
    func startFirmwareUpdate() {
        let defaultConfigObject = URLSessionConfiguration.default
        let defaultSession = URLSession(configuration: defaultConfigObject, delegate: self, delegateQueue: OperationQueue.main)
        if isEmpty(fwLoc) {
            return
        }
        var urlStr: String
        if NJPenCommManager.sharedInstance().isPenSDK2 {
            urlStr = "\(kURL_NEOLAB_FW20)\(fwLoc)"
        }
        let url = URL(string: urlStr)
        let dataTask: URLSessionDataTask? = defaultSession.dataTask(with: url!)
            //defaultSession.dataTask(withURL: url)
        dataTask?.resume()
        progressBar.progress = 0.0
        animateProgressView(false, with: "Downloading from the server...")
        indicator.startAnimating()
    }
    
    func urlSession(session: URLSession, dataTask: URLSessionDataTask, didReceiveResponse response: URLResponse, completionHandler: @escaping (_ disposition: URLSession.ResponseDisposition) -> Void) {
        completionHandler(NO)
        completionHandler(NSURLSessionResponseAllow)
        progressBar.progress = 0.0
        downloadSize = Float(response.expectedContentLength)
        dataToDownload = Data()
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceiveData data: Data) {
        dataToDownload.append(data)
        progressBar.progress = dataToDownload!.length / downloadSize
        if progressBar.progress == 1.0 {
            indicator.stopAnimating()
            let documentsDirectoryPath = URL(fileURLWithPath: NSTemporaryDirectory())
            let fileURL: URL? = documentsDirectoryPath.appendingPathComponent("NEO1.zip")
            let filePath: String? = fileURL?.path
            try? dataToDownload?.write(to: filePath, options: .atomic)
            NJPenCommManager.sharedInstance().sendUpdateFileInfoAtUrl(toPen: fileURL)
            animateProgressView(false, with: "Start updating pen firmware...")
            indicator.startAnimating()
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        //download 100% complete
        if error != nil {
            print("error \(error)")
            if error?._code == -1009 {
                let alert = UIAlertView(title: "", message: "There is a problem with a network connection.", delegate: nil, cancelButtonTitle: "OK", otherButtonTitles: "")
                alert.show()
            }
            else {
                let alert = UIAlertView(title: "", message: "Error occurs. Please try it again.", delegate: nil, cancelButtonTitle: "OK", otherButtonTitles: "")
                alert.show()
            }
            animateProgressView(true, with: nil)
            indicator.stopAnimating()
        }
    }
    
    func requestPage() {
        responseData = Data.subdata
        var url: String
        if NJPenCommManager.sharedInstance().isPenSDK2 {
            let name: String = NJPenCommManager.sharedInstance().deviceName
            if (name == "NWP-F50") {
                url = "\(kURL_NEOLAB_FW20)\(kURL_NEOLAB_FW20_F50_JSON)"
            }
            else {
                url = "\(kURL_NEOLAB_FW20)\(kURL_NEOLAB_FW20_JSON)"
            }
        }
        let request = URLRequest(url: URL(string: url)!)
        connection = NSURLConnection(request: request, delegate: self)
        animateProgressView(false, with: "Checking firmware version from the server...")
        indicator.startAnimating()
    }
    
    // MARK:
    // MARK: -- NSURLConnection Delegate Mehods
    func connection(_ connection: NSURLConnection, didReceive response: URLResponse) {
        print("didReceiveResponse")
        responseData?.count = 0
    }
    
    @objc(connection:didReceiveData:) func connection(_ connection: NSURLConnection, didReceive data: Data) {
        responseData.append(data)
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error?) {
        print("didFailWithError")
        print("error \(error)")
        if error?._code == -1009 {
            let alert = UIAlertView(title: "", message: "There is a problem with a network connection.", delegate: nil, cancelButtonTitle: "OK", otherButtonTitles: "")
            alert.show()
        }
        else {
            let alert = UIAlertView(title: "", message: "Error occurs. Please try it again.", delegate: nil, cancelButtonTitle: "OK", otherButtonTitles: "")
            alert.show()
        }
        animateProgressView(true, with: nil)
        indicator.stopAnimating()
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        print("connectionDidFinishLoading")
        let e: Error? = nil
        let json: [AnyHashable: Any]? = try? JSONSerialization.jsonObject(withData: responseData, options: NSJSONReadingMutableLeaves)
        let loc: String? = (json?["location"] as? String)
        let ver: String? = (json?["version"] as? String)
        fwLoc = loc!
        fwVerServer = ver!
        NJPenCommManager.sharedInstance().fwVerServer = fwVerServer
        if json == nil {
            print("Error parsing JSON: \(e)")
        }
        if isEmpty(penFWVersion) || isEmpty(fwVerServer) {
            return
        }
        animateProgressView(true, with: "")
        indicator.stopAnimating()
        if penFWVersion.compare(fwVerServer) == .orderedAscending {
            let alert = UIAlertView(title: "Firmware Update", message: "Would you like to update the firmware?", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "OK")
            alert.tag = 0
            alert.show()
        }
        else {
            let alert = UIAlertView(title: "", message: "Pen Firmware version is up-to-date", delegate: self, cancelButtonTitle: "OK", otherButtonTitles: "")
            alert.tag = 1
            alert.show()
        }
    }
    
    func alertView(_ alertView: UIAlertView, clickedButtonat buttonIndex: Int) {
        if alertView.tag == 0 {
            if buttonIndex == alertView.firstOtherButtonIndex {
                startFirmwareUpdate()
            }
            else if buttonIndex == alertView.cancelButtonIndex {
                
            }
        }
        else if alertView.tag == 1 {
            
        }
        
    }
 */
}
