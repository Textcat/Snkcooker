//
//  WebViewController.swift
//  snkcooker
//
//  Created by 刘业臻 on 2017/12/28.
//  Copyright © 2017年 luiyezheng. All rights reserved.
//

import Cocoa
import WebKit

class WebViewController: NSViewController {

    @IBOutlet var webView: WKWebView!
    
    var url:URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Snkcooker"
        
        guard let url=self.url
            else {
                return
        }
        
        webView.load(URLRequest(url: url))
        // Do view setup here.
    }
}
