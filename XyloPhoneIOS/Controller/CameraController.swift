//
//  CameraController.swift
//  XyloPhoneIOS
//
//  Created by joseph Emmanuel Dayo on 8/19/21.
//
import UIKit
import AVFoundation

class CameraController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let ciContext = CIContext()
    weak open var delegate: (CameraControllerDelegate)?
    @IBOutlet weak var CaptureButton: UIButton!
    @IBOutlet weak var zoomSlider: UISlider!
    @IBOutlet weak var previewView: UIImageView!
    weak var videoDevice: AVCaptureDevice?
    var currentCrop: Float = 512.0
    
    private var inProgressPhotoCaptureDelegates = [Int64: PhotoCaptureProcessor]()
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.width)
        self.previewView.bringSubviewToFront(CaptureButton)
        self.previewView.contentMode = .scaleAspectFill
    }
    
    @IBAction func wbChanged(_ sender: UISlider) {
        let wbValue = (sender.value * 6500.0)
        let device = self.videoDeviceInput.device
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            let whiteBalanceGain = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(temperature: wbValue, tint: 0.0)
            device.setWhiteBalanceModeLocked(with: device.deviceWhiteBalanceGains(for: whiteBalanceGain), completionHandler: { _ in
                    NSLog("White balance locked")
                })
        } catch {
            NSLog("Error!")
        }
    }
    
    
    @IBAction func zoomChanged(_ sender: UISlider) {
        self.currentCrop = (1 - sender.value) * (3024.0 - 512.0) + 512.0
        NSLog("value set to \(self.currentCrop)")
    }
    
    @IBAction func Capture(_ sender: Any) {
        sessionQueue.async {
            if let photoOutputConnection = self.photoOutput.connection(with: .video) {
                photoOutputConnection.videoOrientation = .portrait
            }
            var photoSettings = AVCapturePhotoSettings()
            
            // Capture HEIF photos when supported. Enable auto-flash and high-resolution photos.
            if  self.photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            }
            
            if self.videoDeviceInput.device.isFlashAvailable {
                photoSettings.flashMode = .off
            }
            

            photoSettings.isHighResolutionPhotoEnabled = true
            photoSettings.photoQualityPrioritization = .quality

            let photoCaptureProcessor = PhotoCaptureProcessor(with: photoSettings, willCapturePhotoAnimation: {}, livePhotoCaptureHandler: { _ in }, completionHandler: {
                photoCaptureProcessor, data in
                    // When the capture is complete, remove a reference to the photo capture delegate so it can be deallocated.
                    self.sessionQueue.async {
                        self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = nil
                        DispatchQueue.main.async {
                            NSLog("photo capture done!")
                            
                            self.delegate?.didCaptureImage(photoOutput: data!, cropSize: self.currentCrop)
                            self.dismiss(animated: true)
                        }
                    }

            }, photoProcessingHandler:  { _ in })
           
    
            self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = photoCaptureProcessor
            self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
        }
    }
    
    
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    
    var windowOrientation: UIInterfaceOrientation {
        return view.window?.windowScene?.interfaceOrientation ?? .unknown
    }
    
    // Communicate with the session and other session objects on this queue.
    private let sessionQueue = DispatchQueue(label: "session queue")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) != .authorized
        {
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler:
            { (authorized) in
                DispatchQueue.main.async
                {
                    if authorized
                    {
                        self.sessionQueue.async {
                            self.configureSession()
                        }
                    }
                }
            })
        } else {
            self.sessionQueue.async {
                self.configureSession()
            }
        }
    }
    
    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            // Choose the back dual camera, if available, otherwise default to a wide angle camera.
            
            if let telephotoCamera = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back) {
                defaultVideoDevice = telephotoCamera
            } else if let dualWideCameraDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
                // If a rear dual camera is not available, default to the rear dual wide camera.
                defaultVideoDevice = dualWideCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                // If a rear dual wide camera is not available, default to the rear wide angle camera.
                defaultVideoDevice = backCameraDevice
            }
            
            self.videoDevice = defaultVideoDevice
            
            guard let videoDevice = defaultVideoDevice else {
                print("Default video device is unavailable.")
                session.commitConfiguration()
                return
            }
            
            
            NSLog("camera \(defaultVideoDevice.debugDescription)")
            NSLog("Current format: %@, max zoom factor: %f", videoDevice.activeFormat, videoDevice.maxAvailableVideoZoomFactor);
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput

                do {
                    try videoDevice.lockForConfiguration()
                    defer { videoDevice.unlockForConfiguration() }

                    if videoDevice.isWhiteBalanceModeSupported(.locked) {
                        NSLog("device type \(UIDevice().type)")
                        let whiteBalanceGain = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(temperature: 5700.0, tint: 0.0)
                            videoDevice.setWhiteBalanceModeLocked(with: videoDevice.deviceWhiteBalanceGains(for: whiteBalanceGain), completionHandler: { _ in
                                NSLog("White balance locked")
                            })
                    }
                } catch {
                    NSLog("Unable to lock device")
                }
                
            } else {
                print("Couldn't add video device input to the session.")
                session.commitConfiguration()
                return
            }

        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
            photoOutput.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliverySupported
            photoOutput.isPortraitEffectsMatteDeliveryEnabled = photoOutput.isPortraitEffectsMatteDeliverySupported
            photoOutput.enabledSemanticSegmentationMatteTypes = photoOutput.availableSemanticSegmentationMatteTypes
            photoOutput.maxPhotoQualityPrioritization = .quality
            
        } else {
            print("Could not add photo output to the session")
            session.commitConfiguration()
            return
        }
        
            
        if session.canAddOutput(videoOutput) {
            videoOutput.automaticallyConfiguresOutputBufferDimensions = false
            videoOutput.deliversPreviewSizedOutputBuffers = false
            videoOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA]
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "my.image.handling.queue"))
            session.addOutput(videoOutput)
        }
            
        session.commitConfiguration()

        session.startRunning()
        

        } catch {
            print("Couldn't create video device input: \(error)")
            session.commitConfiguration()
            return
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        connection.videoOrientation = .portrait
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            debugPrint("unable to get image from sample buffer")
            return
        }
        let imageBuffer: CVImageBuffer? = frame
        let sourceImage = CIImage(cvPixelBuffer: imageBuffer!, options: nil)
        let sourceExtent: CGRect = sourceImage.extent
        
        let newCropSize = CGFloat(self.currentCrop);
        let x = sourceExtent.width / 2.0 - newCropSize/2.0;
        let y = sourceExtent.height / 2.0 - newCropSize/2.0;

        let cropRect = CGRect(x: x, y: y, width: newCropSize, height: newCropSize);
        let croppedImage = sourceImage.cropped(to: cropRect)
        let cgImage = self.ciContext.createCGImage(croppedImage, from: croppedImage.extent)
        DispatchQueue.main.async {
            let filteredImage = UIImage(cgImage: cgImage!)
            self.previewView.image = filteredImage
        }
    }
}
