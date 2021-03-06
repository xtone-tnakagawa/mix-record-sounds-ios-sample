//
//  AudioService.swift
//  AudioTest
//
import AudioToolbox
import AVFoundation

class AudioObject : NSObject {
    // バッファ
    var buffer: UnsafeMutableRawPointer?
    // オーディオキューオブジェクト
    var audioQueueObject: AudioQueueRef?
    // 再生時のパケット数
    let numPacketsToRead: UInt32 = 1024
    // 録音時のパケット数
    let numPacketsToWrite: UInt32 = 1024
    // 再生/録音時の読み出し/書き込み位置
    var startingPacketCount: UInt32
    // 最大パケット数。（サンプリングレート x 秒数）
    var maxPacketCount: UInt32
    // パケットのバイト数
    let bytesPerPacket: UInt32 = 2
    // 録音時間（＝再生時間）
    var seconds: UInt32
    // オーディオストリームのフォーマット
    var audioFormat: AudioStreamBasicDescription {
        return AudioStreamBasicDescription(
            mSampleRate: 48000.0,  // サンプリング周波数
            mFormatID: kAudioFormatLinearPCM,  // フォーマットID（リニアPCM, MP3, AAC etc）
            mFormatFlags: AudioFormatFlags(kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked),  // フォーマットフラグ（エンディアン, 整数or浮動小数点数）
            mBytesPerPacket: 2,  // １パケットのバイト数（データ読み書き単位）
            mFramesPerPacket: 1,  // １パケットのフレーム数
            mBytesPerFrame: 2,  // １フレームのバイト数
            mChannelsPerFrame: 1,  // １フレームのチャンネル数
            mBitsPerChannel: 16,  // １チャンネルのビット数
            mReserved: 0
        )
    }
    // 書き出し/読み出し用のデータ
    var data: Data?
    var rhythmDataBuffer: AVAudioPCMBuffer?
    
    init(_ obj: Any?) {
        startingPacketCount = 0
        maxPacketCount = 0
        seconds = 0
        buffer = UnsafeMutableRawPointer(malloc(Int(1000000 * bytesPerPacket)))
    }
    deinit {
        buffer!.deallocate()
    }
    
    func reset() {
        data = nil
        rhythmDataBuffer = nil
        buffer!.deallocate()
        startingPacketCount = 0
        maxPacketCount = 0
        seconds = 0
        buffer = UnsafeMutableRawPointer(malloc(Int(1000000 * bytesPerPacket)))
    }
}
