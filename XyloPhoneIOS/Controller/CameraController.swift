import UIKit
import AVFoundation

class CameraController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let ciContext = CIContext()
    private let userDefaults = UserDefaults()
    weak open var delegate: (CameraControllerDelegate)?
    @IBOutlet weak var CaptureButton: UIButton!
    @IBOutlet weak var zoomSlider: UISlider!
    @IBOutlet weak var previewView: UIImageView!
    weak var videoDevice: AVCaptureDevice?
    var currentCrop: Float = 512.0
    var calibrationModeEnabled: Bool = false
    
    private var inProgressPhotoCaptureDelegates = [Int64: PhotoCaptureProcessor]()
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.width)
        self.previewView.bringSubviewToFront(CaptureButton)
        self.previewView.contentMode = .scaleAspectFill
        if !calibrationModeEnabled {
            zoomSlider.isHidden = true
            
            CaptureButton.isHidden = false
        } else {
            zoomSlider.isHidden = false
            CaptureButton.isHidden = false
        }
    }
    
    @IBAction func wbChanged(_ sender: UISlider) {
       
        let device = self.videoDeviceInput.device
        let wbValue = (sender.value * device.maxWhiteBalanceGain)
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            let whiteBalanceGain = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(temperature: wbValue, tint: 0.0)
            NSLog("wb \(wbValue)")
            self.userDefaults.set(wbValue, forKey: "color_temperature")
            device.setWhiteBalanceModeLocked(with: device.deviceWhiteBalanceGains(for: whiteBalanceGain), completionHandler: { _ in
                    NSLog("White balance locked")
                })
        } catch {
            NSLog("Error!")
        }
    }
    
    
    @IBAction func zoomChanged(_ sender: UISlider) {
        self.currentCrop = (1 - sender.value) * (3024.0 - 512.0) + 512.0
        self.userDefaults.set(self.currentCrop, forKey: "current_crop")
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
                            if let photo = data {
                                NSLog("photo avail")
                                self.session.stopRunning()
                                self.delegate?.didCaptureImage(photoOutput: photo, cropSize: self.currentCrop)
                                self.dismiss(animated: true)
                            }
                            NSLog("No photo avail")
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
    private let sessionQueue = DispatchQueue(label: "session queue as! Data")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var savedCrop: Float32 = 735.0
        if (userDefaults.object(forKey: "current_crop") != nil) {
            savedCrop = max(512.0, userDefaults.float(forKey: "current_crop"))
        }

        NSLog("saved crop = \(savedCrop)")
        self.currentCrop = savedCrop
        zoomSlider.value = 1 - (currentCrop - 512.0) / (3024.0 - 512.0)
        // Do any additional setup after loading the view
        AppUtility.lockOrientation(.portrait)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Don't forget to reset when view is being removed
        AppUtility.lockOrientation(.all)
    }
    
    @IBAction func cancelCapture(_ sender: Any) {
        self.dismiss(animated: true)
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
            NSLog("Current format: %@, min zoom factor: %f, max zoom factor: %f", videoDevice.activeFormat,
                  videoDevice.minAvailableVideoZoomFactor, videoDevice.maxAvailableVideoZoomFactor);
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput

                do {
                    try videoDevice.lockForConfiguration()
                    defer { videoDevice.unlockForConfiguration() }

                    if videoDevice.isWhiteBalanceModeSupported(.locked) {
                        NSLog("device type \(UIDevice().type)")
                        var colorTemperature = Float(videoDevice.maxWhiteBalanceGain / 2)
                        
//                        if (userDefaults.object(forKey: "color_temperature") != nil) {
//                            colorTemperature = max(512.0, userDefaults.float(forKey: "color_temperature"))
//                        }
                        
                        let redGain = Float(userDefaults.string(forKey: "red_gain") ?? "1.0")! * 2.0
                        let greenGain = Float(userDefaults.string(forKey: "green_gain") ?? "1.0")!
                        let blueGain = Float(userDefaults.string(forKey: "blue_gain") ?? "1.0")! * 2.0
                        let gain = AVCaptureDevice.WhiteBalanceGains(redGain: redGain, greenGain: greenGain, blueGain: blueGain)

                        
                        videoDevice.setWhiteBalanceModeLocked(with: gain, completionHandler: { _ in
                            NSLog("White balance locked \(colorTemperature)")
                        })
                    }
                    
                    if videoDevice.isExposureModeSupported(AVCaptureDevice.ExposureMode.custom) {
                        var duration = 1;
                        var iso = 200;
                        
                        if (userDefaults.object(forKey: "exposure_duration") != nil) {
                            duration = Int(userDefaults.string(forKey: "exposure_duration") ?? "1")!
                        }
                        
                        if (userDefaults.object(forKey: "iso") != nil) {
                            iso = Int(userDefaults.string(forKey: "iso") ?? "200")!
                        }
                        
                        videoDevice.setExposureModeCustom(duration: CMTime.init(value: CMTimeValue(duration), timescale: 1000), iso: Float(iso),
                                                          completionHandler: { _ in
                            NSLog("Exposure locked \(duration) ms")
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
