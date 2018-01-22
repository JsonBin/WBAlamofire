//
//  WBActivityIndicatorView.swift
//  WBAlamofire
//
//  Created by zwb on 2017/12/27.
//  Copyright © 2017年 HengSu Technology. All rights reserved.
//

import UIKit

/// label文字所处的位置
///
/// - no: 不加载文字
/// - bottom: 靠底部
public enum TextLabelPosition {
    case no
    case bottom
}

/// 加载动画的类型
///
/// - system: 系统自带类型(菊花)
/// - native: 圆形progress动画
public enum AnimationType  {
    case system
    case native
}

/// 加载视图
open class WBActivityIndicatorView: UIView {

    private var _textLabel: UILabel?
    private var _indicator: UIActivityIndicatorView?
    private var _animationView: WBActivityRodllView?
    private var _parentView: UIView?
    private let _detault = CGFloat(30)  // default width and height.

    public override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initUI()
    }
    
    /// 设置文本的位置，默认为右边
    public var labelPosition: TextLabelPosition = .bottom {
        didSet{
            if labelPosition == oldValue { return }
            setLabel()
        }
    }
    
    /// 设置动画的类型，默认为系统菊花
    public var animationType: AnimationType = .system {
        didSet{
            if animationType == oldValue { return }
            if animationType == .system {
                setIndicator()
            }
            if animationType == .native {
                setAnimationView()
            }
        }
    }
    
    /// Set the label's properties
    ///
    /// - Parameters:
    ///   - text: The Label text.
    ///   - font: The label text font.
    ///   - color: The label text color.
    public func setActivityLabel(text: String?, font: UIFont?, color: UIColor?) {
        if let text = text { _textLabel?.text = text }
        if let font = font { _textLabel?.font = font }
        if let color = color { _textLabel?.textColor  = color }
    }
}

// MARK: - Public Functions
extension WBActivityIndicatorView {
    
    /// Start Animation
    public func startAnimation(inView: UIView) {
        if inView.subviews.contains(self) { return }
        center = inView.center
        _parentView = inView
        reloadViewFrame()
        _indicator?.startAnimating()
        _animationView?.start()
        inView.addSubview(self)
    }
    
    /// Stop Animation
    public func stopAnimation() {
        // recover
        bounds = CGRect(x: 0, y: 0, width: _detault, height: _detault)
        _indicator?.stopAnimating()
        _animationView?.stop()
        _parentView = nil
        removeFromSuperview()
    }
}

// MARK: - Init Life Cycle
extension WBActivityIndicatorView {
    private func initUI() {
        backgroundColor = UIColor(white: 0.0, alpha: 0.85)
        layer.cornerRadius = 5.0
        layer.masksToBounds = true
        bounds = CGRect(x: 0, y: 0, width: _detault, height: _detault)
        
        _textLabel = UILabel()
        _textLabel?.textColor = WBAlConfig.shared.loadViewTextColor
        _textLabel?.font = WBAlConfig.shared.loadViewTextFont
        _textLabel?.textAlignment = .center
        _textLabel?.numberOfLines = 0
        _textLabel?.text = WBAlConfig.shared.loadViewText
        addSubview(_textLabel!)
        
        _indicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
        _indicator?.isHidden = true
        _indicator?.hidesWhenStopped = false
        _indicator?.backgroundColor = .clear
        _indicator?.frame = bounds
        addSubview(_indicator!)
        
        _animationView = WBActivityRodllView()
        _animationView?.isHidden = true
        _animationView?.frame = bounds
        addSubview(_animationView!)
        
        reloadViewFrame()
    }
}

// MARK: - 设置
extension WBActivityIndicatorView {
    private func setLabel() {
        if labelPosition == .no {
            _textLabel?.isHidden = true
        }else{
            _textLabel?.isHidden = false
        }
        reloadViewFrame()
    }
    
    private func setIndicator() {
        _animationView?.isHidden = true
        _animationView?.stop()
        _indicator?.isHidden = false
        _indicator?.startAnimating()
        reloadViewFrame()
    }
    
    private func setAnimationView() {
        _indicator?.stopAnimating()
        _indicator?.isHidden = true
        _animationView?.start()
        _animationView?.isHidden = false
        reloadViewFrame()
    }
    
    private func reloadViewFrame() {
        guard let parentView = _parentView else { return }
        if labelPosition == .no {
            _textLabel?.isHidden = true
            bounds = CGRect(x: 0, y: 0, width: _detault, height: _detault)
            _indicator?.frame = bounds
            _animationView?.frame = bounds
            return
        }
        let textSize = CGSize(width: parentView.bounds.width / 3 * 2, height: parentView.bounds.height / 3 * 2)
        let font = _textLabel?.font ?? WBAlConfig.shared.loadViewTextFont
        guard let size = _textLabel?.text?.boundingRect(with: textSize, options: [.usesFontLeading,.truncatesLastVisibleLine,.usesLineFragmentOrigin], attributes: [.font: font], context: nil).size else { return }
        if size.width > bounds.size.width - 10 {
            bounds = CGRect(x: 0, y: 0, width: size.width + 10, height: _detault + 15 + size.height)
        }else{
            bounds = CGRect(x: 0, y: 0, width: _detault, height: _detault + 15 + size.height)
        }
        let width = frame.size.width
        _textLabel?.frame = CGRect(x: 5, y: 35, width: size.width, height: size.height)
        _indicator?.frame = CGRect(x: width / 2 - 15, y: 5, width: 30, height: 30)
        _animationView?.frame = CGRect(x: width / 2 - 15, y: 5, width: 30, height: 30)
    }
}

/// Loading AnimationView
public class WBActivityRodllView: UIView {
    
    /// The line color.
    public var color: UIColor = .white {
        didSet { _shapLayer?.strokeColor = color.cgColor }
    }
    /// The Animation duration with a cycle.
    public var duration: Double = 2
    
    private var _lineWidth = CGFloat(3)
    private var _index = CGFloat(0)
    private var _canAnimation = false
    private var _shapLayer: CAShapeLayer?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initUI()
    }
    
    private func initUI() {
        backgroundColor = .clear
        _shapLayer = CAShapeLayer()
        _shapLayer?.fillColor = UIColor.clear.cgColor
        _shapLayer?.strokeColor = color.cgColor
        _shapLayer?.lineCap = kCALineCapRound
        _shapLayer?.lineJoin = kCALineJoinRound
        _shapLayer?.lineWidth = _lineWidth
        layer.addSublayer(_shapLayer!)
    }
    
    /// Create a new Layer
    private func createLayerPath(_ index: CGFloat) -> CGPath {
        let _center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        let path = UIBezierPath(arcCenter: _center, radius: bounds.width / 2 - _lineWidth, startAngle: .pi * 2 / 3 * index, endAngle: .pi * 2 / 3 * index + 2 * .pi * 4 / 3, clockwise: true)
        return path.cgPath
    }
    
    private func startAnimation() {
        let start = CABasicAnimation(keyPath: "strokeStart")
        start.fromValue = 0
        start.toValue = 1
        start.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        let end = CABasicAnimation(keyPath: "strokeEnd")
        end.fromValue = 0
        end.toValue = 1
        end.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        end.duration = duration / 2
        
        let group = CAAnimationGroup()
        group.duration = duration
        group.delegate = self
        group.animations = [start, end]
        _shapLayer?.add(group, forKey: "strokeAniamtion")
    }
}

// MARK: - Public Interface
extension WBActivityRodllView {
    public func start() {
        if let keys = _shapLayer?.animationKeys(), keys.count > 0 { return }
        _canAnimation = true
        _shapLayer?.path = createLayerPath(_index)
        startAnimation()
    }
    
    public func stop() {
        _shapLayer?.removeAllAnimations()
        _canAnimation = false
    }
}

// MARK: - CAAnimationDelegate
extension WBActivityRodllView : CAAnimationDelegate {
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if !flag || !_canAnimation { return }
        _index += 1
        _shapLayer?.path = createLayerPath(_index.truncatingRemainder(dividingBy: 3))
        startAnimation()
    }
}
