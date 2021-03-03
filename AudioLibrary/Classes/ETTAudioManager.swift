
import AVFoundation


/// 录音回调
@objc public protocol ETTAudioManagerDelegate: AVAudioRecorderDelegate {
    
    /// 更新当前db音量
    /// - Parameter audioDB: 当前音量值
    @objc optional func audioMeterDidUpdate(_ audioDB: Float) -> Void
    
    /// 音频录制结束
    /// - Parameter flag: 结束成功状态
    @objc optional func audioRecordDidFinish(_ finishFlag: Bool) -> Void
    
    /// 音频播放结束
    /// - Parameter finishType: 音频结束播放类型:自动结束/手动结束/暂停
    @objc optional func audioPlayDidStop(_ finishType: PlayingState) -> Void
    
    /// 错误
    /// - Parameter errorType: 错误类型
    @objc optional func audioDidError(_ errorType: ErrorType) -> Void
}

/// 录制状态
public enum RecordingState { case recording, notRecording }

/// 播放状态
@objc public enum PlayingState: Int {
    case playing     = 0
    case pause       = 1
    case manualFinsh = 2
    case autoFinish  = 3
}

/// 错误类型
@objc public enum ErrorType: Int {
    case audioRecorderInitFailed         = -1
    case audioRecorderIsNil              = -2
    case audioRecorderStopFailed         = -3
    case audioPlayerPlayFailed           = -4
    case audioPlayerPlayEncodeError      = -5
    case audioPlayerStopFailed           = -6
}


/// 音频录制&播放管理类
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
    private var pauseCount: Int = 0;
    
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
            fullPath = setupFilePath()
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
            if self.delegate != nil && ((self.delegate?.responds(to: #selector(ETTAudioManagerDelegate.audioDidError(_ :)))) != nil) {
                delegate?.audioDidError?(.audioRecorderInitFailed)
                return
            }
        }
    }
    
    
    /// 设置计时器
    /// - Returns: Void
    private func setupTimer() -> Void {
        if audioTimer == nil {
            count = ETTAudioManager.sharedInstance.playState == .pause ? pauseCount : 0
            audioTimer = Timer(timeInterval: 0.1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
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
                    if self.delegate != nil && ((self.delegate?.responds(to: #selector(ETTAudioManagerDelegate.audioDidError(_ :)))) != nil) {
                        delegate?.audioDidError?(.audioRecorderIsNil)
                    }
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
            if self.delegate != nil && ((self.delegate?.responds(to: #selector(ETTAudioManagerDelegate.audioDidError(_ :)))) != nil) {
                delegate?.audioDidError?(.audioRecorderStopFailed)
                return
            }
        }
    }
    
    
    /// 播放本地音频
    /// - Parameter localPath: 本地音频路径
    public func startPlayingAudio(localPath: URL) {
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: localPath)
            audioPlayer?.prepareToPlay()
            ETTAudioManager.sharedInstance.playingDuration = Int(audioPlayer!.duration)
            audioPlayer?.delegate = self
            
            isRecordingTimer = false
            if ETTAudioManager.sharedInstance.playState == .pause {
                audioPlayer?.currentTime = Double(pauseCount) / 10.0
                audioPlayer?.play()
                setupTimer()
                ETTAudioManager.sharedInstance.playState = .playing
            } else {
                audioPlayer?.play()
                ETTAudioManager.sharedInstance.playState = .playing
                setupTimer()
            }
            
        } catch {
            if self.delegate != nil && ((self.delegate?.responds(to: #selector(ETTAudioManagerDelegate.audioDidError(_ :)))) != nil) {
                delegate?.audioDidError?(.audioPlayerPlayFailed)
                return
            }
        }
    }
    
    
    /// 暂停本地音频播放
    /// - Returns: Void
    public func pausePlayingAudio() -> Void {
        if audioPlayer == nil {
            if self.delegate != nil && ((self.delegate?.responds(to: #selector(ETTAudioManagerDelegate.audioDidError(_ :)))) != nil) {
                delegate?.audioDidError?(.audioPlayerStopFailed)
                return
            }
        }
        audioPlayer?.pause()
        deallocTimer()
        ETTAudioManager.sharedInstance.playState = .pause
        ETTAudioManager.sharedInstance.pauseCount = count
        
        if self.delegate != nil && ((self.delegate?.responds(to: #selector(ETTAudioManagerDelegate.audioPlayDidStop(_ :)))) != nil) {
            delegate?.audioPlayDidStop?(.pause)
        }
    }
    
    /// 停止播放音频
    /// - Returns: Void
    public func stopPlayingAudio() -> Void {
        if audioPlayer == nil {
            if self.delegate != nil && ((self.delegate?.responds(to: #selector(ETTAudioManagerDelegate.audioDidError(_ :)))) != nil) {
                delegate?.audioDidError?(.audioPlayerStopFailed)
                return
            }
        }
        audioPlayer?.stop()
        deallocTimer()
        ETTAudioManager.sharedInstance.playState = .manualFinsh
        if self.delegate != nil && ((self.delegate?.responds(to: #selector(ETTAudioManagerDelegate.audioPlayDidStop(_ :)))) != nil) {
            delegate?.audioPlayDidStop?(.manualFinsh)
            return
        }
    }
    
    
    /// 设置文件本地缓存路径
    /// - Returns: Void
    private func setupFilePath() -> String {
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)[0] as String
        let recordingName = "recordedVoice.m4a"
        let pathArray = [dirPath, recordingName]
        let fullPath = pathArray.joined(separator: "/")
        return fullPath
    }
}


extension ETTAudioManager: AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("录音结束状态:\(flag)")
        deallocTimer()
        if self.delegate != nil && ((self.delegate?.responds(to: #selector(ETTAudioManagerDelegate.audioRecordDidFinish(_:)))) != nil) {
            delegate?.audioRecordDidFinish?(flag)
            return
        }
    }
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("播放本地音频状态:\(flag)")
        deallocTimer()
        ETTAudioManager.sharedInstance.playState = .autoFinish
        if self.delegate != nil && ((self.delegate?.responds(to: #selector(ETTAudioManagerDelegate.audioPlayDidStop(_ :)))) != nil) {
            delegate?.audioPlayDidStop?(.autoFinish)
            return
        }
    }
    
    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("播放本地音频解码错误:\(error!)")
        if self.delegate != nil && ((self.delegate?.responds(to: #selector(ETTAudioManagerDelegate.audioDidError(_ :)))) != nil) {
            delegate?.audioDidError?(.audioPlayerPlayEncodeError)
            return
        }
    }
}
