//
//  shopifyBot.swift
//  snkcooker
//
//  Created by 刘业臻 on 2017/12/17.
//  Copyright © 2017年 luiyezheng. All rights reserved.
//

import Foundation

class ShopifyBot {
    let base_url:String
    let quantity:Int
    let size:Int
    let autoCheckout:Bool
    
    let session:URLSession
    var product_url:String?
    var redirected_url:URL?
    
    init(target:BotTarget, autoCheckout:Bool=false) {
        self.base_url = target.site
        self.quantity = target.quantity
        self.size = target.size
        self.autoCheckout = autoCheckout
        
        self.session = URLSession()

    }

    
    public func cop(withKeywords keywords:Array<String>) {

    }
    
    
    public func cop(withProductUrl product_url:String) {
        self.product_url = product_url
    }
    
    private func productInfo(product_url:String){
        let request_url = URL(string: "\(product_url).json")
        
        let task = self.session.dataTask(with: request_url!) {(data,response,error) in
            if let data=data {
                do {
                    let object = try JSONSerialization.jsonObject(with: data, options: [])
                    
                    
                    var info = [String:Any]()
                }catch {
                    print(error)
                }
            }
        }
    }
}
