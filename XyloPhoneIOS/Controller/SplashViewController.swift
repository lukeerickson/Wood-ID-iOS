//
//  SplashViewController.swift
//  XyloPhoneIOS
//
//  Created by joseph dayo on 8/18/22.
//

import Foundation
import UIKit

class SplashViewController: UIViewController {
    
    @IBAction func continuePressed(_ sender: Any) {
        if let mainView = self.storyboard?.instantiateViewController(withIdentifier: "main") {
            mainView.modalPresentationStyle = .fullScreen
            present(mainView, animated: true)
        }
    }
}
