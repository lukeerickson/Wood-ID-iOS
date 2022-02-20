//
//  ViewController.swift
//  XyloPhoneIOS
//
//  Created by joseph Emmanuel Dayo on 8/16/21.
//

import UIKit
import AVFoundation
import Photos
import CoreData

public protocol ImagePickerDelegate: class {
    func didSelect(image: UIImage?)
}

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CameraControllerDelegate {
    @IBOutlet weak var identificationlabel: UILabel!
    @IBOutlet weak var testImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    @IBAction func openCamera(_ sender: Any) {
        NSLog("Open camera")
    }
    
    @IBAction func showCamera(_ sender: Any) {
        NSLog("showing camera")
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
            case .authorized: // The user has previously granted access to the camera.
                NSLog("Authorized?")
                let cameraController = self.storyboard?.instantiateViewController(withIdentifier: "CameraController") as! CameraController
                cameraController.delegate = self
                cameraController.modalPresentationStyle = .fullScreen
                present(cameraController, animated: true)
               return
           case .notDetermined: // The user has not yet been asked for camera access.
            NSLog("Not Authorized?")
               AVCaptureDevice.requestAccess(for: .video) { granted in
                   if granted {
                    let cameraController = CameraController()
                    cameraController.modalPresentationStyle = .fullScreen
                    cameraController.delegate = self
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
        
    @IBAction func selectImage(_ sender: Any) {
        NSLog("select Image!")
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
            process(photoOutput: pngData, cropSize: min(Float(image.size.height), Float(image.size.width)))
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
    
    func didCaptureImage(photoOutput: Data?, cropSize: Float) {
        guard let photoData = photoOutput else {
            print("No photo data resource")
            return
        }
        if let data = process(photoOutput: photoData, cropSize: cropSize) {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
//                    PHPhotoLibrary.shared().performChanges({
//                        let options = PHAssetResourceCreationOptions()
//                        let creationRequest = PHAssetCreationRequest.forAsset()
//                        creationRequest.addResource(with: .photo, data: data.jpegData(compressionQuality: 100)!, options: options)
//                    }, completionHandler: { _, error in
//                        if let error = error {
//                            print("Error occurred while saving photo to photo library: \(error)")
//                        }
//                    })
                } else {
                    NSLog("not authorized!")
                }
            }
        }
    }
    
    private func preprocessImage(photoOutput: Data?, cropSize: Float) -> UIImage {
            let image = UIImage.init(data: photoOutput!)!
            NSLog("Dimensions width: \(image.size.width) height: \(image.size.height)")
            
            let newCropWidth = CGFloat(cropSize);
            let newCropHeight = CGFloat(cropSize);
            NSLog("Square size: \(cropSize)")
            let x = image.size.width / 2.0 - newCropWidth/2.0;
            let y = image.size.height / 2.0 - newCropHeight/2.0;
            let cropRect = CGRect(x: y, y: x, width: newCropWidth, height: newCropHeight);
            let imageRef = image.cgImage!.cropping(to: cropRect)
            return UIImage.init(cgImage: imageRef!, scale: 1.0, orientation: .right)
    }
    
    private func process(photoOutput: Data?, cropSize: Float) -> UIImage? {
        let resizedImage = preprocessImage(photoOutput: photoOutput, cropSize: cropSize).resized(to: CGSize(width: 512, height: 512))
        
        testImage.image = resizedImage

        guard let pixelBuffer = resizedImage.normalized() else {
            return nil
        }
        let module = ImagePredictor()
        let labels = module.classLabels()
        NSLog("Starting Inference \(labels.count)")
        if let outputs = try? module.predict(pixelBuffer, resultCount: labels.count) {
            NSLog("Inference done")
            let result = outputs.0.first!
//            saveInferenceLog(className: result.label)
            identificationlabel.text = "\(result.label) = \(result.score)"
            return resizedImage
        } else {
            return nil
        }

    }
    
//    func loadInferenceLogs() -> [InferenceLogEntity] {
//        let mainContext = CoreDataManager.shared.mainContext
//        let fetchRequest: NSFetchRequest<InferenceLogEntity> = InferenceLogEntity.fetchRequest()
//        do {
//            let results = try mainContext.fetch(fetchRequest)
//            return results
//        }
//        catch {
//            debugPrint(error)
//        }
//        return []
//    }
//
//    func saveInferenceLog(className: String) {
//        let context = CoreDataManager.shared.backgroundContext()
//        context.perform {
//            NSLog("Saving inference log")
//            let entity = InferenceLogEntity.entity()
//            let inferenceLog = InferenceLogEntity(entity: entity, insertInto: context)
//            inferenceLog.class_name = className
//            do {
//                try context.save()
//            } catch {
//                debugPrint(error)
//            }
//        }
//    }
}

