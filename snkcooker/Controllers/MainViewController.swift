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
    
    override func viewDidAppear() {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let newBot = ShopifyBot(target: BotTarget(site: .apbstore, quantity: 1, size: 8.5))
        
        newBot.cop(withProductUrl: "https://www.apbstore.com/collections/new-arrivals/products/aj-13-altitude-414571-042-blk-grn")
        
        self.emailComboBox.delegate = self
        
        self.loadSiteSelector()
        //self.loadEmailSelector()

        // Do any additional setup after loading the view.
    }
    
    private func loadSiteSelector() {
        let availableSites = [String(describing: Site.a_ma_maniere),String(describing: Site.apbstore),String(describing: Site.bowsandarrows),String(describing: Site.deadstock),String(describing: Site.exclucitylife),String(describing: Site.notre),String(describing: Site.rockcitykicks),String(describing: Site.shoegallerymiami),String(describing: Site.shopnicekicks),String(describing: Site.socialstatuspgh),String(describing: Site.yeezysupply)]
        self.siteSelector.addItems(withTitles: availableSites)
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

