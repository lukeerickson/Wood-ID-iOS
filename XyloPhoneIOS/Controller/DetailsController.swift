//
//  DetailsController.swift
//  XyloPhoneIOS
//
//  Created by joseph dayo on 3/27/22.
//

import Foundation
import UIKit

struct TopKPair: Decodable, Encodable {
    var classLabel: String
    var score: String
}

class DetailsController: UIViewController {
    @IBOutlet weak var sampleImage: UIImageView!
    @IBOutlet weak var sampleCommonName: UILabel!
    @IBOutlet weak var sampleLabel: UILabel!
    @IBOutlet weak var topkContainer: UITableView!
    @IBOutlet weak var timeStampLabel: UILabel!
    weak open var inferenceLog: (InferenceLogEntity)?
    var speciesDatabase: SpeciesUtil?
    var topKArr: [TopKPair] = []
    
    fileprivate func loadSpeciesDetails() {
        DispatchQueue.main.async {
            if let inferenceLog = self.inferenceLog {
                if let species = self.speciesDatabase?.resolve(classLabel: inferenceLog.classLabel!) {
                    if let commonName = species.other_names.first {
                        self.sampleCommonName.text = commonName
                        if (inferenceLog.classLabel != commonName ) {
                            self.sampleLabel.text = species.scientific_name
                            self.sampleLabel.isHidden = false
                        }
                    }
                    
                }
                
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let imagedata = inferenceLog?.image {
            sampleImage.image = UIImage(data: imagedata)
        }
        topkContainer.delegate = self
        topkContainer.dataSource = self
        sampleCommonName.text = inferenceLog?.classLabel
        sampleLabel.isHidden = true
        if let timestamp = inferenceLog?.timestamp {
            let dateFormatterGet = DateFormatter()
            dateFormatterGet.dateFormat = "yyyy-MM-dd HH:mm:ss"
            timeStampLabel.text = dateFormatterGet.string(from: timestamp)
        }
        
        if (speciesDatabase == nil) {
            if let currentAppDelegate = UIApplication.shared.delegate as! AppDelegate? {
                DispatchQueue.global().async {
                    self.speciesDatabase = currentAppDelegate.getSpeciesDatabase();
                    self.loadSpeciesDetails()
                }
            }
        } else {
            loadSpeciesDetails()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if let top = inferenceLog?.topk {
                do {
                    try self.topKArr = JSONDecoder().decode([TopKPair].self, from: top.data(using: .utf8)!)
                    NSLog("total items = \(self.topKArr.count)")
                } catch {
                    
                }
            topkContainer.reloadData()
        }
    }
    
    @IBAction func closeDetailPage(_ sender: Any) {
        dismiss(animated: true)
    }
    
}

extension DetailsController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
}

extension DetailsController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return topKArr.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "topk_cell", for: indexPath) as! TopkCell
        let topk = topKArr[indexPath.item]
        cell.classLabel.text = topk.classLabel
        cell.scoreLabel.text = topk.score
        return cell;
    }
}
