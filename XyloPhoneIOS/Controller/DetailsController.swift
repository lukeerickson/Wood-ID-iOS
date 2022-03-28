//
//  DetailsController.swift
//  XyloPhoneIOS
//
//  Created by joseph dayo on 3/27/22.
//

import Foundation
import UIKit

class DetailsController: UIViewController {
    @IBOutlet weak var sampleImage: UIImageView!
    @IBOutlet weak var sampleLabel: UILabel!
    weak open var inferenceLog: (InferenceLogEntity)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let imagedata = inferenceLog?.image {
            sampleImage.image = UIImage(data: imagedata)
        }
        
        sampleLabel.text = inferenceLog?.classLabel
    }
    
}
