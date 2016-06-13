//
//  ViewController.swift
//  SoundPlayer
//
//  Created by mst on 2016/06/13.
//  Copyright © 2016年 mst. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

	let player: MyAudioPlayer = MyAudioPlayer()

	let camera: CameraSample = CameraSample()

	@IBOutlet weak var a: UIImageView!

	let faceDetector: FaceDetector = FaceDetector()

	var onImageCapturedListener: OnImageCapturedListener?
    
    let valueHolder: ValueHolder = ValueHolder()

	@IBOutlet weak var slider: UISlider!

	@IBOutlet weak var sliderValue: UITextView!

	@IBAction func onPlayButtonClicked(sender: UIButton) {
		player.play()
	}

	override func viewWillAppear(animated: Bool) {
		camera.viewWillAppear(animated)
		camera.setOnImageCapturedListener({ image in
			self.faceDetector.detectFaces(image, callback: { (faceFeature) in
				print(faceFeature.bounds.size)
				let level = 150+Float(faceFeature.bounds.size.width)*1.1
				self.sliderValue.text = String(level)
				self.player.updateFrequency(Double(level))
				self.slider.setValue(Float(level), animated: false)
			})
			self.a.image = image

//            print(image)
		})
	}
	override func viewDidDisappear(animated: Bool) {
		camera.viewDidDisappear(animated)
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	@IBAction func onStopButtonClicked(sender: AnyObject) {
		player.stop()
	}

	@IBAction func onSliderUpdated(sender: UISlider) {
		let level = Int(self.slider.value)
		sliderValue.text = String(level)
		player.updateFrequency(Double(level))
	}
}

