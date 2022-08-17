//
//  SpeciesUtil.swift
//  XyloPhoneIOS
//
//  Created by joseph dayo on 8/16/22.
//

import Foundation

struct Species: Decodable {
    let scientific_name: String?
    let other_names: [String]
}

class SpeciesUtil {
    var database: [String: Species]
    let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults) {
      database = [String: Species]()
      self.userDefaults = userDefaults
    }
    
    public func loadDatabase() {
        database = getSpeciesDatabase(userDefaults: userDefaults)
    }
    
    public func resolveLabel(classLabel: String) -> String {
        let key = classLabel.lowercased().replacingOccurrences(of: " ", with: "_")
        if let commonName = database[key]?.other_names.first {
            return commonName
        }
        return classLabel
    }
    
    public func resolve(classLabel: String) -> Species? {
        let key = classLabel.lowercased().replacingOccurrences(of: " ", with: "_")
        return database[key]
    }
    
    private func getSpeciesDatabase(userDefaults: UserDefaults) -> [String: Species] {
        if let filePath = userDefaults.object(forKey: "currentModel") {
            NSLog("loading extracted model at \(filePath)")
            let filemgr = FileManager.default
            let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
            let docURL = dirPaths[0]
            let speciesDatabasePath = docURL.appendingPathComponent(filePath as! String).appendingPathComponent("species_database.json")
            if let species = try? Data(contentsOf: speciesDatabasePath) {
                NSLog("Loading species database")
                return try! JSONDecoder().decode([String: Species].self, from: species)
            }
        }
        return [String: Species]()
    }
}
