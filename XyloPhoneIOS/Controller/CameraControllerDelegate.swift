//
//  CameraControllerDelegate.swift
//  XyloPhoneIOS
//
//  Created by joseph Emmanuel Dayo on 12/13/21.
//

import Foundation
import AVFoundation
import UIKit

public protocol CameraControllerDelegate : NSObjectProtocol {
    func didCaptureImage(photoOutput: Data?, cropSize: Float)
}
