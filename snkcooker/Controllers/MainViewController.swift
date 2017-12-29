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
        let quantity = 1
        let emailStr = emailComboBox.stringValue
        let kwdStr = kwdTextField.stringValue
        let linkStr = earlyLinkTextField.stringValue
        let sizeStr = sizeTextField.stringValue
        guard let siteStr = siteSelector.selectedItem?.title else {return}
        
        self.stateReducer(action: .newTask(siteStr: siteStr,
                                           email: emailStr,
                                           kwd: kwdStr,
                                           link: linkStr,
                                           quantity: quantity,
                                           size: sizeStr))
        
    }
    
    @IBAction func startSelectedTask(_ sender: NSButton) {
        let index = taskTableView.selectedRow
        
        tasks[index].run()
    }
    
    @IBAction func startAllTasks(_ sender: NSButton) {
        for task in tasks {
            task.run()
        }
    }
    
    @IBAction func stopSelectedTask(_ sender: NSButton) {
        let index = taskTableView.selectedRow
        
        tasks[index].stop()
    }
    
    @IBAction func stopAllTasks(_ sender: NSButton) {
        for task in tasks {
            task.stop()
        }
    }
    
    @IBAction func deleteSelectedTask(_ sender: NSButton) {
        let index = taskTableView.selectedRow
        
        tasks.remove(at: index)
        stateReducer(action: .deleteTask)

    }
    
    @IBAction func deleteAllTasks(_ sender: NSButton) {
        tasks = []
        stateReducer(action: .deleteTask)

    }
    
    @IBAction func copySelectedTask(_ sender: NSButton) {
        let index = taskTableView.selectedRow
        let copiedNewTask = tasks[index].copy() as! BotTask
        
        tasks.append(copiedNewTask)
        stateReducer(action: .copySelectedTask)

    }
    
    var emailData:EmailsData?
    
    var tasks:Array<BotTask> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailComboBox.delegate = self
        taskTableView.delegate = self
        taskTableView.dataSource = self
        taskTableView.target = self
        taskTableView.doubleAction = #selector(tableViewDoubleClicked(_:))
        
        loadSiteSelector()
    }
    
    private func loadSiteSelector() {
        siteSelector.addItems(withTitles: Site.allSites)
    }
    
    private func loadEmailSelector() {
        emailData = EmailsData()
        if let abbrs = emailData?.abbrs {
            emailComboBox.removeAllItems()
            emailComboBox.addItems(withObjectValues: abbrs)
        }
    }
    
    enum Actions {
        case newTask(siteStr:String,
            email:String,
            kwd:String,
            link:String,
            quantity:Int,
            size:String)
        case selectTask(index:Int)
        case deleteTask
        case copySelectedTask
    }
    
    private func stateReducer(action:Actions) {
        var enabled:Array<NSButton> = []
        var disabled:Array<NSButton> = []
        
        switch action {
        case .newTask(let siteStr,
                      let emailStr,
                      let kwdStr,
                      let linkStr,
                      let quantityInt,
                      let sizeStr):
            var email = ""
            if let mailStr = EmailsData().emailOptions[emailStr] {
                email = mailStr
            }else if emailStr.isValidEmail(){
                email = emailStr
            }else {
                emailComboBox.becomeFirstResponder()
                return
            }
            
            let size = sizeStr
            guard let sizeNum = Double(size) else {return}
            if !size.isValidSize() {
                sizeTextField.becomeFirstResponder()
                return
            }
            
            let kwd = kwdStr
            if !kwd.isValidKeywords() {
                kwdTextField.becomeFirstResponder()
                return
            }
            let link = linkStr
            
            let site = siteStr
            guard let siteType = Site.siteDic[site] else {return}
            
            let newTarget = BotTarget(site: siteType,
                                      loginEmail: email,
                                      keywords: kwd,
                                      earlyLink: link,
                                      quantity: quantityInt,
                                      size: sizeNum)
            let newTask = BotTask(target: newTarget)
            newTask.bot.delegate = self
            tasks.append(newTask)
            
            taskTableView.reloadData()
            
            disabled = [startSelectedButton,
                        stopSelectedButton,
                        deleteSelected,
                        copySelecteButton]
            enabled = [startAllButton,
                       stopAllButton,
                       deleteAllButton]
            
        case .deleteTask, .copySelectedTask:
            disabled = [startSelectedButton,
                        stopSelectedButton,
                        deleteSelected,
                        copySelecteButton]
            enabled = [startAllButton,
                       stopAllButton,
                       deleteAllButton]
            
            taskTableView.reloadData()
            
        case .selectTask(let index):
            if index == -1 {
                disabled = [startSelectedButton,
                            stopSelectedButton,
                            deleteSelected,
                            copySelecteButton]
                enabled = [startAllButton,
                           stopAllButton,
                           deleteAllButton]
                
            }else {
                enabled = [startSelectedButton,
                           startAllButton,
                           stopSelectedButton,
                           stopAllButton,
                           deleteSelected,
                           deleteAllButton,
                           copySelecteButton]
            }
    }
        if self.tasks.count == 0 {
            
            disabled = [startSelectedButton,
                        startAllButton,
                        stopSelectedButton,
                        stopAllButton,
                        deleteSelected,
                        deleteAllButton,
                        copySelecteButton]
            enabled = []
        }
        
        for button in enabled {
            
            button.isEnabled = true
        }
        
        for button in disabled {
            
            button.isEnabled = false
        }
    }
}

extension MainViewController:NSComboBoxDelegate {
    func comboBoxWillPopUp(_ notification: Notification) {
        loadEmailSelector()
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
    
    @objc private func tableViewDoubleClicked(_ sender:AnyObject) {
        let index = taskTableView.clickedRow
        let clickedTask = tasks[index]
        let bot = clickedTask.bot
        let status = clickedTask.status
        if status == "Checked out" {
            guard let url = bot.completeURL
                else {
                    return
            }
            let id = "webViewController"
            
            guard let next = self.nextController(withIdentity: id) as? WebViewController
                else {
                    return
            }
            next.url = url
            self.presentViewControllerAsModalWindow(next)
            
        }else if status == "Waiting for selection" {
            
            let id = "productsSelectionController"
            
            guard let foundProducts = bot.foundProducts,
                  let next = self.nextController(withIdentity: id) as? ProductsSelectionController else {
                return
            }
            
            next.products = foundProducts
            next.bot = bot
            
            self.presentViewControllerAsModalWindow(next)
        }
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        let taskCount = tasks.count
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
            if cellIdentity == CellIdentifiers.statusCell {
                switch text {
                case "Added to cart":
                    cell.textField?.backgroundColor = NSColor.yellow
                case "Checked out":
                    cell.textField?.backgroundColor = NSColor.green
                case "Waiting for restock...":
                    cell.textField?.backgroundColor = NSColor.orange
                default:
                    break
                }
            }
            return cell
        }
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        stateReducer(action: .selectTask(index: taskTableView.selectedRow))
    }
}

extension MainViewController:ShopifyBotDelegate {
    
    func productOutOfStock(id: String) {
        let task = tasks.filter{$0.id == id}[0]
        task.status = "Waiting for restock..."
        taskTableView.reloadData()

    }
    
    func productWillFound(id: String) {
        let task = tasks.filter{$0.id == id}[0]
        task.status = "Searching.."
        taskTableView.reloadData()
    }
    
    func productDidFound(id: String, productName: String) {
        let task = tasks.filter{$0.id == id}[0]
        task.status = "Product found"
        task.productName = productName
        taskTableView.reloadData()
    }
    
    func productDidFoundMorethanOne(id: String) {
        let task = tasks.filter{$0.id == id}[0]
        task.status = "Waiting for selection"
        taskTableView.reloadData()
    }
    
    func productDidAddedtoCart(id: String) {
        let task = tasks.filter{$0.id == id}[0]
        task.status = "Added to cart"
        taskTableView.reloadData()
    }
    
    func productDidCheckedout(id: String,url:URL) {
        let task = tasks.filter{$0.id == id}[0]
        task.status = "Checked out"
        taskTableView.reloadData()
        
    }
}

