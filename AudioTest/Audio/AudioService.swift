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
    
}

class AudioService : NSObject {
    var queue: AudioQueueRef!
    //var timer: Timer!
    var audioObj: AudioObject
    
    override init() {
        audioObj = AudioObject(_: nil)
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
        AudioQueueFlush(self.queue)
        AudioQueueStop(self.queue, false)
        AudioQueueDispose(self.queue, true)
    }
    
    func startPlay()
    {
        
    }
    
    func endPlay()
    {
        
    }
    
    func pargeSounds()
    {
        
    }
    
    func getSoundsFromFile(filePath: NSURL)
    {
        
    }
    
    func analyzeSounds()
    {
        
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
