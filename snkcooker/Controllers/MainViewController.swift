//
//  ViewController.swift
//  snkcooker
//
//  Created by 刘业臻 on 2017/12/16.
//  Copyright © 2017年 luiyezheng. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {
    var emailData:EmailsData?
    
    @IBOutlet var emailComboBox: NSComboBox!
    
    @IBOutlet var siteSelector: NSPopUpButton!

    @IBAction func sendSelectedSite(_ sender: NSPopUpButton) {
    }
    
    @IBAction func addTask(_ sender: NSButton) {
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //let newBot = ShopifyBot(target: BotTarget(site: .apbstore, quantity: 1, size: 9))
        //newBot.cop(withProductUrl: "https://www.apbstore.com/collections/new-arrivals/products/aj-13-altitude-414571-042-blk-grn")
        
        self.emailComboBox.delegate = self
        
        self.loadSiteSelector()
    }
    
    private func loadSiteSelector() {
        self.siteSelector.addItems(withTitles: Site.allSites)
    }
    
    private func loadEmailSelector() {
        self.emailData = EmailsData()
        if let abbrs = self.emailData?.abbrs {
            self.emailComboBox.removeAllItems()
            self.emailComboBox.addItems(withObjectValues: abbrs)
        }
    }
}


extension MainViewController:NSComboBoxDelegate {
    func comboBoxWillPopUp(_ notification: Notification) {
        self.loadEmailSelector()
    }
}

