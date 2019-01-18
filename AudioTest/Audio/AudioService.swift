//
//  Record.swift
//  AudioTest
//
//  Created on 2019/01/07.
//
import AudioToolbox
import AVFoundation

private func AudioQueueInputCallback(
    _ inUserData: UnsafeMutableRawPointer?,
    inAQ: AudioQueueRef,
    inBuffer: AudioQueueBufferRef,
    inStartTime: UnsafePointer<AudioTimeStamp>,
    inNumberPacketDescriptions: UInt32,
    inPacketDescs: UnsafePointer<AudioStreamPacketDescription>?)
{
    let audioService = unsafeBitCast(inUserData!, to:AudioService.self)
    audioService.writePackets(inBuffer: inBuffer)
    AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, nil);
}

class AudioService : NSObject {
    var queue: AudioQueueRef!
    //var timer: Timer!
    var audioObj: AudioObject
    var audioEngine: AVAudioEngine
    
    override init() {
        audioObj = AudioObject(_: nil)
        audioEngine = AVAudioEngine()
    }
    
    func startRecord() {
        if audioObj.seconds > 0 {
            audioObj.reset()
        }
        // Set data format
        var dataFormat = audioObj.audioFormat
        // Observe input level
        var audioQueue: AudioQueueRef? = nil
        var error = noErr
        error = AudioQueueNewInput(
            &dataFormat,
            AudioQueueInputCallback,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            .none,
            .none,
            0,
            &audioQueue)
        if error == noErr {
            self.queue = audioQueue
        }
        AudioQueueStart(self.queue, nil)
        
        // Enable level meter
//        var enabledLevelMeter: UInt32 = 1
//        AudioQueueSetProperty(self.queue, kAudioQueueProperty_EnableLevelMetering, &enabledLevelMeter, UInt32(MemoryLayout<UInt32>.size))
//
//        self.timer = Timer.scheduledTimer(timeInterval: 0.5,
//                                          target: self,
//                                          selector: #selector(self.detectVolume(_:)),
//                                          userInfo: nil,
//                                          repeats: true)
//        self.timer?.fire()
    }
    
    func stopRecord()
    {
        // Finish observation
//        self.timer.invalidate()
//        self.timer = nil
        audioObj.data = Data(bytes: audioObj.buffer, count: Int(audioObj.maxPacketCount))
        AudioQueueFlush(self.queue)
        AudioQueueStop(self.queue, false)
        AudioQueueDispose(self.queue, true)
    }
    
    func startPlay()
    {
        let inputVoice = AVAudioPlayerNode()
        let inputRhythm = AVAudioPlayerNode()
        let mixer = audioEngine.mainMixerNode
        let format = inputVoice.inputFormat(forBus: 0)
        
        audioEngine.attach(inputVoice)
        audioEngine.attach(inputRhythm)
        audioEngine.attach(mixer)
        
        //TODO: read sound signals from Buffer
        let voiceBuffer = toPCMBuffer(data: audioObj.data!)
        inputVoice.scheduleBuffer(voiceBuffer, completionHandler: nil)
        let rhythmBuffer = toPCMBuffer(data: audioObj.rhythmData!)
        inputRhythm.scheduleBuffer(rhythmBuffer, completionHandler: nil)
        
        audioEngine.connect(inputVoice, to: mixer, format: format)
        audioEngine.connect(inputRhythm, to: mixer, format: format)
        audioEngine.connect(mixer, to: audioEngine.outputNode, format: nil)
        
        try! audioEngine.start()
        inputRhythm.play()
        inputVoice.play()
    }
    
    func endPlay()
    {
        audioEngine.stop()
    }
    
    func pargeSounds()
    {
        //TODO: set BPM to sound signals (Rhythm based)
    }
    
    func getSoundsFromFile(filePath: NSURL)
    {
        // TODO: read sound signals from a sound file
    }
    
    func analyzeSounds()
    {
        // TODO: FFT with Buffer Data (Recorded)
    }
    
    func writePackets(inBuffer: AudioQueueBufferRef) {
        
        let numPackets: UInt32 = (inBuffer.pointee.mAudioDataByteSize / audioObj.bytesPerPacket)
        audioObj.maxPacketCount = numPackets
        
        if 0 < numPackets {
            memcpy(audioObj.buffer.advanced(by: Int(audioObj.bytesPerPacket * audioObj.startingPacketCount)),
                   inBuffer.pointee.mAudioData,
                   Int(audioObj.bytesPerPacket * numPackets))
            audioObj.startingPacketCount += numPackets;
        }
    }
    
    func toPCMBuffer(data: Data) -> AVAudioPCMBuffer {
        let audioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: audioObj.audioFormat.mSampleRate, channels: 1, interleaved: false)
        let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat!, frameCapacity: UInt32(data.count)/2)
        if let buffer = audioBuffer {
            buffer.frameLength = buffer.frameCapacity
            for i in 0..<data.count/2 {
                // transform two bytes into a float (-1.0 - 1.0), required by the audio buffer
                buffer.floatChannelData?.pointee[i] = Float(Int16(data[i*2+1]) << 8 | Int16(data[i*2]))/Float(INT16_MAX)
            }
            return buffer
        }
        return AVAudioPCMBuffer()
    }
    
    @objc func detectVolume(_ timer: Timer)
    {
        // Get level
        var levelMeter = AudioQueueLevelMeterState()
        var propertySize = UInt32(MemoryLayout<AudioQueueLevelMeterState>.size)
        
        AudioQueueGetProperty(
            self.queue,
            kAudioQueueProperty_CurrentLevelMeterDB,
            &levelMeter,
            &propertySize)
        
        // Show the audio channel's peak and average RMS power.
//        self.peakTextField.text = "".appendingFormat("%.2f", levelMeter.mPeakPower)
//        self.averageTextField.text = "".appendingFormat("%.2f", levelMeter.mAveragePower)
        
        // Show "LOUD!!" if mPeakPower is larger than -1.0
//        self.loudLabel.isHidden = (levelMeter.mPeakPower >= -1.0) ? false : true
    }
}
