//
//  ExportUtil.swift
//  XyloPhoneIOS
//
//  Created by joseph dayo on 4/9/22.
//

import Foundation
import CoreData


struct ExportUtil {
    static func exportToCSV(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<InferenceLogEntity> = InferenceLogEntity.fetchRequest()
        let sort = NSSortDescriptor(key: #keyPath(InferenceLogEntity.timestamp), ascending: false)
        fetchRequest.sortDescriptors = [sort]
        do {
            let results = try context.fetch(fetchRequest)
            let fileManager = FileManager.default
                    do {
                        let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
                        let formatter = DateFormatter()

                        let rootExtract = path.appendingPathComponent("exported_\(formatter.string(from: Date()))")
                        if !FileManager.default.fileExists(atPath: rootExtract.path) {
                            do {
                                try FileManager.default.createDirectory(atPath: rootExtract.path, withIntermediateDirectories: true, attributes: nil)
                            } catch {
                                print(error.localizedDescription)
                            }
                        }
                        
                        NSLog("Extracting to path \(rootExtract)")
                        
                        let csvFile = rootExtract.appendingPathComponent("export.csv")
                        
                        let headers = "uid,first_name,last_name,timestamp,class,img,lat,long,location,model_name,version,correction,comment\n"
                        try headers.write(to: csvFile, atomically: true, encoding: .utf8)
                        
                        try results.forEach( { (body:  InferenceLogEntity) in
                            let imageFolderPath = rootExtract.appendingPathComponent(body.classLabel!)
                            if !FileManager.default.fileExists(atPath: imageFolderPath.path) {
                                do {
                                    try FileManager.default.createDirectory(atPath: imageFolderPath.path, withIntermediateDirectories: true, attributes: nil)
                                } catch {
                                    print(error.localizedDescription)
                                }
                            }
                            

                            if let image = body.image {
                                let imagename = imageFolderPath.appendingPathComponent("\(body.uid).jpg")
                                try image.write(to: imagename)
                                let csvString = "\(body.uid),,,\(body.timestamp),\(body.classLabel),\(imagename.absoluteString),,,,,"
                                try csvString.write(to: csvFile, atomically: true, encoding: .utf8)
                            }
                            

                        })
                    } catch {
                        print("error creating file")
                    }
        }
        catch {
            debugPrint(error)
        }
    }
}
