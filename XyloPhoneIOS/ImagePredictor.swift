import UIKit

class ImagePredictor: Predictor {
    private var isRunning: Bool = false
    private lazy var module: VisionTorchModule = {
        if let filePath = Bundle.main.path(forResource: "fips_wood_model_mobile", ofType: "pt"),
            let module = VisionTorchModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Failed to load model!")
        }
    }()

    private var labels: [String] = {
        if let filePath = Bundle.main.path(forResource: "class_labels", ofType: "txt"),
            let labels = try? String(contentsOfFile: filePath) {
            return labels.components(separatedBy: "\n")
        } else {
            fatalError("Label file was not found.")
        }
    }()

    func predict(_ buffer: [Float32], resultCount: Int) throws -> ([InferenceResult], Double, [String])? {
        if isRunning {
            return nil
        }
        isRunning = true
        let startTime = CACurrentMediaTime()
        var tensorBuffer = buffer;
 
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
    
    func classLabels() -> ([String]) {
        return labels.filter { (val) -> Bool in
            !val.isEmpty
        }
    }
}
