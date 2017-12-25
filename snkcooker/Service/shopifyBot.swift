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
    let earlyLink:String
    let loginEmail:String
    let keywords:String
    
    var id:String = ""
    var delegate:ShopifyBotDelegate?
    
    var session:SessionManager?
    var redirected_url:URL?
    
    lazy var postDataManager  = PostData()
    
    init(target:BotTarget) {
        self.site = target.site
        self.quantity = target.quantity
        self.size = target.size
        self.autoCheckout = target.autoCheckout
        self.earlyLink = target.earlyLink
        self.base_url = target.site.rawValue
        self.loginEmail = target.loginEmail
        self.keywords = target.keywords
        
        self.session = SessionManager(configuration:URLSessionConfiguration.ephemeral)
        self.session?.retrier = RetryHandler()
    }
    
    public func cop() {
        if self.earlyLink == ""{
            self.cop(withKeywords:self.keywords)
        }else {
            self.cop(withProductUrl: self.earlyLink)
        }
    }

    
    public func cancelCop() {
        self.session?.session.getAllTasks() {sessionTask in
            sessionTask.forEach{$0.cancel()}
            
        }
    }
    
    private func cop(withKeywords keywords:String) {
        self.delegate?.productWillFound(id: self.id)
        self.searchProduct(ofSite: self.site, byKeywords: keywords)

    }
    
    private func cop(withProductUrl product_url:String) {
        guard let request_url = URL(string: "\(product_url).json") else {return}
        guard let session = self.session else {return}
        
        session.request(request_url).responseData {response in
            if let data=response.data {
                
                let info = ProductInfo(data: data,wantSize: self.size,wantQuantity: self.quantity)
                if info.quantity != 0 {
                    self.addToCart(productInfo: info)
                }
            }
        }
    }
    
    private func addToCart(productInfo:ProductInfo) {
        let post_url = "\(self.base_url)/cart/add.js"
        guard let session = self.session else {return}
        let post_data:[String:Any] = ["id":productInfo.storeID,
                                      "quantity":productInfo.quantity]
        
        if let url = URL(string:post_url){
            session.request(url, method: .post, parameters: post_data).response {response in
                if response.response?.statusCode == 200 {
                    
                    self.delegate?.productDidAddedtoCart(id: self.id)
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
            
            if response.error == nil,
                let data = response.data,
                let httpResponse = response.response ,
                httpResponse.statusCode == 200 {
                
                let urlContent = data.html
                let authToken = Parser.parse(checkoutPageby: urlContent)
                self.redirected_url = httpResponse.url
                self.fillShipAddress(auth_token: authToken)
            }
        }
    }
    
    private func fillShipAddress(auth_token:String) {
        guard let url = self.redirected_url else {return}
        guard let session = self.session else {return}
        var postData = self.postDataManager.genShippingData(with: auth_token,
                                                            ofSite: self.site)
        postData["checkout[email]"] = self.loginEmail
    
        session.request(url, method: .post, parameters: postData).response {response in
            
            if response.error == nil,
                let data = response.data,
                let httpResponse = response.response ,
                httpResponse.statusCode == 200{
                
                let urlContent = data.html
                let values = Parser.parse(shipMethodPage: urlContent)
                self.selectShipMethod(auth_token: values.0, method: values.1)
            }
        }
    }
    
    private func selectShipMethod(auth_token:String, method:String) {
        guard let url = self.redirected_url else {return}
        guard let session = self.session else {return}
        let postData = self.postDataManager.genShipMethodData(auth_token: auth_token,
                                                              ship_method: method)
    
        session.request(url, method: .post, parameters: postData).response {response in
            if response.error == nil,
                let data = response.data,
                let httpResponse = response.response ,
                httpResponse.statusCode == 200{
                
                let urlContent = data.html
                let values = Parser.parse(paymentPage: urlContent)
                self.sendCreditInfo(authToken: values.0,
                                    price: values.1,
                                    gateway: values.2)
            }
        }
    }
    
    private func sendCreditInfo(authToken:String, price:String, gateway:String) {
        let url = "https://elb.deposit.shopifycs.com/sessions"
        let postData = self.postDataManager.genCreditInfoData()
        guard let session = self.session else {return}
    
        session.request(url, method: .post,parameters: postData,encoding: JSONEncoding.default).responseJSON{response in
            if let json = response.result.value as? [String:Any],
                let sValue = json["id"] as? String{
                
                self.completePayment(authToken: authToken,
                                     price: price,
                                     gateway: gateway,
                                     sValue: sValue)
            }
        }
    }
    
    private func completePayment(authToken:String, price:String, gateway:String, sValue:String) {
        guard let url = self.redirected_url else {return}
        guard let session = self.session else {return}
        let postData = self.postDataManager.genBillingData(with: authToken,
                                                           sValue: sValue,
                                                           price: price,
                                                           payment_gateway: gateway)
        
        session.request(url, method: .post, parameters: postData).response {response in
            if response.error == nil,
                let httpResponse = response.response ,
                httpResponse.statusCode == 200 {
                
                self.delegate?.productDidCheckedout(id: self.id)
            }
            self.session = nil
        }
    }
}

typealias Keywords = (Array<String>,Array<String>)

extension ShopifyBot {
    private func searchProduct(ofSite site:Site, byKeywords keywords:String){
        var foundProduct:[String:String] = [:]
        let siteMapUrl = "\(site.rawValue)/sitemap_products_1.xml"
        
        Alamofire.request(siteMapUrl).responseString {response in
            if response.error == nil,
                let httpResponse = response.response,
                httpResponse.statusCode == 200,
                let content = response.result.value
            {
                
                foundProduct = Parser.parse(siteMap: content, keywords: keywords)
                if foundProduct.count == 0 {
                    DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
                        self.searchProduct(ofSite: site, byKeywords: keywords)
                    }
                }else if foundProduct.count > 1 {
                    
                }else if foundProduct.count == 1,
                    let urlStr = foundProduct.values.first,
                    let name = foundProduct.keys.first
                {
                    self.delegate?.productDidFound(id: self.id, productName: name)
                    self.cop(withProductUrl: urlStr)
                }
            }
        }
    }
}

private class RetryHandler:RequestRetrier {
    public func should(_ manager: SessionManager,
                       retry request: Request,
                       with error: Error,
                       completion: @escaping RequestRetryCompletion)
    {
        if let task = request.task,
            let response = task.response as? HTTPURLResponse,
            response.statusCode != 400,
            response.statusCode != 404
        {
            completion(true, 1.0) // retry after 1 second
        } else {
            completion(false, 0.0) // don't retry
        }
    }
}
