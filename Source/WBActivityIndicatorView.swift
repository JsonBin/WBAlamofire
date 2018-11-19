//
//  WBActivityIndicatorView.swift
//  WBAlamofire
//
//  Created by zwb on 2017/12/27.
//  Copyright © 2017年 HengSu Technology. All rights reserved.
//

/// Loading box is added in the network request, only in the iOS implementation,
/// tvOS, watchOS and does not involve in the macOS

#if os(iOS)
import UIKit

/// The position of the label text
///
/// - no: Don't show text
/// - bottom: in bottom
public enum TextLabelPosition {
    case no
    case bottom
}

/// The type of loading animation
///
/// - system: System built-in types (Daisy)
/// - native: Circular progress animation
public enum AnimationType  {
    case system
    case native
}

public final class WBActivityIndicatorView: UIView {

    private var textLabel: UILabel?
    private var indicator: UIActivityIndicatorView?
    private var animationView: WBActivityRodllView?
    private var parentView: UIView?
    private let detault = CGFloat(30)  // default width and height.

    public override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initUI()
    }
    
    /// Set the location of the text, defaults to the bottom
    public var labelPosition: TextLabelPosition = .bottom {
        didSet{
            if labelPosition == oldValue { return }
            setLabel()
        }
    }
    
    /// Set the type of animation. The default is system
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
        if let text = text { textLabel?.text = text }
        if let font = font { textLabel?.font = font }
        if let color = color { textLabel?.textColor  = color }
    }
}

// MARK: - Public Functions
extension WBActivityIndicatorView {
    
    /// Start Animation
    public func startAnimation(inView: UIView) {
        if inView.subviews.contains(self) { return }
        center = inView.center
        parentView = inView
        reloadViewFrame()
        indicator?.startAnimating()
        animationView?.start()
        inView.addSubview(self)
    }
    
    /// Stop Animation
    public func stopAnimation() {
        // recover
        bounds = CGRect(x: 0, y: 0, width: detault, height: detault)
        indicator?.stopAnimating()
        animationView?.stop()
        parentView = nil
        removeFromSuperview()
    }
}

// MARK: - Init Life Cycle
extension WBActivityIndicatorView {
    private func initUI() {
        backgroundColor = UIColor(white: 0.0, alpha: 0.85)
        layer.cornerRadius = 5.0
        layer.masksToBounds = true
        bounds = CGRect(x: 0, y: 0, width: detault, height: detault)
        
        textLabel = UILabel()
        textLabel?.textColor = WBAlConfig.shared.loadViewTextColor
        textLabel?.font = WBAlConfig.shared.loadViewTextFont
        textLabel?.textAlignment = .center
        textLabel?.numberOfLines = 0
        textLabel?.text = WBAlConfig.shared.loadViewText
        addSubview(textLabel!)

        #if swift(>=4.2)
        indicator = UIActivityIndicatorView(style: .white)
        #else
        indicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
        #endif
        indicator?.isHidden = true
        indicator?.hidesWhenStopped = false
        indicator?.backgroundColor = .clear
        indicator?.frame = bounds
        addSubview(indicator!)
        
        animationView = WBActivityRodllView()
        animationView?.isHidden = true
        animationView?.frame = bounds
        addSubview(animationView!)
        
        reloadViewFrame()
    }
}

// MARK: - Set Infomation
extension WBActivityIndicatorView {
    private func setLabel() {
        if labelPosition == .no {
            textLabel?.isHidden = true
        } else {
            textLabel?.isHidden = false
        }
        reloadViewFrame()
    }
    
    private func setIndicator() {
        animationView?.isHidden = true
        animationView?.stop()
        indicator?.isHidden = false
        indicator?.startAnimating()
        reloadViewFrame()
    }
    
    private func setAnimationView() {
        indicator?.stopAnimating()
        indicator?.isHidden = true
        animationView?.start()
        animationView?.isHidden = false
        reloadViewFrame()
    }
    
    private func reloadViewFrame() {
        guard let parentView = parentView else { return }
        if labelPosition == .no {
            textLabel?.isHidden = true
            bounds = CGRect(x: 0, y: 0, width: detault, height: detault)
            indicator?.frame = bounds
            animationView?.frame = bounds
            return
        }
        let textSize = CGSize(width: parentView.bounds.width / 3 * 2, height: parentView.bounds.height / 3 * 2)
        let font = textLabel?.font ?? WBAlConfig.shared.loadViewTextFont
        guard let size = textLabel?.text?.boundingRect(with: textSize, options: [.usesFontLeading,.truncatesLastVisibleLine,.usesLineFragmentOrigin], attributes: [.font: font], context: nil).size else { return }
        if size.width > bounds.size.width - 10 {
            bounds = CGRect(x: 0, y: 0, width: size.width + 10, height: detault + 15 + size.height)
        } else {
            bounds = CGRect(x: 0, y: 0, width: detault, height: detault + 15 + size.height)
        }
        let width = frame.size.width
        textLabel?.frame = CGRect(x: 5, y: 35, width: size.width, height: size.height)
        indicator?.frame = CGRect(x: width / 2 - 15, y: 5, width: 30, height: 30)
        animationView?.frame = CGRect(x: width / 2 - 15, y: 5, width: 30, height: 30)
    }
}

/// Loading AnimationView
public final class WBActivityRodllView: UIView {
    
    /// The line color.
    public var color: UIColor = .white {
        didSet { shapLayer?.strokeColor = color.cgColor }
    }
    /// The Animation duration with a cycle.
    public var duration: Double = 2
    
    private var lineWidth = CGFloat(3)
    private var index = CGFloat(0)
    private var canAnimation = false
    private var shapLayer: CAShapeLayer?
    
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
        shapLayer = CAShapeLayer()
        shapLayer?.fillColor = UIColor.clear.cgColor
        shapLayer?.strokeColor = color.cgColor
        #if swift(>=4.2)
        shapLayer?.lineCap = .round
        shapLayer?.lineJoin = .round
        #else
        shapLayer?.lineCap = kCALineCapRound
        shapLayer?.lineJoin = kCALineJoinRound
        #endif
        shapLayer?.lineWidth = lineWidth
        layer.addSublayer(shapLayer!)
    }
    
    /// Create a new Layer
    private func createLayerPath(_ index: CGFloat) -> CGPath {
        let _center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        let path = UIBezierPath(arcCenter: _center,
                                radius: bounds.width / 2 - lineWidth,
                                startAngle: .pi * 2 / 3 * index,
                                endAngle: .pi * 2 / 3 * index + 2 * .pi * 4 / 3,
                                clockwise: true)
        return path.cgPath
    }
    
    private func startAnimation() {
        let start = CABasicAnimation(keyPath: "strokeStart")
        start.fromValue = 0
        start.toValue = 1
        
        let end = CABasicAnimation(keyPath: "strokeEnd")
        end.fromValue = 0
        end.toValue = 1
        end.duration = duration / 2

        #if swift(>=4.2)
        start.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        end.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        #else
        start.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        end.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        #endif
        
        let group = CAAnimationGroup()
        group.duration = duration
        group.delegate = self
        group.animations = [start, end]
        shapLayer?.add(group, forKey: "strokeAniamtion")
    }
}

// MARK: - Public Interface
extension WBActivityRodllView {
    public func start() {
        if let keys = shapLayer?.animationKeys(), keys.count > 0 { return }
        canAnimation = true
        shapLayer?.path = createLayerPath(index)
        startAnimation()
    }
    
    public func stop() {
        shapLayer?.removeAllAnimations()
        canAnimation = false
    }
}

// MARK: - CAAnimationDelegate
extension WBActivityRodllView : CAAnimationDelegate {
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if !flag || !canAnimation { return }
        index += 1
        shapLayer?.path = createLayerPath(index.truncatingRemainder(dividingBy: 3))
        startAnimation()
    }
}
#endif
