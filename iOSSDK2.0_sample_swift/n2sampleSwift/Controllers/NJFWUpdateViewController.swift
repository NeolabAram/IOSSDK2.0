//
//  NJFWUpdateViewController.swift
//  n2sampleSwift
//
//  Created by Aram Moon on 2017. 5. 16..
//  Copyright © 2017년 Aram Moon. All rights reserved.
//

import Foundation
import UIKit


class NJFWUpdateViewController: UIViewController, NJFWUpdateDelegate, URLSessionDataDelegate, URLSessionDelegate, URLSessionTaskDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate {

    let kURL_NEOLAB_FW20: String = "http://one.neolab.kr/resource/fw20"
    let kURL_NEOLAB_FW20_JSON: String = "/protocol2.0_firmware.json"
    let kURL_NEOLAB_FW20_F50_JSON: String = "/protocol2.0_firmware_f50.json"

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
        super.init(coder: aDecoder)
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
        let array: [String] = internalFWVersion.components(separatedBy: ".")
        penFWVersion = "\(array[0]).\(array[1])"
        penVersionLabel.text = "Current Version :   v.\(penFWVersion)"
    }
    
    func cancelTask() {
        NJPenCommManager.sharedInstance().cancelFWUpdate = true
        progressBar.progress = 0.0
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
    
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (_ disposition: URLSession.ResponseDisposition) -> Void) {
        completionHandler(.cancel)
        completionHandler(.allow)
        progressBar.progress = 0.0
        downloadSize = Float(response.expectedContentLength)
        dataToDownload = Data()
    }
    
    //Step1. Pen Firmware Version Check With Server
    func requestPage() {
        var url: String = ""
        if NJPenCommManager.sharedInstance().isPenSDK2 {
            let name: String = NJPenCommManager.sharedInstance().deviceName
            if (name == "NWP-F50") {
                url = "\(kURL_NEOLAB_FW20)\(kURL_NEOLAB_FW20_F50_JSON)"
            }
            else {
                url = "\(kURL_NEOLAB_FW20)\(kURL_NEOLAB_FW20_JSON)"
            }
        }

        animateProgressView(false, with: "Checking firmware version from the server...")
        indicator.startAnimating()
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let urlRequest = URLRequest(url: URL(string: url)!)
        
        let task = session.dataTask(with: urlRequest) { (data, uRLResponse, error) in
            if let mdata = data{
                do{
                    let json = try JSONSerialization.jsonObject(with: mdata, options: .mutableLeaves) as! [String : Any]
                    let loc = json["location"] as! String
                    let ver = json["version"] as! String
                    self.fwLoc = loc;                    self.fwVerServer = ver
                    NJPenCommManager.sharedInstance().fwVerServer = self.fwVerServer

                    if isEmpty(self.penFWVersion) || isEmpty(self.fwVerServer) {
                        return
                    }
                    DispatchQueue.main.async() {
                        self.penVersionLabel.text?.append(" ==> \(ver)")
                    }

                    print("FW version : \(ver)")
                    if self.penFWVersion.compare(self.fwVerServer) == .orderedAscending {
                        DispatchQueue.main.async() {
                            let alertVC = UIAlertController(title: "Firmware Update", message:  "Would you like to update the firmware?", preferredStyle: .alert)
                            let OK = UIAlertAction(title: "OK", style: .default, handler: { (UIAlertAction) in
                                self.startFirmwareUpdate()
                            })
                            alertVC.addAction(OK)
                            let Cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                            alertVC.addAction(Cancel)
                            self.present(alertVC, animated: true, completion: nil)
                        }
                    }
                    else {
                        DispatchQueue.main.async() {
                            let alertVC = UIAlertController(title: "", message:  "Pen Firmware version is up-to-date", preferredStyle: .alert)
                            let OK = UIAlertAction(title: "OK", style: .default, handler: nil)
                            alertVC.addAction(OK)

                            self.present(alertVC, animated: true, completion: nil)
                        }
                    }
                } catch{
                    print("Error with Json: \(error)")
                }
                
            }
            DispatchQueue.main.async() {
                self.animateProgressView(true, with: "")
                self.indicator.stopAnimating()
            }
        }
        task.resume()
    }
    
    
    // Step2 Firmware update OK from alertSheet
    func startFirmwareUpdate() {
        print("startFirmwareUpdate")
        if isEmpty(fwLoc) {
            print("file location is empty \(fwLoc)")
            return
        }
        print("startFirmawre Updata \(fwLoc)")
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        var urlStr: String = ""
        if NJPenCommManager.sharedInstance().isPenSDK2 {
            urlStr = "\(kURL_NEOLAB_FW20)\(fwLoc)"
        }
        let urlRequest = URLRequest(url: URL(string: urlStr)!)
        let task = session.downloadTask(with: urlRequest) { (url, response, error) in
            if let tempLocalUrl = url, error == nil {
                // Success
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    print("Success: \(statusCode)")
                }
                
                do {
                    let documentsDirectoryPath = URL(fileURLWithPath: NSTemporaryDirectory())
                    let fileURL: URL = documentsDirectoryPath.appendingPathComponent("NEO1.zip")
                    try FileManager.default.copyItem(at: tempLocalUrl, to: fileURL)
                    NJPenCommManager.sharedInstance().sendUpdateFileInfoAtUrl(toPen: fileURL)
                    self.animateProgressView(false, with: "Start updating pen firmware...")
                    self.indicator.startAnimating()
                } catch (let writeError) {
                    print("error writing file : \(writeError)")
                }
                
            } else {
                print("Failure:\(String(describing: error))");
            }
        }
        task.resume()
        progressBar.progress = 0.0
        animateProgressView(false, with: "Downloading from the server...")
        indicator.startAnimating()
    }
    
    //MARK: - NJFWUpdateDelegate -
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
    
    
    
}
