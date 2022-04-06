//
//  InferenceLogCell.swift
//  XyloPhoneIOS
//
//  Created by joseph dayo on 3/21/22.
//

import Foundation
import UIKit


class InferenceLogCell: UITableViewCell {
    weak var inferenceLog: InferenceLogEntity!
    weak var controller: UIViewController!
    @IBOutlet weak var classLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var InferenceLogImage: UIImageView!
}
