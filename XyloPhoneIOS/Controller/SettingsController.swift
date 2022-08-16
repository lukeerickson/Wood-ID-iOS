//
//  SettingsController.swift
//  XyloPhoneIOS
//
//  Created by joseph Emmanuel Dayo on 2/4/22.
//

import Foundation
import AVFoundation
import UIKit
import CoreData

class SettingsController: UIViewController, UITextFieldDelegate, CameraControllerDelegate, UIDocumentPickerDelegate, UIPickerViewDelegate, UIPickerViewDataSource  {

    
    @IBOutlet weak var isoTextField: UITextField!
    
    @IBOutlet weak var zoomFactorTextField: UITextField!
    
    @IBOutlet weak var shutterSpeedTextField: UITextField!
    
    @IBOutlet weak var redGainTextField: UITextField!
    
    @IBOutlet weak var greenGainTextField: UITextField!
    
    @IBOutlet weak var blueGainTextField: UITextField!
    
    @IBOutlet weak var modelVersion: UILabel!
    
    @IBOutlet weak var modelDescription: UILabel!
    
    private let userDefaults = UserDefaults()
    
    @IBOutlet weak var cameraSelector: UIPickerView!
    @IBOutlet weak var enableCalibrationSwitch: UISwitch!
    
    @IBOutlet weak var openRecalibrateCamera: UIButton!
    
    fileprivate func presentCameraCalibration(_ cameraController: CameraController) {
        cameraController.modalPresentationStyle = .fullScreen
        cameraController.calibrationModeEnabled = true
        cameraController.cameraIndex = cameraSelector.selectedRow(inComponent: 0)
        cameraController.delegate = self
        DispatchQueue.main.async {
            self.present(cameraController, animated: true)
        }
    }
    
    @IBAction func recalibrateCamera(_ sender: Any) {
        let cameraController = self.storyboard?.instantiateViewController(withIdentifier: "CameraController") as! CameraController
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
            case .authorized: // The user has previously granted access to the camera.
                NSLog("Authorized?")
                presentCameraCalibration(cameraController)
               return
            case .notDetermined: // The user has not yet been asked for camera access.
                NSLog("Not Authorized?")
                AVCaptureDevice.requestAccess(for: .video) { granted in
                   if granted {
                       self.presentCameraCalibration(cameraController)
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
        isoTextField.text = self.userDefaults.string(forKey: "iso")
        redGainTextField.text = self.userDefaults.string(forKey: "red_gain")
        blueGainTextField.text = self.userDefaults.string(forKey: "blue_gain")
        greenGainTextField.text = self.userDefaults.string(forKey: "green_gain")
        modelVersion.text = self.userDefaults.string(forKey: "modelVersion")
        modelDescription.text = self.userDefaults.string(forKey: "modelDescription")
        zoomFactorTextField.delegate = self
        shutterSpeedTextField.delegate = self
        isoTextField.delegate = self
        redGainTextField.delegate = self
        blueGainTextField.delegate = self
        greenGainTextField.delegate = self
        cameraSelector.delegate = self
        cameraSelector.dataSource = self
        cameraSelector.selectRow(self.userDefaults.integer(forKey: "camera_index"), inComponent: 0, animated: false)

        AppUtility.lockOrientation(.portrait)
    }
    
    @IBAction func clearAllData(_ sender: Any) {
        let refreshAlert = UIAlertController(title: "Delete All", message: "All data will be lost. Are you sure you want to continue", preferredStyle: UIAlertController.Style.alert)

        refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            let mainContext = CoreDataManager.shared.mainContext
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "InferenceLogEntity")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try mainContext.persistentStoreCoordinator!.execute(deleteRequest, with: mainContext)
            } catch let error as NSError {
                NSLog(error.description)
            }
        }))

        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
        }))

        present(refreshAlert, animated: true, completion: nil)
    }
    
    @IBAction func updateSettings(_ sender: Any) {
        if let zoomFactor = zoomFactorTextField.text {
            self.userDefaults.set(zoomFactor, forKey: "current_crop")
        }
        
        if let shutterSpeed = shutterSpeedTextField.text  {
            self.userDefaults.set(shutterSpeed, forKey: "exposure_duration")
        }
        
        if let iso = isoTextField.text {
            self.userDefaults.set(iso, forKey: "iso")
        }
        
        if let red = redGainTextField.text {
            self.userDefaults.set(red, forKey: "red_gain")
        }
        
        if let blue = blueGainTextField.text {
            self.userDefaults.set(blue, forKey: "blue_gain")
        }
        
        if let green = greenGainTextField.text {
            self.userDefaults.set(green, forKey: "green_gain")
        }
        
        let cameraIndex = cameraSelector.selectedRow(inComponent: 0)
        self.userDefaults.set(cameraIndex, forKey: "camera_index")
        
        self.dismiss(animated: true)
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func updateModelPicker(_ sender: Any) {
        let types = UTType.types(tag: "zip",
                                     tagClass: UTTagClass.filenameExtension,
                                     conformingTo: nil)
            let documentPickerController = UIDocumentPickerViewController(
                    forOpeningContentTypes: types)
            documentPickerController.delegate = self
            self.present(documentPickerController, animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func didCaptureImage(photoOutput: Data?, cropSize: Float) {
        self.userDefaults.set(cropSize, forKey: "current_crop")
        zoomFactorTextField.text = "\(cropSize)"
        redGainTextField.text = self.userDefaults.string(forKey: "red_gain")
        blueGainTextField.text = self.userDefaults.string(forKey: "blue_gain")
        greenGainTextField.text = self.userDefaults.string(forKey: "green_gain")
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        AppUtility.collectAvailableCameras().count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return AppUtility.collectAvailableCameras()[row].0
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let myURL = urls.first else {
            return
        }
        print("import result : \(myURL.absoluteString)")

        DispatchQueue.global(qos: .default).async {
            if (myURL.startAccessingSecurityScopedResource()) {
                defer {myURL.stopAccessingSecurityScopedResource()}
                if let modelDetails = ModelUtility.installModelFrom(filePath: myURL) {
                   ModelUtility.registerModel(userDefaults: self.userDefaults, modelDetails: modelDetails)
                    if let currentAppDelegate = UIApplication.shared.delegate as! AppDelegate? {
                        currentAppDelegate.resetVisionModule();
                        currentAppDelegate.getSpeciesDatabase()?.loadDatabase();
                    }
                    
                    DispatchQueue.main.async {
                        self.modelVersion.text = self.userDefaults.string(forKey: "modelVersion")
                        self.modelDescription.text = self.userDefaults.string(forKey: "modelDescription")
                    }
                }
            
            } else {
                NSLog("Unable to access resource \(myURL)")
            }
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("view was cancelled")
        dismiss(animated: true, completion: nil)
    }
}
