//
//  ProductsSelectionController.swift
//  snkcooker
//
//  Created by luiyezheng on 2017/12/29.
//  Copyright © 2017年 luiyezheng. All rights reserved.
//

import Cocoa

class ProductsSelectionController: NSViewController {
    
    @IBOutlet var tableView: NSTableView!
    
    @IBOutlet var confirmButton: NSButton!
    
    @IBAction func confirm(_ sender: NSButton) {
        let index = tableView.selectedRow
        if index == -1 {
            return
        }else {
            guard let bot = bot,
                  let productNames = productNames,
                  let products = products else {
                return
            }
            let name = productNames[index]
            guard let productURL = products[name] else {
                return
            }
            
            bot.cop(withProductUrl: productURL)
            self.view.window?.close()
        }
    }
    
    var bot:ShopifyBot?
    
    var products:[String:String]?
    
    var productNames:Array<String>? {
        guard let keys = products?.keys else {
            return nil
        }
        return Array(keys)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
        
        tableView.delegate = self
        tableView.dataSource = self
        // Do view setup here.
    }
    
}

extension ProductsSelectionController:NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        guard let products = products else {
            return 0
        }
        return products.count
    }
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let productNames = productNames else {
            return nil
        }
        
        let cellIdenity = "productNameID"
        let name = productNames[row]
        
        let identifier = NSUserInterfaceItemIdentifier(rawValue: cellIdenity)
        if let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = name
            
            return cell
        }
        return nil
    }
}
