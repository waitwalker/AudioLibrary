# AudioLibrary

[![CI Status](https://img.shields.io/travis/waitwalker/AudioLibrary.svg?style=flat)](https://travis-ci.org/waitwalker/AudioLibrary)
[![Version](https://img.shields.io/cocoapods/v/AudioLibrary.svg?style=flat)](https://cocoapods.org/pods/AudioLibrary)
[![License](https://img.shields.io/cocoapods/l/AudioLibrary.svg?style=flat)](https://cocoapods.org/pods/AudioLibrary)
[![Platform](https://img.shields.io/cocoapods/p/AudioLibrary.svg?style=flat)](https://cocoapods.org/pods/AudioLibrary)


## Requirements

## Installation

AudioLibrary is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'AudioLibrary'
```

## Basic Examples
```
import UIKit
import AudioLibrary

class ViewController: UIViewController {
    @IBOutlet weak var voiceImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /// setup delegate first
        ETTAudioManager.sharedInstance.delegate = self
    }
    
    
    
    /// start recording
    /// - Parameter sender:
    @IBAction func startRecording(_ sender: UIButton) {
        ETTAudioManager.sharedInstance.startRecording(filePath: nil)
        
    }
    
    /// stop recording
    /// - Parameter sender:
    @IBAction func stopRecording(_ sender: UIButton) {
        ETTAudioManager.sharedInstance.stopRecording()
        print("录音录制时长:\(ETTAudioManager.sharedInstance.recordingDuration)")
    }
    
    
    /// start playing
    /// - Parameter sender:
    @IBAction func startPlaying(_ sender: UIButton) {
        ETTAudioManager.sharedInstance.startPlayingAudio(localPath: ETTAudioManager.sharedInstance.recordFilePath!)
        print("录音播放时长:\(ETTAudioManager.sharedInstance.playingDuration)")
    }
    
    /// pause playing
    /// - Parameter sender:
    @IBAction func pausePlaying(_ sender: UIButton) {
        ETTAudioManager.sharedInstance.pausePlayingAudio()
        print("录音播放时长:\(ETTAudioManager.sharedInstance.playingDuration)")
    }
    
    /// stop playing
    /// - Parameter sender:
    @IBAction func stopPlaying(_ sender: UIButton) {
        ETTAudioManager.sharedInstance.stopPlayingAudio()
    }
}

/// ETTAudioManagerDelegate call back
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



```

## Author

waitwalker, waitwalker@163.com

## License

AudioLibrary is available under the MIT license. See the LICENSE file for more info.
