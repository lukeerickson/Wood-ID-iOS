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

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CameraControllerDelegate {
    @IBOutlet weak var identificationlabel: UILabel!

    @IBOutlet weak var inferenceLogTableView: UITableView!
    var mainContext = CoreDataManager.shared.mainContext
    var inferenceLogs: [InferenceLogEntity] = []
    
    
    var windowOrientation: UIInterfaceOrientation {
        return view.window?.windowScene?.interfaceOrientation ?? .unknown
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        inferenceLogTableView.delegate = self
        inferenceLogTableView.dataSource = self
        AppUtility.lockOrientation(.portrait)
        // Do any additional setup after loading the view.
        self.inferenceLogs = loadInferenceLogs()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.inferenceLogs = loadInferenceLogs()
        inferenceLogTableView.reloadData()
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
                    let cameraController = self.storyboard?.instantiateViewController(withIdentifier: "CameraController") as! CameraController
                    cameraController.modalPresentationStyle = .fullScreen
                    cameraController.delegate = self
                    self.present(cameraController, animated: true)
                   }
               }
           return
           case .denied: // The user has previously denied access.
            NSLog("denied")
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                     let cameraController = CameraController()
                     cameraController.modalPresentationStyle = .fullScreen
                     cameraController.delegate = self
                     self.present(cameraController, animated: true)
                    }
                }
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
                    NSLog("Saving image \(data.size.width) x \(data.size.height)")
                    PHPhotoLibrary.shared().performChanges({
                        let options = PHAssetResourceCreationOptions()
                        let creationRequest = PHAssetCreationRequest.forAsset()
                        creationRequest.addResource(with: .photo, data: data.jpegData(compressionQuality: 100)!, options: options)
                    }, completionHandler: { _, error in
                        if let error = error {
                            print("Error occurred while saving photo to photo library: \(error)")
                        }
                    })
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
            let cropRect = CGRect(x: x, y: y, width: newCropWidth, height: newCropHeight);
            let imageRef = image.cgImage!.cropping(to: cropRect)
            return UIImage.init(cgImage: imageRef!, scale: 1.0, orientation: .right)
    }
    
    private func process(photoOutput: Data?, cropSize: Float) -> UIImage? {
        let resizedImage = preprocessImage(photoOutput: photoOutput, cropSize: cropSize).resized(to: CGSize(width: 512, height: 512))
        
        guard let pixelBuffer = resizedImage.normalized() else {
            return nil
        }
        let module = ImagePredictor()
        let labels = module.classLabels()
        NSLog("Starting Inference \(labels.count)")
        if let outputs = try? module.predict(pixelBuffer, resultCount: labels.count) {
            NSLog("Inference done")
            let result = outputs.0.first!
            saveInferenceLog(className: result.label, image: resizedImage.pngData()!, score: result.score, labels: labels, topk: outputs.0)
            return resizedImage
        } else {
            return nil
        }

    }
    
    func loadInferenceLogs() -> [InferenceLogEntity] {
        let fetchRequest: NSFetchRequest<InferenceLogEntity> = InferenceLogEntity.fetchRequest()
        let sort = NSSortDescriptor(key: #keyPath(InferenceLogEntity.timestamp), ascending: false)
        fetchRequest.sortDescriptors = [sort]
        do {
            let results = try mainContext.fetch(fetchRequest)
            return results
        }
        catch {
            debugPrint(error)
        }
        return []
    }

    func saveInferenceLog(className: String, image: Data, score: Float, labels: [String], topk: [InferenceResult]) {
        let context = CoreDataManager.shared.backgroundContext()
        context.perform {
            NSLog("Saving inference log")
            let entity = InferenceLogEntity.entity()
            let inferenceLog = InferenceLogEntity(entity: entity, insertInto: context)
            inferenceLog.uid = UUID()
            inferenceLog.classLabel = className
            inferenceLog.image = image
            inferenceLog.timestamp = Date()
            let topKArr = topk.map { (result) -> TopKPair in
                TopKPair(classLabel: result.label, score: String(describing: result.score))
            }

            do {
                try inferenceLog.topk = String(data: JSONEncoder().encode(topKArr), encoding: .utf8)
                inferenceLog.score = score
                try inferenceLog.labels = String(data: JSONEncoder().encode(labels), encoding: .utf8)
                try context.save()
                self.inferenceLogs.append(inferenceLog)
                DispatchQueue.main.async {
                    self.inferenceLogTableView.reloadData()
                }
            } catch {
                debugPrint(error)
            }
        }
    }
}


extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailsController = self.storyboard?.instantiateViewController(withIdentifier: "DetailsController") as! DetailsController
        detailsController.inferenceLog = inferenceLogs[indexPath.item]
        present(detailsController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let log = inferenceLogs[indexPath.item]
        mainContext.delete(log)
        do {
            try mainContext.save()
            inferenceLogs.remove(at: indexPath.item)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } catch {
            NSLog("error while removing element")
        }
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inferenceLogs.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "inference_log_cell", for: indexPath) as! InferenceLogCell
        if let imagedata = inferenceLogs[indexPath.item].image {
            let uimage = UIImage(data: imagedata)
            cell.InferenceLogImage.image = uimage
        }
        let inferenceLog = inferenceLogs[indexPath.item]
        cell.controller = self
        cell.inferenceLog = inferenceLog
        cell.classLabel.text = inferenceLog.classLabel
        if let timestamp = inferenceLog.timestamp {
            let dateFormatterGet = DateFormatter()
            dateFormatterGet.dateFormat = "yyyy-MM-dd HH:mm:ss"
            cell.timestampLabel.text = dateFormatterGet.string(from: timestamp)
        }
        
        return cell;
    }
}
