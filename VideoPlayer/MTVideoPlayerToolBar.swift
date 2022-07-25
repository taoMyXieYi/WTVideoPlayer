//
//  MTVideoPlayerToolBar.swift
//  MammothAB
//
//  Created by wangtao on 2022/7/18.
//

import Foundation
import UIKit
/// 播放器（屏幕）方向
enum PlayerOrientation {
    case horizontal
    case vertical
}
protocol MTVideoHorizontalPlayNavigationBarDelegate: AnyObject {
    func goBackDidHandle()
    func goMoreDidHandle()
}
protocol MTVideoComponentProtocol {
    func setUpTarget(target: AnyObject)
}

class MTVideoHorizontalPlayNavigationBar: UIView, MTVideoComponentProtocol {
    var navTitle: String = "视频" {
        didSet {
            backBtn.set(image: UIImage.bundle(named: "video_back_white"), title: navTitle, titlePosition: .right, additionalSpacing: 4, state: .normal)
        }
    }
    private var backBtn: UIButton!
    private var bgLayer: CAGradientLayer!
    private weak var delegate: MTVideoHorizontalPlayNavigationBarDelegate?
    
    @objc private func back(_ sender: UIButton) {
        delegate?.goBackDidHandle()
    }
    
    @objc private func more(_ sender: UIButton) {
        delegate?.goMoreDidHandle()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        bgLayer = CAGradientLayer()
        bgLayer.colors = [UIColor(red: 0, green: 0, blue: 0, alpha: 0.35).cgColor,
                          UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor]
        bgLayer.locations = [0, 1]
        bgLayer.frame = self.bounds
        bgLayer.startPoint = CGPoint(x: 0, y: 0)
        bgLayer.endPoint = CGPoint(x: 0, y: 1)
        self.layer.addSublayer(bgLayer)
        
        backBtn = UIButton(frame: .zero)
        backBtn.setTitleColor(.white, for: .normal)
        backBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        backBtn.addTarget(self, action: #selector(back(_:)), for: .touchUpInside)
        backBtn.set(image: UIImage.bundle(named: "video_back_white"), title: "视频", titlePosition: .right, additionalSpacing: 4, state: .normal)
        addSubview(backBtn)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        backBtn.snp.updateConstraints { (make) in
            make.left.equalToSuperview().offset(kStatusBarH > 20 ? 44 : kStatusBarH)
            make.centerY.equalToSuperview()
        }
        super.updateConstraints()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        bgLayer.frame = self.bounds
    }
    func setUpTarget(target: AnyObject) {
        guard let target = target as? MTVideoHorizontalPlayNavigationBarDelegate else { return }
        delegate = target
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
}
///进度条
class LYMinSlider: UISlider {
    var isDraging: Bool = false
    var sliderHeight: CGFloat = 2
    override init(frame: CGRect) {
        super.init(frame: frame)
        minimumTrackTintColor = UIColor(hex: 0x427FFF)
        maximumTrackTintColor = UIColor(hex: 0x8E8A88).withAlphaComponent(0.8)
        setThumbImage(UIImage.bundle(named: "video_point_icon"), for: .normal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect.init(x: 0, y: (bounds.height - sliderHeight) / 2.0,     width: frame.width, height: sliderHeight)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDraging = true
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDraging = false
        super.touchesEnded(touches, with: event)
    }
}

class LYVideoControlView: UIView {
    var slider: LYMinSlider!
    var playedTimeLab: UILabel!
    var durationTimeLab: UILabel!
    var playerBottomPlayBtn: UIButton!
    var fullScreenBtn: UIButton!
    var playBtnClosure:(() -> Void)?
    var timeSliderClosure: ((Float) -> Void)?
    var fullScreenClosure:(() -> Void)?
    var bgLayer: CAGradientLayer!
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        initInterface()
        self.clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func changePadding(orientation: PlayerOrientation = .vertical){
        if orientation == .vertical {
            playerBottomPlayBtn.snp.updateConstraints { make in
                make.left.equalTo(20)
            }
            fullScreenBtn.snp.updateConstraints { make in
                make.right.equalTo(-20)
            }
        } else {
            playerBottomPlayBtn.snp.updateConstraints { make in
                make.left.equalTo(50)
            }
            fullScreenBtn.snp.updateConstraints { make in
                make.right.equalTo(-50)
            }
        }
        slider.sliderHeight = orientation == .vertical ? 2 : 6
        self.layoutIfNeeded()
    }
    func hiddenControlView(isHidden: Bool){
        bgLayer.isHidden = isHidden
        UIView.animate(withDuration: 0.5) {
            if isHidden {
                self.playerBottomPlayBtn.snp.updateConstraints { make in
                    make.centerY.equalTo(self.snp.centerY).offset(self.bounds.height)
                }
            } else{
                self.playerBottomPlayBtn.snp.updateConstraints { make in
                    make.centerY.equalTo(self.snp.centerY).offset(0)
                }
            }
            self.layoutIfNeeded()
        } completion: { _ in}
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        bgLayer.frame = self.bounds
    }
    func initInterface(){
        bgLayer = CAGradientLayer()
        bgLayer.colors = [UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor,
                          UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor]
        bgLayer.locations = [0, 1]
        bgLayer.frame = self.bounds
        bgLayer.startPoint = CGPoint(x: 0, y: 0)
        bgLayer.endPoint = CGPoint(x: 0, y: 1)
        self.layer.addSublayer(bgLayer)
        
        playerBottomPlayBtn = UIButton(type: .custom)
        playerBottomPlayBtn.setImage(UIImage.bundle(named: "video_pause"), for: .selected)
        playerBottomPlayBtn.setImage(UIImage.bundle(named: "video_play"), for: .normal)
        addSubview(playerBottomPlayBtn)
        playerBottomPlayBtn.addTarget(self, action: #selector(startPlay(_:)), for: .touchUpInside)
        playerBottomPlayBtn.snp.makeConstraints { (make) in
            make.left.equalTo(20)
            make.size.equalTo(CGSize.init(width: 24, height: 24))
            make.centerY.equalTo(self.snp.centerY)
        }
        
        playedTimeLab = UILabel()
        playedTimeLab.textColor = .white
        playedTimeLab.font = UIFont.systemFont(ofSize: 13)
        addSubview(playedTimeLab)
        playedTimeLab.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.playerBottomPlayBtn.snp.centerY)
            make.left.equalTo(self.playerBottomPlayBtn.snp.right).offset(8)
            make.width.equalTo(58)
        }
        
        //    fullscreen
        fullScreenBtn = UIButton(type: .custom)
        fullScreenBtn.setImage(UIImage.bundle(named: "video_fullscreen_quit"), for: .selected)
        fullScreenBtn.setImage(UIImage.bundle(named: "video_fullscreen"), for: .normal)
        fullScreenBtn.addTarget(self, action: #selector(fullScreenAction), for: .touchUpInside)
        addSubview(fullScreenBtn)
        fullScreenBtn.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize.init(width: 24, height: 24))
            make.right.equalTo(-20)
            make.centerY.equalTo(self.playerBottomPlayBtn.snp.centerY)
        }
        
        durationTimeLab = UILabel()
        durationTimeLab.textColor = .white
        durationTimeLab.font = UIFont.systemFont(ofSize: 13)
        addSubview(durationTimeLab)
        durationTimeLab.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.playerBottomPlayBtn.snp.centerY)
            make.right.equalTo(self.fullScreenBtn.snp.left).offset(-8)
        }
        
        slider = LYMinSlider(frame: .zero)
        addSubview(slider)
        slider.snp.makeConstraints { (make) in
            make.left.equalTo(self.playedTimeLab.snp.right).offset(8)
            make.right.equalTo(self.durationTimeLab.snp.left).offset(-8)
            make.centerY.equalTo(self.playerBottomPlayBtn.snp.centerY)
        }
        slider.addTarget(self, action: #selector(handleProgressSlider(slider:)), for: .valueChanged)
    }
    @objc func startPlay(_ sender: UIButton) {
        playBtnClosure?()
    }
    @objc func handleProgressSlider(slider: UISlider) {
        timeSliderClosure?(slider.value)
    }
    @objc func fullScreenAction(){
        fullScreenClosure?()
    }
}

