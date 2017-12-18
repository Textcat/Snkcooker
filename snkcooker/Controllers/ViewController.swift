//
//  ViewController.swift
//  snkcooker
//
//  Created by 刘业臻 on 2017/12/16.
//  Copyright © 2017年 luiyezheng. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let plistPath:String? = Bundle.main.path(forResource: "userconfig", ofType: "plist")!
        let dict = NSMutableDictionary(contentsOfFile: plistPath!)
        let type = "Emails"
        
        var old_emails = dict![type] as! Array<String>
        
        old_emails.append("luiyezheng@126.com")
        print(old_emails)
        dict?.setValue(old_emails, forKey: "Emails")
        dict?.write(toFile: plistPath!, atomically: true)

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

