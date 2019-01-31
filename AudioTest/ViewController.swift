//
//  ViewController.swift
//  AudioTest
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var record: UIButton!
    @IBOutlet weak var rec_end: UIButton!
    @IBOutlet weak var stop: UIButton!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var label: UILabel!
    
    var audioService:AudioService! = AudioService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        rec_end.isHidden = true
        stop.isHidden = true
        indicator.isHidden = true
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        //stop to record
        //self.audioService.stopRecord()
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onTapRecordButton(_ sender: Any) {
        record.isHidden = true
        label.text = "Recording ... "
        //start to recode
        self.audioService.startRecord()
        rec_end.isHidden = false
    }

    @IBAction func OnTapRecEndButton(_ sender: Any) {
        rec_end.isHidden = true
        label.text = "Stopping ... "
        //stop to record
        self.audioService.stopRecord()
        label.text = "Converting Now. Please Wait. "
        indicator.isHidden = false
        //convert voice to music
        //self.audioService.pargeSounds()
        indicator.isHidden = true
        stop.isHidden = false
        //start to play a music
        self.audioService.startPlay()
        label.text = "Playing ... "
    }
    
    @IBAction func onTapStopButton(_ sender: Any) {
        stop.isHidden = true
        //stop a music
        //self.audioService.endPlay()
        label.text = "Tap to Record your Voice"
        record.isHidden = false
    }
}

