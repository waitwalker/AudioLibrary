//
//  ViewController.swift
//  AudioLibrary
//
//  Created by waitwalker on 03/01/2021.
//  Copyright (c) 2021 waitwalker. All rights reserved.
//

import UIKit
import AudioLibrary

class ViewController: UIViewController {
    @IBOutlet weak var voiceImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ETTAudioManager.sharedInstance.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func startRecording(_ sender: UIButton) {
        ETTAudioManager.sharedInstance.startRecording(filePath: nil)
        
    }
    
    @IBAction func stopRecording(_ sender: UIButton) {
        ETTAudioManager.sharedInstance.stopRecording()
        print("录音录制时长:\(ETTAudioManager.sharedInstance.recordingDuration)")
    }
    
    
    @IBAction func startPlaying(_ sender: UIButton) {
        ETTAudioManager.sharedInstance.startPlayingAudio()
        print("录音播放时长:\(ETTAudioManager.sharedInstance.playingDuration)")
    }
    
    @IBAction func pausePlaying(_ sender: UIButton) {
        ETTAudioManager.sharedInstance.pausePlayingAudio()
        print("录音播放时长:\(ETTAudioManager.sharedInstance.playingDuration)")
    }
    
    @IBAction func stopPlaying(_ sender: UIButton) {
        ETTAudioManager.sharedInstance.stopPlayingAudio()
    }
    
    
}

extension ViewController: ETTAudioManagerDelegate {
    
    func audioMeterDidUpdate(_ audioDB: Float) {
        let currentAudioDB = Int((Int(audioDB) + 50) * 3 / 2)
        print("current audio db:\(currentAudioDB)")
        if currentAudioDB < 10 {
            self.voiceImageView.image = UIImage(named: "recording_ volume_0")
        } else if currentAudioDB >= 10 && currentAudioDB < 20 {
            self.voiceImageView.image = UIImage(named: "recording_ volume_1")
        } else if currentAudioDB >= 20 && currentAudioDB < 30 {
            self.voiceImageView.image = UIImage(named: "recording_ volume_2")
        } else if currentAudioDB >= 30 && currentAudioDB < 40 {
            self.voiceImageView.image = UIImage(named: "recording_ volume_3")
        } else {
            self.voiceImageView.image = UIImage(named: "recording_ volume_4")
        }
    }
    
    func audioRecordDidFinish(_ finishFlag: Bool) {
        print("finish flag:\(finishFlag)")
    }
    
    
    func audioDidError(_ errorType: ErrorType) {
        print("errorType:\(errorType)")
    }
    
    func audioPlayDidStop(_ finishType: PlayingState) {
        print("stop type:\(finishType)")
    }
}



