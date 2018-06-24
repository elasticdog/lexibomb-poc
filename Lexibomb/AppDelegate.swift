//
//  AppDelegate.swift
//  Lexibomb
//
//  Created by Alan Westbrook on 6/29/14.
//  Copyright (c) 2014 Elastic Dog. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?

    private func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        assert(UIDevice.current.userInterfaceIdiom == .pad, "Lexibom(tm)(sm)(r)(c) can only run on pad-like devices")
        return true
    }

}

