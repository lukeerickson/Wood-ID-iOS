//
//  SettingsController.swift
//  XyloPhoneIOS
//
//  Created by joseph Emmanuel Dayo on 2/4/22.
//

import Foundation
import AVFoundation
import UIKit

class SettingsController: UIViewController, UITextFieldDelegate  {
    @IBOutlet weak var isoTextField: UITextField!
    
    @IBOutlet weak var zoomFactorTextField: UITextField!
    
    @IBOutlet weak var shutterSpeedTextField: UITextField!
    
    @IBOutlet weak var colorTempTextField: UITextField!
    
    private let userDefaults = UserDefaults()
    
    @IBOutlet weak var enableCalibrationSwitch: UISwitch!
    
    @IBOutlet weak var openRecalibrateCamera: UIButton!
    
    @IBAction func recalibrateCamera(_ sender: Any) {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
            case .authorized: // The user has previously granted access to the camera.
                NSLog("Authorized?")
                let cameraController = self.storyboard?.instantiateViewController(withIdentifier: "CameraController") as! CameraController
                
                cameraController.modalPresentationStyle = .fullScreen
                cameraController.calibrationModeEnabled = true
                present(cameraController, animated: true)
               return
           case .notDetermined: // The user has not yet been asked for camera access.
            NSLog("Not Authorized?")
               AVCaptureDevice.requestAccess(for: .video) { granted in
                   if granted {
                    let cameraController = CameraController()
                    cameraController.modalPresentationStyle = .fullScreen
                    self.present(cameraController, animated: true)
                   }
               }
           return
           case .denied: // The user has previously denied access.
            NSLog("denied")
               return

           case .restricted: // The user can't grant access due to restrictions.
            NSLog("restricted")
            return
        @unknown default:
            NSLog("unknown status")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        // Do any additional setup after loading the view.
        zoomFactorTextField.text = self.userDefaults.string(forKey: "current_crop")
        shutterSpeedTextField.text = self.userDefaults.string(forKey: "exposure_duration")
        colorTempTextField.text = self.userDefaults.string(forKey: "color_temperature")
        isoTextField.text = self.userDefaults.string(forKey: "iso")
        zoomFactorTextField.delegate = self
        shutterSpeedTextField.delegate = self
        colorTempTextField.delegate = self
        isoTextField.delegate = self
    }
    
    var windowOrientation: UIInterfaceOrientation {
        return view.window?.windowScene?.interfaceOrientation ?? .unknown
    }
    
    @IBAction func updateSettings(_ sender: Any) {
        if let zoomFactor = zoomFactorTextField.text {
            self.userDefaults.set(Float(zoomFactor), forKey: "current_crop")
        }
        
        if let shutterSpeed = shutterSpeedTextField.text  {
            self.userDefaults.set(Int(shutterSpeed), forKey: "exposure_duration")
        }
        
        if let colorTemp = colorTempTextField.text {
            self.userDefaults.set(Float(colorTemp), forKey: "color_temperature")
        }
        
        if let iso = isoTextField.text {
            self.userDefaults.set(Int(iso), forKey: "iso")
        }
        
        self.dismiss(animated: true)
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
