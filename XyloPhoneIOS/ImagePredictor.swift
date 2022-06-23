import UIKit

class ImagePredictor: Predictor {
    private var isRunning: Bool = false
//    private lazy var module: VisionTorchModule = {
//        if let filePath = Bundle.main.path(forResource: "fips_wood_model_mobile", ofType: "pt"),
//            let module = VisionTorchModule(fileAtPath: filePath) {
//            return module
//        } else {
//            fatalError("Failed to load model!")
//        }
//    }()

    func getLabels() -> [String] {
        let userDefaults = UserDefaults()
        if let filePath = userDefaults.object(forKey: "currentModel") {
            NSLog("loading extracted model at \(filePath)")
            let filemgr = FileManager.default
            let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
            let docURL = dirPaths[0]
            let classLabelsPath = docURL.appendingPathComponent(filePath as! String).appendingPathComponent("labels.txt")
            if let labels = try? Data(contentsOf: classLabelsPath) {
                return String(data: labels, encoding: .utf8)!.components(separatedBy: "\n")
            }
        }
        return []
    }

    func predict(_ buffer: [Float32], resultCount: Int) throws -> ([InferenceResult], Double, [String])? {
        if isRunning {
            return nil
        }
        isRunning = true
        let startTime = CACurrentMediaTime()
        var tensorBuffer = buffer;
 
        if let currentAppDelegate = UIApplication.shared.delegate as! AppDelegate? {
            if let module = currentAppDelegate.getTorchVisionModule() {
                let labels =  getLabels()
                guard let outputs = module.predictImage(UnsafeMutableRawPointer(&tensorBuffer)
                                                        , size: Int32(labels.count)) else {
                    throw PredictorError.invalidInputTensor
                }
                isRunning = false
                NSLog("Number of outputs \(outputs.count)")
                NSLog("Number of classes \(labels.count)")
                let inferenceTime = (CACurrentMediaTime() - startTime) * 1000
                for x in 0..<outputs.count {
                    NSLog("\(labels[x]) -> \(outputs[x].floatValue)")
                }
                let results = topK(scores: outputs, labels: labels, count: resultCount)
                return (results, inferenceTime, labels)
            }
        }
        return ([], 0.0, [])
    }
    
    func classLabels() -> ([String]) {
        let labels =  getLabels()
        return labels.filter { (val) -> Bool in
            !val.isEmpty
        }
    }
}
