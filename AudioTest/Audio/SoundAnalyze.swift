//
//  SoundAnalyze.swift
//  AudioTest
//
//  Created by 中川貴代 on 2019/01/24.
//

import Foundation
import AudioToolbox
import AVFoundation

class SoundAnalyze : NSObject {
    //extern "C" void rdft(int n, int isgn, double *a, int *ip, double *w);
//    INT CALLBACK DlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);
//    void GetDlgItemRect(HWND hDlg, int nIDDlgItem, RECT& rc);
//    HDC CreateBackBuffer(HWND hWnd, const int width, const int height);
//    void find_peak3(const double* a, size_t size, int *max_idx);
    
    let FLAME_LENGTH: Int = 512
    // 最大最小テンポ
    let MIN_BPM = 60
    let MAX_BPM = 240

    
    var vols: [Double]
    var diffs: [Double]
    var buffer: [[Float]]

    override init()
    {
        vols = Array<Double>()
        diffs = Array<Double>()
        buffer = Array<Array<Float>>()
        
    }
    
    func getTempo(data: AudioObject, pcmBuffer: AVAudioPCMBuffer) -> Int
    {
        let samplingRate = data.audioFormat.mSampleRate
        let nChannel = 3
        let nframe = data.data?.count
        
        guard let floatChannelData = pcmBuffer.floatChannelData else {
            return -1
        }

        buffer.removeAll()
        for i in 0 ..< nChannel {
            let buf:[Float] = Array(UnsafeMutableBufferPointer(start: floatChannelData[i], count: nframe!))
            buffer.append(buf)
        }

        // フレームの数
        let n = nframe! / FLAME_LENGTH
        
        vols.removeAll()
        for i in 0 ..< n {
            var vol:Double = 0
            for j in 0 ..< FLAME_LENGTH {
                let idx = i * FLAME_LENGTH + j
                let sound = Double(buffer[0][idx])
                vol += pow(sound, 2)
            }
            let vol2 = sqrt((1.0 / Double(FLAME_LENGTH)) * vol)
            vols.append(vol2)
        }
        
        diffs.removeAll()
        
        //音量の増分をとる
        for i in 0 ..< n - 1 {
            let value = vols[i] - vols[i + 1]
            let diff = value > 0 ? value : 0
            diffs.append(diff)
        }
        diffs.append(0)
        
        // フレームの数
        let s = samplingRate / Double(FLAME_LENGTH)
        
        var a:[Double] = []
        var b:[Double] = []
        var r:[Double] = []
        
        for bpm in MIN_BPM ... MAX_BPM {
            var aSum:Double = 0
            var bSum:Double = 0
            let f = Double(bpm) / Double(MIN_BPM)
            for i in 0 ..< n {
                aSum += diffs[i] * cos(2.0 * Double.pi * f * Double(i) / s)
                bSum += diffs[i] * sin(2.0 * Double.pi * f * Double(i) / s)
            }
            let aTMP = aSum / Double(n)
            let bTMP = bSum / Double(n)
            a.append(aTMP)
            b.append(bTMP)
            r.append(sqrt(pow(aTMP, 2) + pow(bTMP, 2)))
        }
        
        var maxIndex = 0
        
        // 一番マッチするインデックスを求める
        var dy:Double = 0
        for i in 1 ..< (MAX_BPM - MIN_BPM + 1) {
            let dyPre = dy
            dy = r[i] - r[i - 1]
            if dyPre > 0 && dy <= 0 {
                if maxIndex < 0 || r[i - 1] > r[maxIndex] {
                    maxIndex = i - 1
                }
            }
        }
        
        if maxIndex < 0 {
            return -1
        }
        return maxIndex + MIN_BPM
    }
}
