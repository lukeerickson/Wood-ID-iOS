//
//  ExportUtil.swift
//  XyloPhoneIOS
//
//  Created by joseph dayo on 4/9/22.
//

import Foundation
import CoreData


struct ExportUtil {
    static func exportToCSV(context: NSManagedObjectContext, label: String) -> URL? {
        let fetchRequest: NSFetchRequest<InferenceLogEntity> = InferenceLogEntity.fetchRequest()
        let sort = NSSortDescriptor(key: #keyPath(InferenceLogEntity.timestamp), ascending: false)
        fetchRequest.sortDescriptors = [sort]
        do {
            let results = try context.fetch(fetchRequest)
            let fileManager = FileManager.default
                    do {
                        let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)

                        let rootExtract = path.appendingPathComponent("exported_\(label)")
                        if !FileManager.default.fileExists(atPath: rootExtract.path) {
                            do {
                                try FileManager.default.createDirectory(atPath: rootExtract.path, withIntermediateDirectories: true, attributes: nil)
                            } catch {
                                print(error.localizedDescription)
                            }
                        }
                        
                        NSLog("Extracting to path \(rootExtract)")
                        
                        let csvFile = rootExtract.appendingPathComponent("wood_id_export_\(label).csv")
                        var csvRows = [String]()
                        let headers = "uid,timestamp,prediction_label_1,img,score,scores,model_name";
                        csvRows.append(headers)
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
                                let imagename = imageFolderPath.appendingPathComponent("\(body.uid!).jpg")
                                try image.write(to: imagename)
                                let relativeImagePath = imagename.absoluteString.replacingOccurrences(of: "\(rootExtract.absoluteString)/", with: "")
                                let csvString = "\(body.uid!),\(body.timestamp!),\(body.classLabel!),\(relativeImagePath),\(body.score),\(body.scores),\(body.modelVersion)\n"
                                csvRows.append(csvString)
                            }
                        })
                        
                        try csvRows.joined(separator: "\n").write(to: csvFile, atomically: true, encoding: .utf8)
                        return rootExtract
                    } catch {
                        print("error creating file")
                    }
        }
        catch {
            debugPrint(error)
        }
        return nil
    }
}
