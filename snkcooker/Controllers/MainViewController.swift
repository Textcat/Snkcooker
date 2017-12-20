//
//  ViewController.swift
//  snkcooker
//
//  Created by 刘业臻 on 2017/12/16.
//  Copyright © 2017年 luiyezheng. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {
    var emailData:emails?
    var emailOptions:[String:String] = [:]
    
    @IBOutlet var emailSelector: NSPopUpButton!
    
    @IBOutlet var siteSelector: NSPopUpButton!

    @IBAction func sendSelectedSite(_ sender: NSPopUpButton) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadSiteSelector()
        self.loadEmailSelector()

        // Do any additional setup after loading the view.
    }
    
    private func loadSiteSelector() {
        let availableSites = [String(describing: Site.a_ma_maniere),String(describing: Site.apbstore),String(describing: Site.bowsandarrows),String(describing: Site.deadstock),String(describing: Site.exclucitylife),String(describing: Site.notre),String(describing: Site.rockcitykicks),String(describing: Site.shoegallerymiami),String(describing: Site.shopnicekicks),String(describing: Site.socialstatuspgh),String(describing: Site.yeezysupply)]
        self.siteSelector.addItems(withTitles: availableSites)
    }
    
    private func loadEmailSelector() {
        self.emailData = EmailsData().values
        if let emails = self.emailData {
            for email in emails {
                if let abbr = email["abbr"] {
                    self.emailSelector.addItem(withTitle: abbr)
                    self.emailOptions[abbr] = email["address"]
                }
            }
            print(self.emailOptions)
        }
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

