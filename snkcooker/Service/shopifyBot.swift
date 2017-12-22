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
    
    var id:String?
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
    }
    
    public func cop() {
        if self.earlyLink == ""{
            self.cop(withKeywords: [])
        }else {
            self.cop(withProductUrl: self.earlyLink)
        }
    }

    
    public func cancelCop() {
        self.session?.session.getAllTasks() {sessionTask in
            sessionTask.forEach{$0.cancel()}
            
        }
    }
    
    private func cop(withKeywords keywords:Array<String>) {

    }
    
    private func cop(withProductUrl product_url:String) {
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
                    self.delegate?.productDidAddedtoCart()
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
                
                let urlContent = data.html
                let authToken = Parser.parse(checkoutPageby: urlContent)
                
                self.fillShipAddress(auth_token: authToken)
            }
        }
    }
    
    private func fillShipAddress(auth_token:String) {
        if let url = self.redirected_url {
            let postData = self.postDataManager.genShippingData(with: auth_token, ofSite: self.site)
            
            guard let session = self.session else {return}
            session.request(url, method: .post, parameters: postData).response {response in
                
                if response.error == nil, let data = response.data, let httpResponse = response.response ,httpResponse.statusCode == 200 {
                    
                    let urlContent = data.html
                    let values = Parser.parse(shipMethodPage: urlContent)
                    
                    self.selectShipMethod(auth_token: values.0, method: values.1)
                }
            }
        }
    }
    
    private func selectShipMethod(auth_token:String, method:String) {
        if let url = self.redirected_url {
            let postData = self.postDataManager.genShipMethodData(auth_token: auth_token, ship_method: method)
            
            guard let session = self.session else {return}
            session.request(url, method: .post, parameters: postData).response {response in
                if response.error == nil, let data = response.data, let httpResponse = response.response ,httpResponse.statusCode == 200 {
                    let urlContent = data.html
                    let values = Parser.parse(paymentPage: urlContent)
                    
                    self.sendCreditInfo(authToken: values.0, price: values.1, gateway: values.2)
                }
            }
        }
    }
    
    private func sendCreditInfo(authToken:String, price:String, gateway:String) {
            let postData = self.postDataManager.genCreditInfoData()
            let url = "https://elb.deposit.shopifycs.com/sessions"
        
            guard let session = self.session else {return}
            session.request(url, method: .post, parameters: postData, encoding: JSONEncoding.default).responseJSON{response in
                if let json = response.result.value as? [String:Any], let sValue = json["id"] as? String{
                    
                    self.completePayment(authToken: authToken, price: price, gateway: gateway, sValue: sValue)
                }
        }
    }
    
    private func completePayment(authToken:String, price:String, gateway:String, sValue:String) {
        if let url = self.redirected_url {
            let postData = self.postDataManager.genBillingData(with: authToken, sValue: sValue, price: price, payment_gateway: gateway)
            
            guard let session = self.session else {return}
            session.request(url, method: .post, parameters: postData).response {response in
                if response.error == nil, let httpResponse = response.response ,
                    httpResponse.statusCode == 200 {
                    self.delegate?.productDidCheckedout()
                }
                self.session = nil
            }
        }
    }
}

