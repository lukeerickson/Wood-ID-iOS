//
//  ModelInstaller.swift
//  XyloPhoneIOS
//
//  Created by joseph dayo on 4/9/22.
//

import Foundation
import ZIPFoundation

struct ModelUtility {
    static func installDefaultModel() -> URL? {
        if let filePath = Bundle.main.path(forResource: "model", ofType: "zip") {
            return installModelFrom(filePath: filePath)
        } else {
            fatalError("Failed to load model!")
        }
    }
    
    static func installModelFrom(filePath: String) -> URL? {
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
            try filemgr.unzipItem(at: URL(fileURLWithPath: filePath), to: dataPath)
            NSLog("model unziped at \(dataPath)")
            return dataPath
        } catch {
            NSLog("Error while unzipping item")
        }
        return nil
    }
}
