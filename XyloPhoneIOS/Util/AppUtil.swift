import Foundation
import UIKit
import AVFoundation

struct AppUtility {

    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
    
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.orientationLock = orientation
        }
    }

    /// OPTIONAL Added method to adjust lock and rotate to the desired orientation
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {
   
        self.lockOrientation(orientation)
    
        UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
        UINavigationController.attemptRotationToDeviceOrientation()
    }

    static func collectAvailableCameras() -> [(String,AVCaptureDevice)] {
        var cameras: [(String,AVCaptureDevice)] = []
        if let telephotoCamera = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back) {
            cameras.append(("Back Telephoto", telephotoCamera))
        }
        if let dualWideCameraDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
            // If a rear dual camera is not available, default to the rear dual wide camera.
            cameras.append(("Back Dualwide", dualWideCameraDevice))
        }
        if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            // If a rear dual wide camera is not available, default to the rear wide angle camera.
            cameras.append(("Back Wide Angle", backCameraDevice))
        }
        
//        if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera ,for: .video, position: .front) {
//            cameras.append(("Front Wide Angle", frontCameraDevice))
//        }
        
        return cameras
    }
}
