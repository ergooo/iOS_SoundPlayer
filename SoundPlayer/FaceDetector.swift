//
//  FaceDetector.swift
//  SoundPlayer
//
//  Created by mst on 2016/06/17.
//  Copyright © 2016年 mst. All rights reserved.
//

import Foundation
import UIKit

protocol OnFaceFeatureListener {
    func onFaceFeature(result: CIFaceFeature)
}

class FaceDetector {
    
    private var isRunning: Bool = false
    
    private var count = 0
    
    func detectFaces(image: UIImage, callback: (CIFaceFeature)->Void) {
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        if(self.isRunning){
            return
        }
        dispatch_async(queue) {
            self.isRunning = true;

            // create CGImage from image on storyboard.
            let image = image
            guard let cgImage = image.CGImage else {
                return
            }
            
            let ciImage = CIImage(CGImage: cgImage)
            
            // set CIDetectorTypeFace.
            let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
            
            // set options
            let options = [CIDetectorSmile : true, CIDetectorEyeBlink : true]
            
            // get features from image
            let features = detector.featuresInImage(ciImage, options: options)

            var resultString = "DETECTED FACES:\n\n"

            for feature in features as! [CIFaceFeature] {
                resultString.appendContentsOf("bounds: \(NSStringFromCGRect(feature.bounds))\n")
                resultString.appendContentsOf("hasSmile: \(feature.hasSmile ? "YES" : "NO")\n")
                resultString.appendContentsOf("faceAngle: \(feature.hasFaceAngle ? String(feature.faceAngle) : "NONE")\n")
                resultString.appendContentsOf("leftEyeClosed: \(feature.leftEyeClosed ? "YES" : "NO")\n")
                resultString.appendContentsOf("rightEyeClosed: \(feature.rightEyeClosed ? "YES" : "NO")\n")
                
                resultString.appendContentsOf("\n")
            }
            if(!features.isEmpty){
                print(resultString)

                dispatch_async(dispatch_get_main_queue()) { () -> Void in
                    callback(features[0] as! CIFaceFeature)
                }
            }
            self.isRunning = false;

        }
    }

    
}
