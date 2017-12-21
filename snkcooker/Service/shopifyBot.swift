//
//  shopifyBot.swift
//  snkcooker
//
//  Created by 刘业臻 on 2017/12/17.
//  Copyright © 2017年 luiyezheng. All rights reserved.
//

import Foundation

public class ShopifyBot {
    let base_url:String
    let quantity:Int
    let size:Double
    let autoCheckout:Bool
    let site:Site
    
    let session:URLSession
    var redirected_url:URL?
    
    init(target:BotTarget, autoCheckout:Bool=false) {
        self.site = target.site
        self.base_url = target.site.rawValue
        self.quantity = target.quantity
        self.size = target.size
        self.autoCheckout = autoCheckout
        
        self.session = URLSession(configuration: .ephemeral)
    }

    
    public func cop(withKeywords keywords:Array<String>) {

    }
    
    
    public func cop(withProductUrl product_url:String) {
        let request_url = URL(string: "\(product_url).json")
        
        let task = self.session.dataTask(with: request_url!) {(data,response,error) in
            if let data=data {
                let info = ProductInfo(data: data,
                                       wantSize: self.size,
                                       wantQuantity: self.quantity)
                if info.quantity != 0 {
                    self.addToCart(productInfo: info)
                }
            }
        }
        task.resume()
    }
    
    
    private func addToCart(productInfo:ProductInfo) {
        print("Start adding to cart...")
        let name = productInfo.productName
        let post_data:[String:Any] = ["id":productInfo.storeID, "quantity":productInfo.quantity]
        let post_url = "\(self.base_url)/cart/add.js"
        
        if let url = URL(string:post_url){
            let request = Utility.genUrlencodePostRequest(from: url, with: post_data)
            let task = self.session.dataTask(with: request) {(data,response,error) in
                if error == nil {
                    if let httpResponse = response as? HTTPURLResponse ,httpResponse.statusCode == 200, let fields = httpResponse.allHeaderFields as? [String : String],let url = httpResponse.url{
                        let cookies = HTTPCookie.cookies(withResponseHeaderFields: fields, for: url)

                    }
                }
            }
            task.resume()
        }
    }
}
