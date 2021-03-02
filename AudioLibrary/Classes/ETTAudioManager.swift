
import AVFoundation
import Toaster


/// 录音回调
@objc public protocol ETTAudioManagerDelegate: AVAudioRecorderDelegate {
    
    /// 更新当前db音量
    /// - Parameter audioDB: 当前音量值
    @objc optional func audioMeterDidUpdate(_ audioDB: Float)
}

/// 录制状态
public enum RecordingState { case recording, notRecording }

/// 播放状态
public enum PlayingState { case playing, notPlaying }


public class ETTAudioManager: NSObject {
    public static let sharedInstance = ETTAudioManager()
    
    /// 默认存储路径
    public var recordFilePath: URL?
    /// 录制状态
    public var recordState: RecordingState?
    /// 播放状态
    public var playState: PlayingState?
    
    /// 录制当前时间
    public var recordingCurrentTime: Int = 0
    /// 录制时长
    public var recordingDuration: Int = 0
    
    /// 播放当前时间
    public var playingCurrentTime: Int = 0
    /// 播放时长
    public var playingDuration: Int = 0
    
    public weak var delegate: ETTAudioManagerDelegate?
    
    
    
    /// 录音机
    private var audioRecorder: AVAudioRecorder!
    private var recordedAudioURL: URL!
    private var audioFile: AVAudioFile!
    private var audioEngine: AVAudioEngine!
    private var audioPlayerNode: AVAudioPlayerNode!
    private var audioTimer: Timer!
    private var audioPlayer: AVAudioPlayer?
    /// 是否是录制的timer
    private var isRecordingTimer: Bool = true
    private var count: Int = 0
    
    
    private override init() {
        
    }
    
    
    /// 开始录制
    /// - Parameter filePath: 录制文件的存储路径
    /// - Returns: Void
    public func startRecording(filePath: String?) -> Void {
        ETTAudioManager.sharedInstance.recordingDuration = 0
        var fullPath = filePath
        var fileURL: URL?
        
        if let path = filePath {
            fullPath = path
        } else {
            let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)[0] as String
            let recordingName = "recordedVoice.m4a"
            let pathArray = [dirPath, recordingName]
            fullPath = pathArray.joined(separator: "/")
        }
        fileURL = URL(string: fullPath!)
        ETTAudioManager.sharedInstance.recordFilePath = fileURL
        
        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
        
        let settings: [String: Any] = [
            AVFormatIDKey : NSNumber(value: Int32(kAudioFormatMPEG4AAC) as Int32),
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue as Any,
        ]

        try! self.audioRecorder = AVAudioRecorder(url: fileURL!, settings: settings)
        self.audioRecorder.delegate = self
        self.audioRecorder.isMeteringEnabled = true
        self.audioRecorder.prepareToRecord()
        
        if let audioM = self.audioRecorder {
            ETTAudioManager.sharedInstance.recordState = .recording
            
            isRecordingTimer = true
            setupTimer()
            audioM.record()
        } else {
            ETTAudioManager.sharedInstance.recordState = .notRecording
            //assert(self.audioRecorder == nil, "Init audioRecorder failed")
            Toast(text: "Init audioRecorder failed").show()
            
        }
    }
    
    
    /// 设置计时器
    /// - Returns: Void
    private func setupTimer() -> Void {
        if audioTimer == nil {
            count = 0
            audioTimer = Timer(timeInterval: isRecordingTimer ? 0.5 : 1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
            audioTimer.fire()
            RunLoop.current.add(audioTimer, forMode: RunLoop.Mode.common)
        }
    }
    
    
    /// 计时器事件
    /// - Returns: Void
    @objc func timerAction() -> Void {
        count = count + 1
        if isRecordingTimer {
            ETTAudioManager.sharedInstance.recordingCurrentTime = Int(count / 2)
            if self.delegate != nil && ((self.delegate?.responds(to: #selector(ETTAudioManagerDelegate.audioMeterDidUpdate(_ :)))) != nil) {
                guard let recorder = audioRecorder else {
                    Toast(text: "audioRecorder is nil").show()
                    return
                }
                
                recorder.updateMeters()
                let dB = recorder.averagePower(forChannel: 0)
                delegate?.audioMeterDidUpdate?(dB)
            }
        } else {
            ETTAudioManager.sharedInstance.playingCurrentTime = count
        }
        
    }
    
    
    /// 释放计时器
    /// - Returns: Void
    private func deallocTimer() -> Void {
        if audioTimer != nil {
            if isRecordingTimer {
                ETTAudioManager.sharedInstance.recordingCurrentTime = ETTAudioManager.sharedInstance.recordingDuration
            } else {
                ETTAudioManager.sharedInstance.playingCurrentTime = ETTAudioManager.sharedInstance.playingDuration
            }
            audioTimer.invalidate()
            audioTimer = nil
        }
    }
    
    
    /// 停止录制
    /// - Returns: Void
    public func stopRecording() -> Void {
        ETTAudioManager.sharedInstance.recordState = .notRecording
        if let audioM = self.audioRecorder {
            ETTAudioManager.sharedInstance.recordingDuration = Int(audioM.currentTime)
            audioM.stop()
            let audioSession = AVAudioSession.sharedInstance()
            try! audioSession.setActive(false)
            deallocTimer()
            print("音频时间")
        } else {
            ETTAudioManager.sharedInstance.recordingDuration = 0
            Toast(text: "stopRecording failed").show()
            //assert(self.audioRecorder == nil, "audioRecorder is nil ")
        }
    }
    
    
    /// 播放本地音频
    /// - Parameter localPath: 本地音频路径
    public func startPlayingAudio(localPath: URL? = nil) {
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: localPath ?? ETTAudioManager.sharedInstance.recordFilePath!)
            audioPlayer?.prepareToPlay()
            ETTAudioManager.sharedInstance.playingDuration = Int(audioPlayer!.duration)
            audioPlayer?.delegate = self
            
            isRecordingTimer = false
            setupTimer()
            audioPlayer?.play()
            ETTAudioManager.sharedInstance.playState = .playing
        } catch {
            Toast(text: "startPlayingAudio failed").show()
        }
    }
    
    /// 停止播放音频
    /// - Returns: Void
    public func stopPlayingAudio() -> Void {
        if audioPlayer == nil {
            Toast(text: "stopPlayingAudio failed").show()
            return
        }
        audioPlayer?.stop()
        deallocTimer()
        ETTAudioManager.sharedInstance.playState = .notPlaying
    }
    
    
    /// 设置音频相关文件
    /// - Parameter fileURL: 文件存储路径
    public func setupAudio(fileURL: URL) {
        do {
            recordedAudioURL = fileURL
            audioFile = try AVAudioFile(forReading: fileURL)
        } catch {
            Toast(text: "setupAudio failed").show()
        }
    }
    
    
    /// 开始播放音频
    /// - Parameters:
    ///   - rate: 播放速度
    ///   - pitch: 音调
    ///   - echo: 是否回声
    ///   - reverb: 是否混响
    public func playSound(rate: Float? = nil, pitch: Float? = nil, echo: Bool = false, reverb: Bool = false) {
        audioEngine = AVAudioEngine()
        
        audioPlayerNode = AVAudioPlayerNode()
        audioEngine.attach(audioPlayerNode)
        
        let changeRatePitchNode = AVAudioUnitTimePitch()
        if let pitch = pitch {
            changeRatePitchNode.pitch = pitch
        }
        if let rate = rate {
            changeRatePitchNode.rate = rate
        }
        audioEngine.attach(changeRatePitchNode)
        
        let echoNode = AVAudioUnitDistortion()
        echoNode.loadFactoryPreset(.multiEcho1)
        audioEngine.attach(echoNode)
        
        let reverbNode = AVAudioUnitReverb()
        reverbNode.loadFactoryPreset(.cathedral)
        reverbNode.wetDryMix = 50
        audioEngine.attach(reverbNode)
        
        if echo == true && reverb == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, reverbNode, audioEngine.outputNode)
        } else if echo == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, audioEngine.outputNode)
        } else if reverb == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, reverbNode, audioEngine.outputNode)
        } else {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, audioEngine.outputNode)
        }
        
        audioPlayerNode.stop()
        audioPlayerNode.scheduleFile(audioFile, at: nil) {
            
            var delayInSeconds: Double = 0
            if let lastRenderTime = self.audioPlayerNode.lastRenderTime, let playerTime = self.audioPlayerNode.playerTime(forNodeTime: lastRenderTime) {
                
                if let rate = rate {
                    delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate) / Double(rate)
                } else {
                    delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate)
                }
            }
        }
        
        do {
            try audioEngine.start()
        } catch {
            Toast(text: "playSound failed").show()
            return
        }
        
        // 开始播放
        audioPlayerNode.play()
    }
    
    func connectAudioNodes(_ nodes: AVAudioNode...) {
        for x in 0..<nodes.count-1 {
            audioEngine.connect(nodes[x], to: nodes[x+1], format: audioFile.processingFormat)
        }
    }
    
    func stopPlaying() -> Void {
        if audioPlayerNode == nil {
            Toast(text: "stopPlaying failed").show()
            return
        }
        
    }
    
}

extension ETTAudioManager: AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("录音结束状态:\(flag)")
        deallocTimer()
    }
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("播放本地音频状态:\(flag)")
        deallocTimer()
    }
}