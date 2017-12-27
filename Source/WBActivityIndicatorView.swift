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
/// - none: 不加载文字
/// - left: 靠左边
/// - right: 靠右边
/// - bottom: 靠底部
public enum TextLabelPosition {
    case none
    case left
    case right
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

    open static let shared = WBActivityIndicatorView()

    
}
