//
//  ViewController.swift
//  snkcooker
//
//  Created by 刘业臻 on 2017/12/16.
//  Copyright © 2017年 luiyezheng. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {
    
    @IBOutlet var emailComboBox: NSComboBox!
    
    @IBOutlet var siteSelector: NSPopUpButton!
    
    @IBOutlet var sizeTextField: NSTextField!
    
    @IBOutlet var kwdTextField: NSTextField!
    
    @IBOutlet var earlyLinkTextField: NSTextField!
    
    @IBOutlet var autoCheckoutButton: NSButton!
    
    @IBOutlet var startSelectedButton: NSButton!
    
    @IBOutlet var stopSelectedButton: NSButton!
    
    @IBOutlet var deleteSelected: NSButton!
    
    @IBOutlet var copySelecteButton: NSButton!
    
    @IBOutlet var startAllButton: NSButton!
    
    @IBOutlet var stopAllButton: NSButton!
    
    @IBOutlet var deleteAllButton: NSButton!
    
    @IBAction func sendSelectedSite(_ sender: NSPopUpButton) {
        
    }
    
    @IBOutlet var taskTableView: NSTableView!
    
    @IBAction func addTask(_ sender: NSButton) {
        var email = ""
        if let mailStr = EmailsData().emailOptions[self.emailComboBox.stringValue] {
            email = mailStr
        }else if self.emailComboBox.stringValue.isValidEmail(){
            email = self.emailComboBox.stringValue
        }else {
            self.emailComboBox.becomeFirstResponder()
            return
        }
        
        let size = self.sizeTextField.stringValue
        guard let sizeNum = Double(size) else {return}
        if !size.isValidSize() {
            self.sizeTextField.becomeFirstResponder()
            return
        }
        
        let kwd = self.kwdTextField.stringValue
        if !kwd.isValidKeywords() {
            self.kwdTextField.becomeFirstResponder()
            return
        }
        let link = self.earlyLinkTextField.stringValue
        let autoCheckout = (self.autoCheckoutButton.state.rawValue == 1)
        guard let site = self.siteSelector.selectedItem?.title else {return}
        guard let siteType = Site.siteDic[site] else {return}
        
        let newTarget = BotTarget(site: siteType, loginEmail: email, keywords: kwd, earlyLink: link, autoCheckout: autoCheckout, quantity: 1, size: sizeNum)
        let newTask = BotTask(target: newTarget)
        self.tasks.append(newTask)
        
        self.taskTableView.reloadData()
    }
    
    @IBAction func startSelectedTask(_ sender: NSButton) {
        let index = self.taskTableView.selectedRow
        
        self.tasks[index].run()
    }
    
    @IBAction func startAllTasks(_ sender: NSButton) {
        for task in tasks {
            task.run()
        }
    }
    
    @IBAction func stopSelectedTask(_ sender: NSButton) {
        let index = self.taskTableView.selectedRow
        
        self.tasks[index].stop()
    }
    
    @IBAction func stopAllTasks(_ sender: NSButton) {
        for task in tasks {
            task.stop()
        }
    }
    
    @IBAction func deleteSelectedTask(_ sender: NSButton) {
        let index = self.taskTableView.selectedRow
        
        self.tasks.remove(at: index)
        self.taskTableView.reloadData()
    }
    
    @IBAction func deleteAllTasks(_ sender: NSButton) {
        self.tasks = []
        self.taskTableView.reloadData()
    }
    
    @IBAction func copySelectedTask(_ sender: NSButton) {
        let index = self.taskTableView.selectedRow
        let copiedNewTask = self.tasks[index].copy() as! BotTask
        
        self.tasks.append(copiedNewTask)
        self.taskTableView.reloadData()
    }
    
    var emailData:EmailsData?
    
    var tasks:Array<BotTask> = [] {
        willSet {
            let buttonGroup = [self.startSelectedButton,
                               self.startAllButton,
                               self.stopSelectedButton,
                               self.stopAllButton,
                               self.deleteSelected,
                               self.deleteAllButton,
                               self.copySelecteButton]
            let allGroup = [self.startAllButton,
                            self.stopAllButton,
                            self.deleteAllButton]
            if newValue.count == 0 {
                for button in buttonGroup {
                    button?.isEnabled = false
                }
            }else{
                for button in allGroup {
                    button?.isEnabled = true
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //let newBot = ShopifyBot(target: BotTarget(site: .apbstore, quantity: 1, size: 9))
        //newBot.cop(withProductUrl: "https://www.apbstore.com/collections/new-arrivals/products/aj-13-altitude-414571-042-blk-grn")
        self.emailComboBox.delegate = self
        self.taskTableView.delegate = self
        self.taskTableView.dataSource = self
        
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
    
    private func disableButton(button:NSButton) {
        button.isEnabled = false
    }
    
    private func enableButton(button:NSButton) {
        button.isEnabled = true
    }
}

extension MainViewController:NSComboBoxDelegate {
    func comboBoxWillPopUp(_ notification: Notification) {
        self.loadEmailSelector()
    }
}

extension MainViewController:NSTableViewDelegate, NSTableViewDataSource {
    private enum CellIdentifiers {
        static let siteCell = "siteCellID"
        static let sizeCell = "sizeCellID"
        static let productCell  = "productCellID"
        static let statusCell = "statusCellID"
        static let kwdCell = "kwdCellID"
        static let earlyLinkCell = "earlyLinkCellID"
        static let emailCell = "emailCellID"
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        let taskCount = self.tasks.count
            return taskCount
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var text:String = ""
        var cellIdentity:String = ""
        let item = tasks[row]
        
        if tableColumn == tableView.tableColumns[0] {
            text = item.site
            cellIdentity = CellIdentifiers.siteCell
        }else if tableColumn == tableView.tableColumns[1]  {
            text = String(item.size)
            cellIdentity = CellIdentifiers.sizeCell
        }else if tableColumn == tableView.tableColumns[2] {
            text = item.productName
            cellIdentity = CellIdentifiers.productCell
            
        }else if tableColumn == tableView.tableColumns[3]{
            text = item.bot.keywords
            cellIdentity = CellIdentifiers.kwdCell
        }else if tableColumn == tableView.tableColumns[5] {
            text = item.bot.earlyLink != "" ? "YES" : "NO"
            cellIdentity = CellIdentifiers.earlyLinkCell
        }else if tableColumn == tableView.tableColumns[4] {
            text = item.bot.loginEmail
            cellIdentity = CellIdentifiers.emailCell
        }
        else {
            text = item.status
            cellIdentity = CellIdentifiers.statusCell
        }
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentity), owner: nil) as? NSTableCellView {
            
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let buttonGroup = [self.startSelectedButton,
                           self.stopSelectedButton,
                           self.deleteSelected,
                           self.copySelecteButton]
        if self.taskTableView.selectedRow != -1 {
            for button in buttonGroup {
                button?.isEnabled = true
            }
        }else {
            for button in buttonGroup {
                button?.isEnabled = false
            }
        }
    }
}

