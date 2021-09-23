//
//  ViewController.swift
//  XyloPhoneIOS
//
//  Created by joseph Emmanuel Dayo on 8/16/21.
//

import UIKit
import AVFoundation

public protocol ImagePickerDelegate: class {
    func didSelect(image: UIImage?)
}

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var identificationlabel: UILabel!
    @IBOutlet weak var testImage: UIImageView!
    
    let labels = [ "Albizia",
                   "Detarium",
                   "Dialium",
                   "Hymenaea",
                   "Inga",
                   "Morus",
                   "Nauclea",
                   "Robinia",
                   "Swietenia",
                   "Tectona",
                   "Ulmus_americana",
                   "Ulmus_rubra"
]
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func showCamera(_ sender: Any) {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
            case .authorized: // The user has previously granted access to the camera.
                NSLog("Authorized?")
                let cameraController = CameraController()
                   present(cameraController, animated: true)
               return
           case .notDetermined: // The user has not yet been asked for camera access.
               AVCaptureDevice.requestAccess(for: .video) { granted in
                   if granted {
                    let cameraController = CameraController()
                    self.present(cameraController, animated: true)
                   }
               }
           return
           case .denied: // The user has previously denied access.
               return

           case .restricted: // The user can't grant access due to restrictions.
               return
        @unknown default:
            NSLog("unknown status")
        }
    }
    
    
    @IBAction func selectImage(_ sender: Any) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = UIImagePickerController.SourceType.photoLibrary
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = ["public.image"]
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        NSLog("imagePicker selected")
        guard let image = info[.originalImage] as? UIImage else { return }

        let imageName = UUID().uuidString
        let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
        NSLog("imagePath \(imagePath)")
        if let pngData = image.pngData() {
            let image = UIImage.init(data: pngData)!
            let resizedImage = image.resized(to: CGSize(width: 512, height: 512))
            testImage.image = resizedImage
            guard let pixelBuffer = resizedImage.normalized() else {
                return
            }
            let module = ImagePredictor()
            
            if let outputs = try? module.predict(pixelBuffer, resultCount: labels.count) {
                NSLog("Inference done")
                for m in outputs.0 {
                    NSLog("\(m.label) -> \(m.score)")
                }
                let result = outputs.0.first!
                identificationlabel.text = "\(result.label) = \(result.score)"
            } else {
                return
            }
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
}

