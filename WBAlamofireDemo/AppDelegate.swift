//
//  AppDelegate.swift
//  WBAlamofire
//
//  Created by zwb on 17/3/24.
//  Copyright © 2017年 HengSu Technology. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        WBAlConfig.shared.baseURL = "https://timgsa.baidu.com/"
        WBAlConfig.shared.debugLogEnable = true
        
        WBAlConfig.shared.loadViewText = "Login"
        WBAlConfig.shared.loadViewTextFont = .systemFont(ofSize: 16)
        WBAlConfig.shared.loadViewTextColor = .red
        WBAlConfig.shared.loadViewAnimationType = .system
        WBAlConfig.shared.loadViewTextPosition = .bottom

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white
        window?.makeKeyAndVisible()
        
        window?.rootViewController = ViewController()

        /*
        // all the download cache file size
        WBAlCache.shared.downloadCacheSize
        // all requests the cache file size
        WBAlCache.shared.responseCacheFilesSize
        // remove single download file
        WBAlCache.shared.removeDownloadFiles(with: `YourFileName`)
        // remove all requests results cache file
        WBAlCache.shared.removeCacheFiles()
        // remove all the downloaded file
        WBAlCache.shared.removeDownloadFiles()
        // remove all download cache and network request results
        WBAlCache.shared.removeAllFiles()
         */
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

