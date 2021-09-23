//
//  CameraController.swift
//  XyloPhoneIOS
//
//  Created by joseph Emmanuel Dayo on 8/19/21.
//
import UIKit
import AVFoundation

class CameraController: UIViewController {
    private let session = AVCaptureSession()
    
    @IBOutlet weak var previewView: CameraPreviewView!
    
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    
    var windowOrientation: UIInterfaceOrientation {
        return view.window?.windowScene?.interfaceOrientation ?? .unknown
    }
    
    // Communicate with the session and other session objects on this queue.
    private let sessionQueue = DispatchQueue(label: "session queue")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view
        
        previewView.session = session
        
        sessionQueue.async {
            self.configureSession()
        }
    }
    
    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            // Choose the back dual camera, if available, otherwise default to a wide angle camera.
            
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let dualWideCameraDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
                // If a rear dual camera is not available, default to the rear dual wide camera.
                defaultVideoDevice = dualWideCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                // If a rear dual wide camera is not available, default to the rear wide angle camera.
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                // If the rear wide angle camera isn't available, default to the front wide angle camera.
                defaultVideoDevice = frontCameraDevice
            }
            guard let videoDevice = defaultVideoDevice else {
                print("Default video device is unavailable.")
                session.commitConfiguration()
                return
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                DispatchQueue.main.async {
                    /*
                     Dispatch video streaming to the main queue because AVCaptureVideoPreviewLayer is the backing layer for PreviewView.
                     You can manipulate UIView only on the main thread.
                     Note: As an exception to the above rule, it's not necessary to serialize video orientation changes
                     on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                     
                     Use the window scene's orientation as the initial video orientation. Subsequent orientation changes are
                     handled by CameraViewController.viewWillTransition(to:with:).
                     */
                    self.previewView.videoPreviewLayer.connection?.videoOrientation = .portrait
                }
            } else {
                print("Couldn't add video device input to the session.")
                session.commitConfiguration()
                return
            }
        } catch {
            print("Couldn't create video device input: \(error)")
            session.commitConfiguration()
            return
        }
        
        session.commitConfiguration()
        session.startRunning()
    }
}
