//
//  UserconfigViewController.swift
//  snkcooker
//
//  Created by 刘业臻 on 2017/12/19.
//  Copyright © 2017年 luiyezheng. All rights reserved.
//

import Cocoa

class UserconfigViewController: NSViewController {
    @IBOutlet var shipFirstName: NSTextField!
    @IBOutlet var shipLastName: NSTextField!
    @IBOutlet var shipAddress1: NSTextField!
    @IBOutlet var shipAddress2: NSTextField!
    @IBOutlet var shipCity: NSTextField!
    @IBOutlet var shipCountry: NSTextField!
    @IBOutlet var shipProvince: NSTextField!
    @IBOutlet var shipZip: NSTextField!
    @IBOutlet var shipPhone: NSTextField!
    
    @IBOutlet var billFirstName: NSTextField!
    @IBOutlet var billLastName: NSTextField!
    @IBOutlet var billAddress1: NSTextField!
    @IBOutlet var billAddress2: NSTextField!
    @IBOutlet var billCity: NSTextField!
    @IBOutlet var billCountry: NSTextField!
    @IBOutlet var billProvince: NSTextField!
    @IBOutlet var billZip: NSTextField!
    @IBOutlet var billPhone: NSTextField!
    
    override func viewDidLoad() {
        PlistDicManager.checkExist()
        super.viewDidLoad()
        
        // Do view setup here.
    }
    
    private func loadUserConfig() {
        let shipAddressDic = PlistDicManager.readPlistObject(withkey: "ShippingAddress")
        
    }
}

