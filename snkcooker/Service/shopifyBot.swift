//
//  shopifyBot.swift
//  snkcooker
//
//  Created by 刘业臻 on 2017/12/17.
//  Copyright © 2017年 luiyezheng. All rights reserved.
//

import Foundation
import Alamofire

public class ShopifyBot {
    let base_url:String
    let quantity:Int
    let size:Double
    let autoCheckout:Bool
    let site:Site
    
    var session:SessionManager?
    var redirected_url:URL?
    
    lazy var postDataManager  = PostData()
    
    init(target:BotTarget, autoCheckout:Bool=false) {
        self.site = target.site
        self.quantity = target.quantity
        self.size = target.size
        self.autoCheckout = autoCheckout
        
        self.base_url = target.site.rawValue
        self.session = SessionManager(configuration:URLSessionConfiguration.ephemeral)
    }

    
    public func cop(withKeywords keywords:Array<String>) {

    }
    
    
    public func cop(withProductUrl product_url:String) {
        guard let request_url = URL(string: "\(product_url).json") else {return}
        guard let session = self.session else {return}
        session.request(request_url).responseData {response in
            if let data=response.data {
                let info = ProductInfo(data: data,
                                       wantSize: self.size,
                                       wantQuantity: self.quantity)
                if info.quantity != 0 {
                    self.addToCart(productInfo: info)
                }
            }
        }
    }
    
    private func addToCart(productInfo:ProductInfo) {
        print("Start adding to cart...")
        let post_data:[String:Any] = ["id":productInfo.storeID, "quantity":productInfo.quantity]
        let post_url = "\(self.base_url)/cart/add.js"
        
        if let url = URL(string:post_url){
            guard let session = self.session else {return}
            session.request(url, method: .post, parameters: post_data).response {response in
                if response.response?.statusCode == 200 {
                    self.toCheckout()
                }
            }
        }
    }
    
    private func toCheckout() {
        let checkOutUrl = "\(self.base_url)/checkout"
        guard let url = URL(string: checkOutUrl) else {return}
        
        guard let session = self.session else {return}
        session.request(url).response {response in
            if response.error == nil, let data = response.data, let httpResponse = response.response ,httpResponse.statusCode == 200 {
                
                self.redirected_url = httpResponse.url
                
                let urlContent = String(describing: NSString(data: data, encoding: String.Encoding.utf8.rawValue))
                let authToken = Parser.parse(checkoutPageby: urlContent)
                
                self.fillShipAddress(auth_token: authToken)
            }
        }
    }
    
    private func fillShipAddress(auth_token:String) {
        if let url = self.redirected_url {
            let postData = self.postDataManager.genShippingData(with: auth_token, ofSite: .apbstore)
            
            guard let session = self.session else {return}
            session.request(url, method: .post, parameters: postData).response {response in
                
                if response.error == nil, let data = response.data, let httpResponse = response.response ,httpResponse.statusCode == 200 {
                    let urlContent = String(describing: NSString(data: data, encoding: String.Encoding.utf8.rawValue))
                    print(urlContent)
                    
                }
                self.session = nil
            }
        }
    }
}

