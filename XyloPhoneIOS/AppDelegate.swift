//
//  AppDelegate.swift
//  XyloPhoneIOS
//
//  Created by joseph Emmanuel Dayo on 8/16/21.
//

import UIKit
import CoreData

struct PhoneSettings: Decodable {
    let id: String
    let cropFactor: String
    let redGain: String?
    let blueGain: String?
    let greenGain: String?
    let exposureDuration: String?
    let iso: String?
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    private let userDefaults = UserDefaults()
    private var visionModule: VisionTorchModule?
    private var speciesLookup: SpeciesUtil?
    
    fileprivate func settingWithDefault(key: String, value: String?, defval: String) {
        if let settingval =  value {
            self.userDefaults.set(settingval, forKey: key)
        } else {
            self.userDefaults.set(defval, forKey: key)
        }
    }
    
    func getSpeciesDatabase() -> SpeciesUtil? {
        if (self.speciesLookup == nil) {
            if let filePath = userDefaults.object(forKey: "currentModel") {
                NSLog("loading extracted model at \(filePath)")
                speciesLookup = SpeciesUtil(userDefaults: userDefaults)
                speciesLookup?.loadDatabase()
            }
        }
        return speciesLookup
    }
    
    func getTorchVisionModule() -> VisionTorchModule? {
        if self.visionModule == nil {
            if let filePath = userDefaults.object(forKey: "currentModel") {
                NSLog("loading extracted model at \(filePath)")
                let filemgr = FileManager.default
                let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
                let docURL = dirPaths[0]
                let finalModelFilePath = "\(docURL.path)/\(filePath as! String)/model.pt"
                
                if (!filemgr.fileExists(atPath: finalModelFilePath)) {
                    fatalError("Model does not exist at \(finalModelFilePath)")
                }
                               
                if let module = VisionTorchModule(fileAtPath: finalModelFilePath) {
                    self.visionModule = module
                    return module
                }
                
                speciesLookup = SpeciesUtil(userDefaults: userDefaults)
                speciesLookup?.loadDatabase()
                
            } else {
                fatalError("Failed to load model!")
            }
            return nil
        }
        return self.visionModule
    }
    
    func resetVisionModule() {
        self.visionModule = nil
    }
    
    fileprivate func applyDefaultSettings() {
        self.userDefaults.set( "512.0", forKey: "current_crop")
        self.userDefaults.set( "1.0", forKey: "red_gain")
        self.userDefaults.set( "1.0", forKey: "blue_gain")
        self.userDefaults.set( "1.0", forKey: "green_gain")
        self.userDefaults.set( "200", forKey: "iso")
        self.userDefaults.set("1", forKey: "exposure_duration")
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let currentPhoneModel = UIDevice.current.type.rawValue
        NSLog("Phone model \"\(currentPhoneModel)\"")
        let currentPhoneSettings =  userDefaults.object(forKey: "current_phone_settings")
    
        NSLog("Setup initial settings")
        let modelPath = userDefaults.object(forKey: "currentModel")
        
        if modelPath == nil {
            NSLog("Setting up initial model")
            DispatchQueue.global(qos: .default).async {
                if let modelDetails = ModelUtility.installDefaultModel() {
                    ModelUtility.registerModel(userDefaults: self.userDefaults, modelDetails: modelDetails)
                }
            }
        }
        if currentPhoneSettings == nil {
        if let filePath = Bundle.main.path(forResource: "phone_settings", ofType: "json") {
            do {

                    let jsonString = try String(contentsOfFile: filePath)
                    self.userDefaults.set(jsonString, forKey: "current_phone_settings")
                    let phoneSettings = try JSONDecoder().decode([PhoneSettings].self, from: jsonString.data(using: .utf8)!)
                    
                    if let applicableSettings = phoneSettings.first(where: { (phoneSettings) -> Bool in
                                        phoneSettings.id == currentPhoneModel
                        }
                    ) {
                        NSLog("Found setting for \(currentPhoneModel) using cropFactor \(applicableSettings.cropFactor)")
                        settingWithDefault(key: "current_crop", value: applicableSettings.cropFactor, defval: "512.0")
                        settingWithDefault(key: "red_gain", value: applicableSettings.redGain, defval: "1.0")
                        settingWithDefault(key: "blue_gain", value: applicableSettings.blueGain, defval: "1.0")
                        settingWithDefault(key: "green_gain", value: applicableSettings.greenGain, defval: "1.0")
                        settingWithDefault(key: "iso", value: applicableSettings.iso, defval: "200")
                        settingWithDefault(key: "exposure_duration", value: applicableSettings.exposureDuration, defval: "1")
                    } else {
                        NSLog("No settings found for \(currentPhoneModel)")
                        applyDefaultSettings()
                    }

            } catch {
                
            }
        } else {
            applyDefaultSettings()
        }
    }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    /// set orientations you want to be allowed in this property by default
    var orientationLock = UIInterfaceOrientationMask.portrait

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "XyloPhoneIOS")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

