//
//  MTVideoPlayerTools.swift
//  MammothAB
//
//  Created by wangtao on 2022/7/22.
//

import Foundation

extension UIImage {
    static func bundle(named: String) -> UIImage? {
        let bundle = MTResourceBundle() ?? .main
        let image = UIImage(named: named, in: bundle, compatibleWith: nil)
        return image
    }
}
func MTResourceBundle() -> Bundle? {
    let frameworkpath = Bundle.main.bundlePath
    let frameworkbundleTmp = Bundle.init(path: frameworkpath)
    guard let frameworkbundle = frameworkbundleTmp else {return nil}
    let resourcepath = frameworkbundle.path(forResource: "MTVideoPlayer", ofType: "bundle", inDirectory: nil)
    if let path = resourcepath {
        return Bundle(path: path)
    }
    return nil
}
