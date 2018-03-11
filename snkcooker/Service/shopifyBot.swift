//
//  shopifyBot.swift
//  snkcooker
//
//  Created by luiyezheng on 2017/12/17.
//  Copyright © 2017年 luiyezheng. All rights reserved.
//

import Foundation
import Alamofire

public class ShopifyBot {
    let baseURLStr:String
    let quantity:Int
    let size:Double
    let site:Site
    let earlyLink:String
    let loginEmail:String
    let keywords:String
    
    var id:String = ""
    var delegate:ShopifyBotDelegate?
    
    var session:SessionManager?
    var redirectURL:URL?
    var completeURL:URL?
    var foundProducts:[String:String]?
    
    lazy var postDataManager = PostDataManager()
    
    init(target:BotTarget) {
        site = target.site
        quantity = target.quantity
        size = target.size
        earlyLink = target.earlyLink
        baseURLStr = target.site.rawValue
        loginEmail = target.loginEmail
        keywords = target.keywords
        
        session = SessionManager(configuration:.ephemeral)
        session?.retrier = RetryHandler()
    }
    
    public func cop() {
        if earlyLink == ""{
            cop(withKeywords: keywords)
        }else {
            cop(withProductUrl: earlyLink)
        }
    }
    
    
    public func cancelCop() {
        session?.session.getAllTasks() {sessionTask in
            sessionTask.forEach{$0.cancel()}
            
        }
    }
    
    public func cop(withKeywords keywords:String) {
        delegate?.productWillFound(id: id)
        searchProduct(ofSite: site, byKeywords: keywords)
        
    }
    
    public func cop(withProductUrl product_url:String) {
        let step:Step = .StartCop(productURL: product_url)
        guard let values = requestPrepare(step:step) else {return}
        
        let url = values.0
        let session = values.1
        
        session.request(url).responseData {response in
            if let data=response.data {
                
                let info = ProductInfo(data: data,
                                       wantSize: self.size,
                                       wantQuantity: self.quantity)
                if info.quantity != 0 {
                    self.addToCart(productInfo: info)
                }else {
                    self.delegate?.productOutOfStock(id: self.id)
                }
            }
        }
    }
    
    fileprivate func addToCart(productInfo:ProductInfo) {
        let step:Step = .AddtoCart(productInfo: productInfo)
        guard let values = requestPrepare(step:step) else {return}
        let url = values.0
        let session = values.1
        let postData = values.2
        
        session.request(url,method: .post,parameters: postData).response {response in
            if response.response?.statusCode == 200 {
                
                self.delegate?.productDidAddedtoCart(id: self.id)
                self.toCheckout()
            }
        }
    }
    
    fileprivate func toCheckout() {
        let step:Step = .StartCheckout
        guard let values = requestPrepare(step: step) else {return}
        let url = values.0
        let session = values.1
        
        session.request(url).response {response in
            if response.error == nil,
                let data = response.data,
                let httpResponse = response.response ,
                httpResponse.statusCode == 200 {
                
                self.toCheckoutHandler(data: data, response:httpResponse)
            }
        }
    }
    
    fileprivate func toCheckoutHandler(data:Data, response:HTTPURLResponse) {
        redirectURL = response.url
        if let url = redirectURL,
            url.absoluteString.contains("stock_problems") {
            delegate?.productOutOfStock(id: id)
        }
        
        let urlContent = data.html
        let authToken = Parser.parse(checkoutPageby: urlContent)
        
        fillShipAddress(auth_token: authToken,captchaSolution: "")
        
    }
    
    fileprivate func fillShipAddress(auth_token:String, captchaSolution:String) {
        let step:Step = .FillShipAddress(authToken: auth_token, captchaSolution: captchaSolution)
        guard let values = requestPrepare(step: step) else {return}
        let url = values.0
        let session = values.1
        let postData = values.2
        
        session.request(url,method: .post,parameters: postData).response {response in
            if response.error == nil,
                let data = response.data,
                let httpResponse = response.response ,
                httpResponse.statusCode == 200{
                
                self.fillShipAddressHandler(data: data)
            }
        }
    }
    
    fileprivate func fillShipAddressHandler(data:Data) {
        let urlContent = data.html
        let values = Parser.parse(shipMethodPage: urlContent)
        
        self.selectShipMethod(auth_token: values.0, method: values.1)
        
    }
    
    fileprivate func selectShipMethod(auth_token:String, method:String) {
        let step:Step = .SelectShipMethod(authToken: auth_token, method: method)
        guard let values = requestPrepare(step: step) else {return}
        let url = values.0
        let session = values.1
        let postData = values.2
        
        session.request(url,method: .post,parameters: postData).response {response in
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
    
    fileprivate func sendCreditInfo(authToken:String, price:String, gateway:String) {
        let step:Step = .SendCreditCard
        guard let values = requestPrepare(step:step) else {return}
        let url = values.0
        let session = values.1
        let postData = values.2
        
        session.request(url,method: .post,parameters: postData,encoding: JSONEncoding.default).responseJSON{response in
            if let json = response.result.value as? [String:Any],
                let sValue = json["id"] as? String{
                
                self.completePayment(authToken: authToken,
                                     price: price,
                                     gateway: gateway,
                                     sValue: sValue)
            }
        }
    }
    
    fileprivate func completePayment(authToken:String, price:String, gateway:String, sValue:String) {
        let step:Step = .Complete(authToken: authToken,price: price,gateway: gateway,sValue: sValue)
        guard let values = requestPrepare(step:step) else {return}
        let url = values.0
        let session = values.1
        let postData = values.2
        
        session.request(url,method: .post,parameters: postData).response {response in
            if response.error == nil,
                let httpResponse = response.response,
                let url = httpResponse.url,
                httpResponse.statusCode == 200 {
                self.completeURL = url
                self.delegate?.productDidCheckedout(id: self.id,url: url)
            }
            self.session = nil
        }
    }
    
    fileprivate enum Step {
        case StartCop(productURL:String)
        case AddtoCart(productInfo:ProductInfo)
        case StartCheckout
        case FillShipAddress(authToken:String,captchaSolution:String)
        case SelectShipMethod(authToken:String,method:String)
        case SendCreditCard
        case Complete(authToken:String, price:String, gateway:String, sValue:String)
    }
    
    fileprivate func requestPrepare(step:Step) -> (url:URL,session:SessionManager,postData:[String:Any])? {
        guard let session = self.session
            else {
                return nil
        }
        
        switch step {
        case .StartCop(let productURL):
            let string = "\(productURL).json"
            guard let url = URL(string: string)
                else{
                return nil
            }
            return (url, session, [:])
            
        case .AddtoCart(let productInfo):
            let string = "\(baseURLStr)/cart/add.js"
            guard let url = URL(string:string)
                else {
                    return nil
            }
            let postData:[String:Any] = ["id":productInfo.storeID,
                                         "quantity":productInfo.quantity]
            return (url, session, postData)
            
        case .StartCheckout:
            let string = "\(baseURLStr)/checkout"
            guard let url = URL(string:string)
                else {
                    return nil
                    
            }
            return (url, session, [:])
            
        case .FillShipAddress(let authToken,let captchaSolution):
            guard let url = redirectURL else {
                return nil
            }
            let postData = postDataManager.data(ofShipping: authToken,
                                                ofSite: site,
                                                email:loginEmail,
                                                captchaSolution:captchaSolution)
            
            return (url,session,postData)
            
        case .SelectShipMethod(let authToken, let method):
            guard let url = redirectURL else {
                return nil
            }
            let postData = postDataManager.data(ofMethod:authToken,
                                                ship_method: method)
            
            return (url, session, postData)
            
        case .SendCreditCard:
            let string = "https://elb.deposit.shopifycs.com/sessions"
            guard let url = URL(string:string)
                else {
                    return nil
                    
            }
            let postData = postDataManager.genCreditInfoData()
            
            return (url, session, postData)
            
        case .Complete(let authToken,let price, let gateway, let sValue):
            guard let url = redirectURL else {
                return nil
            }
            let postData = postDataManager.data(ofBill: authToken,
                                                sValue: sValue,price: price,
                                                payment_gateway: gateway)
            
            return (url,session,postData)
        }
    }
}


extension ShopifyBot {
    fileprivate func searchProduct(ofSite site:Site, byKeywords keywords:String){
        var foundProduct:[String:String] = [:]
        let siteMapUrl = "\(site.rawValue)/sitemap_products_1.xml"
        
        Alamofire.request(siteMapUrl).responseString {response in
            if response.error == nil,
                let httpResponse = response.response,
                httpResponse.statusCode == 200,
                let content = response.result.value{
                
                foundProduct = Parser.parse(siteMap: content, keywords: keywords)
                
                if foundProduct.count == 0 {
                    
                    self.delegate?.productNotFoundYet(id: self.id)
                    DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
                        self.searchProduct(ofSite: site, byKeywords: keywords)
                    }
                }else if foundProduct.count > 1 {
                    
                    self.foundProducts = foundProduct
                    self.delegate?.productDidFoundMorethanOne(id: self.id)
                    
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


public class CaptchaRequestShopifyBot:ShopifyBot {
    
    override fileprivate func toCheckoutHandler(data: Data, response: HTTPURLResponse) {
        let urlContent = data.html
        let authToken = Parser.parse(checkoutPageby: urlContent)
        redirectURL = response.url
        
        if let url = redirectURL,
            url.absoluteString.contains("stock_problems") {
            
            delegate?.productOutOfStock(id: id)
        }
        
        solveCaptcha(authToken: authToken)
    }
    
    fileprivate func solveCaptcha(authToken:String) {
        guard let urlStr = self.redirectURL?.absoluteString else {return}
        let solver = CapSolver(pUrl: urlStr)
        
        solver?.startSolve() {solution in
            self.fillShipAddress(auth_token: authToken,captchaSolution: solution)
            
        }
    }
}


public class FlatRateShopifyBot:ShopifyBot {
    
    override fileprivate func fillShipAddressHandler(data:Data) {
        self.fetchShippingRate()
    }
    
    fileprivate func fetchShippingRate() {
        guard let session = session
            else {
                return
        }
        guard let redirectURL = redirectURL
            else {
                return
        }
        
        let rateURLStr = "\(redirectURL.absoluteString)/shipping_rates?step=shipping_method"
        
        session.request(rateURLStr).response {response in
            if response.error == nil,
                let data = response.data,
                let httpResponse = response.response{
                if httpResponse.statusCode == 202 {
                    
                    self.fetchShippingRate()
                    
                }else if httpResponse.statusCode == 200 {
                    let urlContent = data.html
                    let values = Parser.parse(shipMethodPage: urlContent)
                    self.selectShipMethod(auth_token: values.0, method: values.1)
                }
            }
        }
    }
}
