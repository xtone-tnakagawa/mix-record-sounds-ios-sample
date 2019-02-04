//
//  AudiopService.swift
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

class AudioService : NSObject
{
    var queue: AudioQueueRef!
    var audioObj: AudioObject
    var audioEngine: AVAudioEngine
    
    override init()
    {
        audioObj = AudioObject(_: nil)
        audioEngine = AVAudioEngine()
    }
    
    func startRecord() {
        if audioObj.seconds > 0
        {
            audioObj.reset()
        }
        // Set data format
        var dataFormat = audioObj.audioFormat
        // Observe input level
        var audioQueue: AudioQueueRef? = nil
        let error = AudioQueueNewInput(
            &dataFormat,
            AudioQueueInputCallback,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            .none,
            .none,
            0,
            &audioQueue)
        if error == noErr
        {
            self.queue = audioQueue
        }
        AudioQueueStart(self.queue, nil)
    }
    
    func stopRecord()
    {
        if let buf = audioObj.buffer
        {
            audioObj.data = Data(bytes: buf, count: Int(audioObj.maxPacketCount))
        }
        AudioQueueFlush(self.queue)
        AudioQueueStop(self.queue, false)
        AudioQueueDispose(self.queue, true)
    }
    
    //NOTE: This method no execution becouse this child method is empty.
    func pargeSounds()
    {
        analyzeSounds()
    }
    
    func startPlay()
    {
        let inputVoice = AVAudioPlayerNode()
        let inputRhythm = AVAudioPlayerNode()
        let mixer = audioEngine.mainMixerNode
        
        audioEngine.attach(inputVoice)
        audioEngine.attach(inputRhythm)
        
        audioEngine.connect(inputVoice, to: mixer, format: AVAudioFormat.init(standardFormatWithSampleRate: audioObj.audioFormat.mSampleRate, channels: 1))
        audioEngine.connect(inputRhythm, to: mixer, format: AVAudioFormat.init(standardFormatWithSampleRate: audioObj.audioFormat.mSampleRate, channels: 3))
        audioEngine.connect(mixer, to: audioEngine.outputNode, format: nil)

        // read sound signals from Buffer
        let voiceBuffer = toPCMBuffer(data: audioObj.data!)
        inputVoice.scheduleBuffer(voiceBuffer, completionCallbackType: .dataPlayedBack, completionHandler: { (AVAudioPlayerNodeCompletionCallbackType) -> Void in
            self.endPlay()
        })
        
        if let resourcePath = Bundle.main.path(forResource: "rhythm", ofType: "wav") {
            let url = URL(fileURLWithPath: resourcePath)
            getSoundsFromFile(url)
        }
        if let buffer = audioObj.rhythmDataBuffer {
            inputRhythm.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            // set speed rate
            inputRhythm.rate = getPargeSpeed(buffer: voiceBuffer)
        }

        //NOTE: if you want to save sounds at file, use `mixer.installTap(OnBus:)` with new AudioFile
        
        try! audioEngine.start()
        inputRhythm.play()
        inputVoice.play()
    }
    
    func endPlay()
    {
        audioEngine.stop()
    }

    func writePackets(inBuffer: AudioQueueBufferRef)
    {
        
        let numPackets: UInt32 = (inBuffer.pointee.mAudioDataByteSize / audioObj.bytesPerPacket)
        audioObj.maxPacketCount += numPackets
        
        if 0 < numPackets
        {
            memcpy(audioObj.buffer!.advanced(by: Int(audioObj.bytesPerPacket * audioObj.startingPacketCount)),
                   inBuffer.pointee.mAudioData,
                   Int(audioObj.bytesPerPacket * numPackets))
            audioObj.startingPacketCount += numPackets;
        }
    }

    //NOTE: 複数のリズム・伴奏音声ファイルからBPMを取得する場合は、引数追加
    private func getPargeSpeed(buffer: AVAudioPCMBuffer) -> Float
    {
        let bpm = SoundAnalyze().getTempo(data: audioObj, pcmBuffer: buffer)
        if bpm < 0
        {
          return 1.0
        }
        return Float(bpm) / 100.0 // bpm of sample rhythm sound is 100.
    }
    
    private func getSoundsFromFile(_ filePath: URL)
    {
        // read sound signals from a sound file
        guard let audioFile = try? AVAudioFile(forReading: filePath) else {
          return
        }
        do {
            audioObj.rhythmDataBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length))
            try audioFile.read(into: audioObj.rhythmDataBuffer!)
        } catch {
            return
        }
    }
    
    private func analyzeSounds()
    {
        // TODO: FFT with Buffer Data if needed
        
    }
    
    private func toPCMBuffer(data: Data) -> AVAudioPCMBuffer
    {
        let audioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: audioObj.audioFormat.mSampleRate, channels: 1, interleaved: true)
        let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat!, frameCapacity: UInt32(data.count)/2)
        if let buffer = audioBuffer
        {
            buffer.frameLength = buffer.frameCapacity
            for i in 0..<data.count/2
            {
                // transform two bytes into a float (-1.0 - 1.0), required by the audio buffer
                buffer.floatChannelData?.pointee[i] = Float(Int16(data[i*2+1]) << 8 | Int16(data[i*2]))/Float(INT16_MAX)
            }
            return buffer
        }
        return AVAudioPCMBuffer()
    }
    
    //NOTE: if you want to display volume level, use this function and add UI parts.
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
    }
}
