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
    
    lazy var postDataManager  = PostData()
    
    init(target:BotTarget, autoCheckout:Bool=false) {
        self.site = target.site
        self.quantity = target.quantity
        self.size = target.size
        self.autoCheckout = autoCheckout
        
        self.base_url = target.site.rawValue
        self.session = URLSession(configuration: .default)
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
        let post_data:[String:Any] = ["id":productInfo.storeID, "quantity":productInfo.quantity]
        let post_url = "\(self.base_url)/cart/add.js"
        
        if let url = URL(string:post_url){
            let request = Utility.genUrlencodePostRequest(from: url, with: post_data)
            let task = self.session.dataTask(with: request) {(data,response,error) in
                if error == nil {
                    if let httpResponse = response as? HTTPURLResponse ,httpResponse.statusCode == 200{
                        self.toCheckout()
                    }
                }
            }
            task.resume()
        }
    }
    
    private func toCheckout() {
        let checkOutUrl = "\(self.base_url)/checkout"
        guard let url = URL(string: checkOutUrl) else {return}
        
        let task = self.session.dataTask(with: url) {(data, response, error) in
            
            if error == nil, let data = data, let httpResponse = response as? HTTPURLResponse ,httpResponse.statusCode == 200 {
                
                self.redirected_url = httpResponse.url
                
                let urlContent = String(describing: NSString(data: data, encoding: String.Encoding.utf8.rawValue))
                let authToken = Parser.parse(checkoutPageby: urlContent)
                print(authToken)
                print("   ")
                
                self.fillShipAddress(auth_token: authToken)
            }
            
        }
        task.resume()
    }
    
    private func fillShipAddress(auth_token:String) {
        if let url = self.redirected_url {
            let postData = self.postDataManager.genShippingData(with: auth_token, ofSite: .apbstore)
            
            let request = Utility.genUrlencodePostRequest(from: url, with: postData)
            
            let task = self.session.dataTask(with: request) {(data, response, error) in
                if error == nil, let data = data, let httpResponse = response as? HTTPURLResponse ,httpResponse.statusCode == 200 {
                    let urlContent = String(describing: NSString(data: data, encoding: String.Encoding.utf8.rawValue))
                    print(urlContent)
                }
            }
            task.resume()
        }
        
    }
}
