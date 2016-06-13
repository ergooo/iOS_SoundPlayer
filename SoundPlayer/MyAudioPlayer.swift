import Foundation
import AudioUnit
import AudioToolbox
import AVFoundation

/**
 http://pebble8888.hatenablog.com/entry/2015/12/05/192914
 */
class MyAudioPlayer
{
    var frequency: Double = 440
	var _audiounit: AudioUnit = nil
	var _x: Float = 0
	let _sampleRate: Double = 44100
	init() {
		var audioComponentDescription = AudioComponentDescription(componentType: kAudioUnitType_Output, componentSubType: kAudioUnitSubType_RemoteIO, componentManufacturer: kAudioUnitManufacturer_Apple, componentFlags: 0, componentFlagsMask: 0)
		let audioComponentFindNext = AudioComponentFindNext(nil, &audioComponentDescription)
		AudioComponentInstanceNew(audioComponentFindNext, &_audiounit)
		AudioUnitInitialize(_audiounit);

		let audioformat: AVAudioFormat = AVAudioFormat(standardFormatWithSampleRate: _sampleRate, channels: 2)
		var audioStreamDescription: AudioStreamBasicDescription = audioformat.streamDescription.memory
		AudioUnitSetProperty(_audiounit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &audioStreamDescription, UInt32(sizeofValue(audioStreamDescription)))
	}

	let callback: AURenderCallback = {
		(inRefCon: UnsafeMutablePointer<Void>, ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>, inTimeStamp: UnsafePointer<AudioTimeStamp>, inBusNumber: UInt32, inNumberFrames: UInt32, ioData: UnsafeMutablePointer<AudioBufferList>)
		in
		let myAudioPlayer: MyAudioPlayer = unsafeBitCast(inRefCon, MyAudioPlayer.self)
		myAudioPlayer.render(inNumberFrames, ioData: ioData)
		return noErr
	}

	func render(inNumberFrames: UInt32, ioData: UnsafeMutablePointer<AudioBufferList>) {
		let delta: Float = Float(frequency * 2 * M_PI / _sampleRate)
		let audioBufferList = UnsafeMutableAudioBufferListPointer(ioData)
		var x: Float = 0
		for buffer: AudioBuffer in audioBufferList {
			x = _x
			let buf: UnsafeMutablePointer<Float> = unsafeBitCast(buffer.mData, UnsafeMutablePointer<Float>.self)
			for i in 0 ..< Int(inNumberFrames) {
				buf[i] = sin(x)
				x += delta
			}
		}
		if audioBufferList.count > 0 {
			_x = x
		}
	}
	func play() {
		let ref: UnsafeMutablePointer<Void> = unsafeBitCast(self, UnsafeMutablePointer<Void>.self)
		var callbackstruct: AURenderCallbackStruct = AURenderCallbackStruct(inputProc: callback, inputProcRefCon: ref)
		AudioUnitSetProperty(_audiounit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &callbackstruct, UInt32(sizeofValue(callbackstruct)))

		AudioOutputUnitStart(_audiounit)
	}
	func stop() {
		AudioOutputUnitStop(_audiounit)
        _x = 0
	}
    
    func updateFrequency(frequency: Double){
        self.frequency = frequency
    }
}