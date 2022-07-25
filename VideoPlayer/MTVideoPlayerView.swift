//
//  MTVideoPlayerView.swift
//  MammothAB
//
//  Created by wangtao on 2022/7/18.
//

import UIKit
import AVFoundation

class MTVideoPlayerTool {
    static func cameraRecordTime(timeCount: Int) -> String {
        let hour = timeCount / 3600
        let min = (timeCount - hour * 3600) / 60
        let second = timeCount - hour * 3600 - min * 60
        let hourStr = hour < 10 ? String(format: "0%d", hour) : String(hour)
        let minStr = min < 10 ? String(format: "0%d", min) : String(min)
        let secondStr = second < 10 ? String(format: "0%d", second) : String(second)
        return String(format: "%@:%@:%@", hourStr, minStr, secondStr)
    }
}

class MTVideoPlayerView: UIView {
    private var playerLayer: AVPlayerLayer!
    private var playerItem: AVPlayerItem?
    private var player: AVPlayer?
    private var playPauseButton: UIButton!
    fileprivate var navBar: MTVideoHorizontalPlayNavigationBar!
    private var url: URL?
    var backClosure:(() -> Void)?
    var disposeBag = DisposeBag()
    var downCount: Int = 0
    var isStart = false
    var orientation: PlayerOrientation = .vertical
    var isHaveNetWork = true
    var isInterrupt = false
    var isPlaying = false
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubViews()
    }
    func loadVideo(_ url: URL) {
        self.url = url
        playerItem = AVPlayerItem(url: url)
        player?.replaceCurrentItem(with: playerItem)
        resetUI()
        startPlay()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initSubViews(){
        self.backgroundColor = .black
        self.clipsToBounds = true
        player = AVPlayer()
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        playerLayer.backgroundColor = UIColor.black.cgColor
        self.layer.addSublayer(playerLayer)
        
        playPauseButton = UIButton(frame: .zero)
        playPauseButton.setImage(UIImage.bundle(named: "video_play"), for: .normal)
        playPauseButton.setImage(UIImage.bundle(named: "video_play"), for: .selected)
        playPauseButton.addTarget(self, action: #selector(startPlay), for: .touchUpInside)
        addSubview(playPauseButton)
        
        addSubview(controlView)
        addSubview(bottomSlider)
        
        bottomSlider.addSubview(highLightSlider)
        bringSubviewToFront(playPauseButton)
        
        navBar = MTVideoHorizontalPlayNavigationBar(frame: .zero)
        navBar.navTitle = "视频"
        navBar.setUpTarget(target: self)
        addSubview(navBar)
        navBar.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(44 + 40)
        }
        addSubview(indicatorView)
        indicatorView.snp.makeConstraints { make in
            make.centerX.equalTo(self.snp.centerX)
            make.centerY.equalTo(self.snp.centerY)
        }
        bindData()
        UIDevice.current.setValue(NSNumber.init(integerLiteral: UIDeviceOrientation.portrait.rawValue),
                                  forKey: "orientation")
        
    }
    
    func bindData() {
        controlView.playBtnClosure = {[weak self] in
            self?.startPlay()
        }
        controlView.timeSliderClosure = {[weak self] value in
            self?.handleProgressSlider(value: value)
        }
        controlView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(35)
        }
        controlView.fullScreenClosure = {[weak self] in
            self?.changeOrientation()
        }
        player?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 5), queue: .main, using: {[weak self] (cmtime) in
            guard let playerItem = self?.playerItem, let strongSelf = self else {return}
            if playerItem.duration.timescale == 0 {
                return
            }
            let second = CMTimeGetSeconds(cmtime)
            let duration = CMTimeGetSeconds(playerItem.duration)
            
            if self?.player?.rate != 0 {
                strongSelf.controlView.slider.value = Float(second / duration)
                strongSelf.playPauseButton.isHidden = true
                strongSelf.controlView.playedTimeLab.text = MTVideoPlayerTool.cameraRecordTime(timeCount: Int(second))
                strongSelf.controlView.durationTimeLab.text = MTVideoPlayerTool.cameraRecordTime(timeCount: Int(duration))
                strongSelf.highLightSlider.width = strongSelf.bounds.width * CGFloat(second / duration)
                strongSelf.isStart = true
                strongSelf.indicatorView.stopAnimating()
            }
        })
        addNotification()
    }
    func addNotification() {
        /// 添加通知
        NotificationCenter.default.addObserver(self, selector: #selector(playEnd), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.rx.notification(UIDevice.orientationDidChangeNotification).subscribe(onNext: { [weak self] _ in
            self?.changeOrientationComplete()
        }).disposed(by: disposeBag)
        let timerOne = Observable<Int>.timer(.seconds(1), period: .seconds(1), scheduler: MainScheduler.instance)
        timerOne.subscribe(onNext: {[weak self] _ in
            self?.timerAction()
        }).disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(.AVPlayerItemPlaybackStalled).subscribe(onNext: { [weak self]_ in
            guard let strongSelf = self else {return}
            strongSelf.isInterrupt = true
            if !strongSelf.isHaveNetWork {
                strongSelf.playPauseButton.isHidden = false
                strongSelf.playPauseButton.isSelected = true
                strongSelf.controlView.playerBottomPlayBtn.isSelected = true
            }
        }).disposed(by: disposeBag)
    }
    func changeOrientation() {
        let interfaceOrientation: UIInterfaceOrientation = UIDevice.current.orientation.isLandscape ? .portrait : .landscapeRight
        UIDevice.current.setValue(NSNumber.init(integerLiteral: interfaceOrientation.rawValue), forKey: "orientation")
    }
    
    func timerAction() {
        if !isStart {
            return
        }
        downCount += 1
        if downCount >= 4 {
            hiddenControlView(isHidden: true)
        }
    }
    
    func changeOrientationComplete() {
        let height = bounds.width * 0.56
        orientation = UIDevice.current.orientation.isPortrait ? .vertical : .horizontal
        controlView.fullScreenBtn.isSelected = orientation == .horizontal
        if  UIDevice.current.orientation.isPortrait {
            playerLayer.frame = CGRect(x: 0, y: (bounds.height - height) / 2.0 - 2, width: bounds.width, height: height)
            bottomSlider.frame = CGRect(x: 0, y: bounds.height - 2, width: bounds.width, height: 2)
            controlView.snp.remakeConstraints { make in
                make.left.right.bottom.equalToSuperview()
                make.height.equalTo(35)
            }
        } else {
            playerLayer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
            bottomSlider.frame = CGRect(x: 0, y: bounds.height - 2, width: bounds.width, height: 2)
            controlView.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                make.height.equalTo(35)
                make.bottom.equalToSuperview().offset(-25)
            }
        }
    }
    
    @objc func startPlay() {
        if player?.rate != 0 {
            stopPlay()
        } else {
            if isInterrupt && !isHaveNetWork {
                // 如果是没网的话 点击播放直接从头开始
                player?.seek(to: CMTime.init(value: 0, timescale: 1), completionHandler: {[weak self] (finish) in
                    if finish {
                        self?.isInterrupt = false
                        self?.playerStartPlayAction()
                    }
                })
                return
            }
            playerStartPlayAction()
        }
    }
    func stopPlay() {
        player?.pause()
        playPauseButton.isHidden = false
        controlView.playerBottomPlayBtn.isSelected = false
        playPauseButton.isSelected = false
        isPlaying = false
    }
    func playerStartPlayAction() {
        player?.play()
        playPauseButton.isHidden = true
        controlView.playerBottomPlayBtn.isSelected = true
        playPauseButton.isSelected = false
        isPlaying = true
    }
    @objc func pausePlay(_ sender: UIButton) {
        self.player?.pause()
    }
    
    func handleProgressSlider(value: Float) {
        guard let playerItem = playerItem else {return}
        if playerItem.duration.timescale == 0 {
            return
        }
        
        player?.pause()
        let dxT = value * Float(CMTimeGetSeconds(playerItem.duration))
        controlView.playedTimeLab.text = MTVideoPlayerTool.cameraRecordTime(timeCount: Int(dxT))
        switch player?.status {
        case .readyToPlay:
            let time = CMTimeMake(value: Int64(dxT), timescale: 1)
            player?.seek(to: time, completionHandler: {[weak self] (_) in
                if let isDraging = self?.controlView.slider.isDraging {
                    self?.downCount = 0
                    self?.isStart = false
                    self?.controlView.playerBottomPlayBtn.isSelected = false
                    if !isDraging {
                        self?.player?.play()
                        self?.controlView.playerBottomPlayBtn.isSelected = true
                        self?.isStart = true
                    }
                }
            })
        default:
            break
        }
    }
    
    func resetUI() {
        controlView.playedTimeLab.text = "00:00:00"
        if let playerItem = playerItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if playerItem.duration.timescale != 0 {
                    let duration = Int(CMTimeGetSeconds(playerItem.duration))
                    self.controlView.durationTimeLab.text = MTVideoPlayerTool.cameraRecordTime(timeCount: duration)
                }
            }
        }
        controlView.playerBottomPlayBtn.isSelected = false
        playPauseButton.isHidden = false
        controlView.slider.value = 0
    }
    
    /// 播放完成回调
    @objc func playEnd() {
        player?.seek(to: CMTime.init(value: 0, timescale: 1), completionHandler: {[weak self] (finish) in
            if finish {
                self?.playPauseButton.isSelected = true
                self?.playPauseButton.isHidden = false
                self?.controlView.playerBottomPlayBtn.isSelected = false
            }
        })
    }
    func hiddenControlView(isHidden: Bool) {
        UIView.animate(withDuration: 0.5) {
            if isHidden {
                self.controlView.transform = CGAffineTransform.init(translationX: 0, y: self.orientation == .vertical ?  35 : 70)
                self.navBar.transform = CGAffineTransform.init(translationX: 0, y: 0)
            } else {
                self.controlView.transform = CGAffineTransform.identity
                self.navBar.transform = CGAffineTransform.identity
            }
        } completion: { _ in
            self.bottomSlider.isHidden = !isHidden
            self.navBar.isHidden = isHidden
        }
    }
    override func removeFromSuperview() {
        super.removeFromSuperview()
        NotificationCenter.default.removeObserver(self)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.downCount = 0
        self.hiddenControlView(isHidden: self.bottomSlider.isHidden)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        changeOrientationComplete()
    }
    
    override func updateConstraints() {
        playPauseButton.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize.init(width: 58, height: 58))
        }
        super.updateConstraints()
    }
    lazy var bottomSlider: UIView = {
        let value = UIView()
        value.backgroundColor = UIColor.init(hexString: "#4D4D4D")
        value.isHidden = true
        return value
    }()
    lazy var highLightSlider: UIView = {
        let value = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 2))
        value.backgroundColor = UIColor.init(hexString: "#427FFF")
        return value
    }()
    lazy var controlView: LYVideoControlView = {
        let value = LYVideoControlView(frame: .zero)
        return value
    }()
    lazy var indicatorView: UIActivityIndicatorView = {
        let value  = UIActivityIndicatorView()
        value.style = .white
        value.startAnimating()
        return value
    }()
    
    deinit {
        player?.pause()
        player = nil
    }
}

extension MTVideoPlayerView: MTVideoHorizontalPlayNavigationBarDelegate {
    func goMoreDidHandle() {
        
    }
    
    func goBackDidHandle() {
        if self.orientation == .horizontal {
            changeOrientation()
        }
        DispatchQueue.main.asyncAfter(deadline: .now()+0.3) {
            self.backClosure?()
        }
    }
}

