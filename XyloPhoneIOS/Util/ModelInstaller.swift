//
//  ModelInstaller.swift
//  XyloPhoneIOS
//
//  Created by joseph dayo on 4/9/22.
//

import Foundation
import ZIPFoundation

struct ModelDetails: Decodable {
    let name: String
    var url: URL?
    let description: String
    let pytorch : String
    let version: String
}

struct ModelUtility {
    static func installDefaultModel() -> ModelDetails? {
        if let filePath = Bundle.main.path(forResource: "model", ofType: "zip") {
            return installModelFrom(filePath: URL(fileURLWithPath: filePath))
        } else {
            fatalError("Failed to load model!")
        }
    }
    
    static func installModelFrom(filePath: URL) -> ModelDetails? {
        let filemgr = FileManager.default
        let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
        let docURL = dirPaths[0]
        let dataPath = docURL.appendingPathComponent("model_\(NSUUID().uuidString)")
        if !FileManager.default.fileExists(atPath: dataPath.path) {
            do {
                try FileManager.default.createDirectory(atPath: dataPath.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
            }
        }
        do {
            try filemgr.unzipItem(at: filePath, to: dataPath)
            NSLog("model unziped at \(dataPath)")
            let modelJson = try String(contentsOf: dataPath.appendingPathComponent("model.json"), encoding: .utf8)
            var details = try! JSONDecoder().decode(ModelDetails.self, from: modelJson.data(using: .utf8)!)
            details.url = dataPath
            return details
        } catch {
            NSLog("Error while unzipping item \(error)")
        }
        return nil
    }
    
    static func registerModel(userDefaults: UserDefaults, modelDetails: ModelDetails) -> ModelDetails {
        let filemgr = FileManager.default
        let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
        let docURL = dirPaths[0]
        let modelRelativePath = modelDetails.url!.path.replacingOccurrences(of: "\(docURL.path)/", with: "")
        NSLog("Model is at \(modelRelativePath)")
        userDefaults.set(modelRelativePath, forKey: "currentModel")
        userDefaults.set("\(modelDetails.name)-\(modelDetails.version)", forKey: "modelVersion")
        userDefaults.set(modelDetails.description, forKey: "modelDescription")
        
        return modelDetails
    }
}
