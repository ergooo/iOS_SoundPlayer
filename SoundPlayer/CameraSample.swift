import UIKit
import AVFoundation

protocol OnImageCapturedListener {
    func onImageCaptured(image: UIImage)
}

class CameraSample: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var device: AVCaptureDevice!
    var session: AVCaptureSession!
    var adjustingExposure: Bool!
    
    private var onImageCapturedListener: (image: UIImage) -> () = {_ in}
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setup()
    }
    
    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        super.init(nibName: nil, bundle: nil)
        setup()
    }
    
    convenience init(onImageCapturedListener: (image:UIImage) -> Void) {
        self.init(nibName: nil, bundle: nil)
        self.onImageCapturedListener = onImageCapturedListener
    }
    
    func setup() {
    }
    
    func setOnImageCapturedListener(onImageCapturedListener:(image:UIImage)->Void){
        self.onImageCapturedListener = onImageCapturedListener
    }
    
    override func viewWillAppear(animated: Bool) {
        self.initCamera()
    }
    
    override func viewDidDisappear(animated: Bool) {
        self.session.stopRunning()
        for output in self.session.outputs {
            self.session.removeOutput(output as! AVCaptureOutput)
        }
        
        for input in self.session.inputs {
            self.session.removeInput(input as! AVCaptureInput)
        }
        self.session = nil
        self.device = nil
    }
    
    private func initCamera() {
        for caputureDevice: AnyObject in AVCaptureDevice.devices() {
            if caputureDevice.position == AVCaptureDevicePosition.Front {
                self.device = caputureDevice as! AVCaptureDevice
            }
        }
        
        self.device.activeVideoMinFrameDuration = CMTimeMake(1, 30)
        
        var input: AVCaptureDeviceInput?
        do {
            input = try AVCaptureDeviceInput(device: self.device) as AVCaptureDeviceInput
        } catch {
            input = nil
        }
        
        if let input = input {
            
            let cameraQueue = dispatch_queue_create("cameraQueue", nil)
            let videoDataOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_32BGRA)]
            videoDataOutput.setSampleBufferDelegate(self, queue: cameraQueue)
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            
            self.session = AVCaptureSession()
            
            if (self.session.canAddInput(input)) {
                self.session.addInput(input)
            }
            
            if (self.session.canAddOutput(videoDataOutput)) {
                self.session.addOutput(videoDataOutput)
            }
            
            self.session.sessionPreset = AVCaptureSessionPreset1280x720
            self.session.startRunning()
            
            self.adjustingExposure = false
            self.device.addObserver(self, forKeyPath: "adjustingExposure", options: NSKeyValueObservingOptions.New, context: nil)
            
        }
        
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        let image = self.imageFromSampleBuffer(sampleBuffer)
        dispatch_async(dispatch_get_main_queue()) {
            self.onImageCapturedListener(image: image)
        }
    }
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBufferRef) -> UIImage {
        let imageBuffer: CVImageBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(imageBuffer, 0)
        let baseAddress: UnsafeMutablePointer<Void> = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        
        let bytesPerRow: Int = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width: Int = CVPixelBufferGetWidth(imageBuffer)
        let height: Int = CVPixelBufferGetHeight(imageBuffer)
        
        let colorSpace: CGColorSpaceRef = CGColorSpaceCreateDeviceRGB()!
        
        let bitsPerCompornent: Int = 8
        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.ByteOrder32Little.rawValue |
            CGImageAlphaInfo.PremultipliedFirst.rawValue) as UInt32)
        let newContext: CGContextRef = CGBitmapContextCreate(baseAddress, width, height, bitsPerCompornent, bytesPerRow, colorSpace, bitmapInfo.rawValue)! as CGContextRef
        
        let imageRef: CGImageRef = CGBitmapContextCreateImage(newContext)!
        let resultImage = UIImage(CGImage: imageRef, scale: 1.0, orientation: UIImageOrientation.Right)
        
        return resultImage
    }
    
    // 以下のコメントの値を引数で受け取る値の例
    // let anyTouch = sender as UIGestureRecognizer
    // let origin = anyTouch.locationInView(self.preview);
    // let focusPoint = CGPointMake(origin.y / self.preview.bounds.size.height, 1 - origin.x / self.preview.bounds.size.width);
    func setFocusAndrExposure(focusPoint: CGPoint) {
        do {
            try self.device.lockForConfiguration()
            self.device.focusPointOfInterest = focusPoint
            self.device.focusMode = AVCaptureFocusMode.AutoFocus
            
            if self.device.isExposureModeSupported(AVCaptureExposureMode.ContinuousAutoExposure) {
                self.adjustingExposure = true
                self.device.exposurePointOfInterest = focusPoint
                self.device.exposureMode = AVCaptureExposureMode.AutoExpose
            }
            self.device.unlockForConfiguration()
            
            
        } catch {
            return
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String: AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if !self.adjustingExposure {
            return
        }
        
        if keyPath == "adjustingExposure" {
            let isNew = change![NSKeyValueChangeNewKey]! as! Bool
            if !isNew {
                self.adjustingExposure = false
                
                do{
                    try self.device.lockForConfiguration()
                } catch {
                    return
                }
                self.device.exposureMode = AVCaptureExposureMode.Locked
                self.device.unlockForConfiguration()
            }
        }
    }
}