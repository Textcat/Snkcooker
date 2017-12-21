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
    
    private func productInfo(ofProductUrl product_url:String){
        let request_url = URL(string: "\(product_url).json")
        
        let task = self.session.dataTask(with: request_url!) {(data,response,error) in
            if let data=data {
                let info = ProductInfo(data: data,
                                       wantSize: self.size,
                                       wantQuantity: self.quantity)
            }
        }
        task.resume()
    }
    
    private func genShippingData(with auth_token:String, ofSite:Site) -> [String:Any] {
        var data_to_post = [String:Any]()
        data_to_post["utf8"] = "✓"
        data_to_post["_method"] = "patch"
        data_to_post["authenticity_token"] = auth_token
        data_to_post["previous_step"] = "contact_information"
        data_to_post["step"] = "shipping_method"
        data_to_post["checkout[email]"] = "luiyezheng123@gmail.com"
        data_to_post["checkout[shipping_address][first_name]"] = "Zhen"
        data_to_post["checkout[shipping_address][last_name]"] = "Yu"
        data_to_post["checkout[shipping_address][company]"] = ""
        data_to_post["checkout[shipping_address][address1]"] = "828 Jazz CT"
        data_to_post["checkout[shipping_address][address2]"] = "18551629136"
        data_to_post["checkout[shipping_address][city]"] = "San Jose"
        data_to_post["checkout[shipping_address][country]"] = "United States"
        data_to_post["checkout[shipping_address][province]"] = "California"
        data_to_post["checkout[shipping_address][zip]"] = "95134"
        data_to_post["checkout[shipping_address][phone]"] = "(408) 513-6565"
        data_to_post["button"] = ""
        data_to_post["checkout[client_details][browser_width]"] = "1170"
        data_to_post["checkout[client_details][browser_height]"] = "711"
        data_to_post["checkout[client_details][javascript_enabled]"] = "1"
        
        var add_data = [String:Any]()
        switch ofSite {
        case .bowsandarrows:
            add_data = ["checkout[buyer_accepts_marketing]":"0",
                        "checkout[remember_me]":["0":"false","1":"0"]]
        case .rockcitykicks:
            add_data = ["checkout[buyer_accepts_marketing]":["0","1"]]
        case .exclucitylife:
            add_data = ["checkout[remember_me]":["0","false"],
                        "checkout[buyer_accepts_marketing]":"0"]
        case .notre:
            add_data = ["checkout[buyer_accepts_marketing]":"0"]
        default:
            add_data = [:]
        }
        
        data_to_post += add_data
        return data_to_post
    }
    
    
    private func genBillingData(with auth_token:String, sValue:String, price:String, payment_gateway:String) -> [String:Any]{
        var data_to_post = [String:Any]()
        data_to_post["utf8"] = "✓"
        data_to_post["_method"] = "patch"
        data_to_post["authenticity_token"] = auth_token
        data_to_post["previous_step"] = "payment_method"
        data_to_post["step"] = ""
        data_to_post["s"] = sValue
        data_to_post["checkout[payment_gateway]"] = payment_gateway
        data_to_post["checkout[credit_card][vault]"] = "false"
        data_to_post["checkout[different_billing_address]"] = "true"
        data_to_post["checkout[billing_address][first_name]"] = ["Zhen",""]
        data_to_post["checkout[billing_address][last_name]"] = ["Yu",""]
        data_to_post["checkout[billing_address][company]"] = ["",""]
        data_to_post["checkout[billing_address][address1]"] = ["828 Jazz CT",""]
        data_to_post["checkout[billing_address][address2]"] = ["18551629136",""]
        data_to_post["checkout[billing_address][city]"] = ["San Jose",""]
        data_to_post["checkout[billing_address][country]"] = ["United States",""]
        data_to_post["checkout[billing_address][province]"] = ["California",""]
        data_to_post["checkout[billing_address][zip]"] = ["95134",""]
        data_to_post["checkout[billing_address][phone]"] = ["(408) 513-6565",""]
        data_to_post["checkout[remember_me]"] = ["false","0"]
        data_to_post["checkout[vault_phone]"] = ""
        data_to_post["checkout[total_price]"] = price
        data_to_post["complete"] = "1"
        data_to_post["checkout[client_details][browser_width]"] = "1170"
        data_to_post["checkout[client_details][browser_height]"] = "711"
        data_to_post["checkout[client_details][javascript_enabled]"] = "1"
        
        return data_to_post
    }
    
    
    private func genShipMethodData(auth_token:String, ship_method:String) -> [String:Any] {
        var data_to_post = [String:Any]()
        
        data_to_post["utf8"] = "✓"
        data_to_post["_method"] = "patch"
        data_to_post["authenticity_token"] = auth_token
        data_to_post["previous_step"] = "shipping_method"
        data_to_post["step"] = "payment_method"
        data_to_post["checkout[shipping_rate][id]"] = ship_method
        data_to_post["button"] = ""
        data_to_post["checkout[client_details][browser_width]"] = "1170"
        data_to_post["checkout[client_details][browser_height]"] = "711"
        data_to_post["checkout[client_details][javascript_enabled]"] = "1"
        
        return data_to_post
    }
    
    
    private func genCreditInfoData() -> [String:Any]{
        var credit_info = [String:Any]()
        var data_to_post = [String:Any]()
        
        credit_info["number"] = ""
        credit_info["name"] = ""
        credit_info["month"] = ""
        credit_info["year"] = ""
        credit_info["verification_value"] = ""
        
        data_to_post["credit_card"] = credit_info
        
        return data_to_post
    }
}
