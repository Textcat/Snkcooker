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
    var product_url:String?
    var redirected_url:URL?
    
    init(target:BotTarget, autoCheckout:Bool=false) {
        self.site = target.site
        self.base_url = target.site.rawValue
        self.quantity = target.quantity
        self.size = target.size
        self.autoCheckout = autoCheckout
        
        self.session = URLSession(configuration: .default)

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
                    guard let json = object as? [String:Any] else {return}
                    var info = [String:Any]()
                    guard let product = json["product"] as? [String:Any] else {return}
                    let name = product["title"]
                    info["product_name"] = name
                    guard let variants : Array<Any> = product["variants"] as? Array<Any> else {return}
                    for variant in variants {
                        guard let variant = variant as? Dictionary<String, Any> else{return}
                        guard let size = variant["option1"] as? String else{return}
                        if self.size == Double(size){
                            info["storeID"] = variant["id"]
                            if let quantity = variant["inventory_quantity"] as? Int {
                                if quantity == 0 {
                                }
                                if quantity >= self.quantity {
                                    info["quantity"] = self.quantity
                                }else {
                                    info["quantity"] = quantity
                                }
                            }else {
                                info["quantity"] = 1
                            }
                        }
                    }
                    print(info)
                }catch {
                    print(error)
                }
            }
        }
        task.resume()
    }
}
