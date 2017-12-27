//
//  models.swift
//  snkcooker
//
//  Created by 刘业臻 on 2017/12/17.
//  Copyright © 2017年 luiyezheng. All rights reserved.
//

import Foundation
import Kanna

struct BotTarget {
    let site:Site
    let loginEmail:String
    let keywords:String
    let earlyLink:String
    let autoCheckout:Bool
    var quantity:Int
    var size:Double
}





class BotTask:NSCopying {
    public let site:String
    public let size:Double
    public let id:String
    public let bot:ShopifyBot
    private let target:BotTarget
    
    public var productName:String = ""
    public var status = "Ready"
    
    init(target:BotTarget) {
        
        switch target.site {
        case .rockcitykicks,
             .exclucitylife:
            bot = CaptchaRequestShopifyBot(target: target)
        case .bowsandarrows, 
             .shoegallerymiami:
            bot = FlatRateShopifyBot(target: target)
        default:
            bot = ShopifyBot(target: target)
        }
        
        id = UUID().uuidString
        bot.id = id
        site = String(describing: target.site)
        size = target.size
        self.target = target
    }
    
    public func run() {
        bot.cop()
    }
    
    public func stop() {
        bot.cancelCop()
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let botTask = BotTask(target: target)
        
        return botTask
    }
}






struct Parser {
    internal static func parse(checkoutPageby content:String) -> String {
        let authPath = "//form[@class='edit_checkout']/input[@name='authenticity_token']/@value"
        do {
            let doc = try HTML(html: content, encoding: .utf8)
            let authObject = doc.xpath(authPath)[0]
            if let authToken = authObject.content {
                return authToken
            }else {
                return ""
            }
        }catch {
            return ""
        }
    }
    
    internal static func parse(shipMethodPage content:String) -> (String,String) {
        let authPath = "//form[@data-shipping-method-form='true']/input[@name='authenticity_token']/@value"
        let methodPath = "//div[@class='radio-wrapper']/@data-shipping-method"
        do {
            let doc = try HTML(html: content, encoding: .utf8)
            let authToken = doc.xpath(authPath)[0].content ?? ""
            let method = doc.xpath(methodPath).filter({$0.content?.lowercased().contains("pick") == false})[0].content ?? ""
            
            return (authToken,method)
        }catch {
            return ("","")
        }
    }
    
    internal static func parse(paymentPage content:String) -> (String,String,String) {
        enum Path:String {
            case auth = "//form[@data-payment-form='']/input[@name='authenticity_token']/@value"
            case price = "//input[@id='checkout_total_price']/@value"
            case gateway = "//input[@name='checkout[payment_gateway]']"
        }
        
        do {
            let doc = try HTML(html: content, encoding: .utf8)
            let authToken = doc.xpath(Path.auth.rawValue)[0].content ?? ""
            let gateway = doc.xpath(Path.gateway.rawValue)[0].xpath("./@value")[0].content ?? ""
            
            if let priceString = doc.xpath(Path.price.rawValue)[0].content {
                return (authToken, priceString, gateway)
                
            }else {
                return ("","","")
            }
        }catch {
            return ("","","")
        }
    }
    
    internal static func parse(siteMap content:String, keywords:String) -> [String:String] {
        enum Path:String {
            case products = "//d:url"
            case name = ".//image:title/text()"
            case url = "./d:loc/text()"
        }

        let keywords = keywords.keywords()
        let positiveKwd = keywords.0.map{$0.lowercased()}
        let negativeKwd = keywords.1.map{$0.lowercased()}
        
        var foundProducts:[String:String] = [:]
        let namespaces = ["d":"http://www.sitemaps.org/schemas/sitemap/0.9",
                          "image":"http://www.google.com/schemas/sitemap-image/1.1"]
        
        do {
            let root = try Kanna.XML(xml:content, encoding: .utf8)
            
            let products = root.xpath(Path.products.rawValue,
                                      namespaces: namespaces).dropFirst()
            
            
            for product in products {
                let nodeSet = product.xpath(Path.name.rawValue,namespaces: namespaces)
                if nodeSet.count == 0 {
                    continue
                }else {
                    let productName = nodeSet[0].content
                    if let name = productName,
                        (positiveKwd.filter{name.lowercased().contains($0)}.count == positiveKwd.count),
                        (negativeKwd.filter {name.lowercased().contains($0)} == []){
                        
                        foundProducts[name] = product.xpath(Path.url.rawValue,
                                                            namespaces: namespaces)[0].content
                    }
                }
            }
            return foundProducts
        }catch {
            return [:]
        }
    }
}







struct PostDataManager {
    var userShipConfig:[String:Any] = [:]
    var userbillConfig:[String:Any] = [:]
    var userCreditConfig:[String:Any] = [:]
    
    init() {
        if let userconfig = PlistDicManager.allPlistObject() {
            self.userShipConfig = (userconfig.object(forKey: "ShippingAddress") as? [String : Any])!
            self.userbillConfig = (userconfig.object(forKey: "BillingAddress") as? [String : Any])!
            self.userCreditConfig = (userconfig.object(forKey: "PaymentCardInfo") as? [String : Any])!

            }
        }
    
    internal func data(ofShipping auth_token:String, ofSite:Site, email:String, captchaSolution:String) -> [String:Any] {
        var data_to_post = [String:Any]()
        data_to_post["utf8"] = "✓"
        data_to_post["_method"] = "patch"
        data_to_post["authenticity_token"] = auth_token
        data_to_post["previous_step"] = "contact_information"
        data_to_post["step"] = "shipping_method"
        data_to_post["checkout[email]"] = email
        data_to_post["checkout[shipping_address][first_name]"] = self.userShipConfig["firstName"]
        data_to_post["checkout[shipping_address][last_name]"] = self.userShipConfig["lastName"]
        data_to_post["checkout[shipping_address][company]"] = ""
        data_to_post["checkout[shipping_address][address1]"] = self.userShipConfig["address1"]
        data_to_post["checkout[shipping_address][address2]"] = self.userShipConfig["address2"]
        data_to_post["checkout[shipping_address][city]"] = self.userShipConfig["city"]
        data_to_post["checkout[shipping_address][country]"] = self.userShipConfig["country"]
        data_to_post["checkout[shipping_address][province]"] = self.userShipConfig["province"]
        data_to_post["checkout[shipping_address][zip]"] = self.userShipConfig["zip"]
        data_to_post["checkout[shipping_address][phone]"] = self.userShipConfig["phone"]
        data_to_post["button"] = ""
        data_to_post["checkout[client_details][browser_width]"] = "1170"
        data_to_post["checkout[client_details][browser_height]"] = "711"
        data_to_post["checkout[client_details][javascript_enabled]"] = "1"
        if captchaSolution != "" {
            data_to_post["g-recaptcha-response"] = captchaSolution
        }
        
        var add_data = [String:Any]()
        switch ofSite {
        case .bowsandarrows:
            add_data = ["checkout[buyer_accepts_marketing]":"1",
                        "checkout[remember_me]":"0"]
        case .rockcitykicks:
            add_data = ["checkout[buyer_accepts_marketing]":"1"]
        case .exclucitylife:
            add_data = ["checkout[remember_me]":"false",
                        "checkout[buyer_accepts_marketing]":"1"]
        case .notre,.apbstore:
            add_data = ["checkout[buyer_accepts_marketing]":"0"]
        default:
            add_data = [:]
        }
        
        data_to_post += add_data
        return data_to_post
    }
    
    
    internal func data(ofBill auth_token:String, sValue:String, price:String, payment_gateway:String) -> [String:Any]{
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
        data_to_post["checkout[billing_address][first_name]"] = self.userbillConfig["firstName"]
        data_to_post["checkout[billing_address][last_name]"] = self.userbillConfig["lastName"]
        data_to_post["checkout[billing_address][company]"] = ""
        data_to_post["checkout[billing_address][address1]"] = self.userbillConfig["address1"]
        data_to_post["checkout[billing_address][address2]"] = self.userbillConfig["address2"]
        data_to_post["checkout[billing_address][city]"] = self.userbillConfig["city"]
        data_to_post["checkout[billing_address][country]"] = self.userbillConfig["country"]
        data_to_post["checkout[billing_address][province]"] = self.userbillConfig["province"]
        data_to_post["checkout[billing_address][zip]"] = self.userbillConfig["zip"]
        data_to_post["checkout[billing_address][phone]"] = self.userbillConfig["phone"]
        data_to_post["checkout[remember_me]"] = "0"
        data_to_post["checkout[vault_phone]"] = ""
        data_to_post["checkout[total_price]"] = price
        data_to_post["complete"] = "1"
        data_to_post["checkout[client_details][browser_width]"] = "1170"
        data_to_post["checkout[client_details][browser_height]"] = "711"
        data_to_post["checkout[client_details][javascript_enabled]"] = "1"
        
        return data_to_post
    }
    
    
    internal func data(ofMethod auth_token:String, ship_method:String) -> [String:Any] {
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
    
    
    internal func genCreditInfoData() -> [String:Any]{
        var credit_info = [String:Any]()
        var data_to_post = [String:Any]()
        
        credit_info["number"] = self.userCreditConfig["cardNumber"]
        credit_info["name"] = self.userCreditConfig["nameOnCard"]
        credit_info["month"] = ""
        credit_info["year"] = ""
        credit_info["verification_value"] = self.userCreditConfig["cvv"]
        
        data_to_post["credit_card"] = credit_info
        
        return data_to_post
    }
}







struct ProductInfo {
    private var json:[String:Any] = [:]
    var productName:String? {
        guard let product = json["product"] as? [String:Any] else {return ""}
        let name = product["title"]
        return name as? String
    }
    var storeID:String = ""
    var quantity:Int = 0
    
    init(data:Data,wantSize:Double,wantQuantity:Int) {
        do {
            let object = try JSONSerialization.jsonObject(with: data, options: [])
            guard let json = object as? [String:Any] else {return}
            self.json = json
            
            guard let product = json["product"] as? [String:Any] else {return}
            guard let variants : Array<Any> = product["variants"] as? Array<Any> else {return}
            
            for variant in variants {
                guard let variant = variant as? Dictionary<String, Any> else{return}
                guard let size = variant["option1"] as? String else{return}
                
                if wantSize == Double(size){
                    if let id = variant["id"] as? Int {
                        self.storeID = String(id)
                        if let invQuantity = variant["inventory_quantity"] as? Int {
                            if invQuantity == 0 {
                                print("Out of stock")
                            }
                            if invQuantity >= wantQuantity {
                                self.quantity = wantQuantity
                            }else {
                                self.quantity = invQuantity
                            }
                        }else {
                            self.quantity = 1
                        }
                    }
                }
            }
        }catch {
            print("Invalid data")
        }
    }
}




typealias emails = [Dictionary<String, String>]







struct EmailsData {
    var values:emails
    
    var emailOptions:[String:String] {
        var options:[String:String] = [:]
        
        for value in values {
            if let abbr = value["abbr"], let address = value["address"]{
                options[abbr] = address
            }
        }
        return options
    }
    
    var abbrs:Array<String> {
        var abbrs:Array<String> = []
        for value in values {
            if let abbr = value["abbr"] {
                abbrs.append(abbr)
            }
        }
        return abbrs
    }
    
    init() {
        let array = PlistDicManager.readPlistObject(withkey: "Emails") as! emails
        self.values = array
    }
}


public enum Site : String {
    case rockcitykicks = "https://rockcitykicks.com"
    case exclucitylife = "https://shop.exclucitylife.com"
    case yeezysupply = "https://yeezysupply.com"
    case notre = "https://www.notre-shop.com"
    case bowsandarrows = "https://www.bowsandarrowsberkeley.com"
    case shoegallerymiami = "https://shoegallerymiami.com"
    case shopnicekicks = "https://shopnicekicks.com"
    case deadstock = "https://www.deadstock.ca"
    case apbstore = "https://www.apbstore.com"
    case socialstatuspgh = "https://www.socialstatuspgh.com"
    case a_ma_maniere = "https://www.a-ma-maniere.com"
    
    static let siteDic = ["a_ma_maniere":a_ma_maniere,
                          "apbstore":apbstore,
                          "bowsandarrows":bowsandarrows,
                          "deadstock":deadstock,
                          "exclucitylife":exclucitylife,
                          "notre":notre,
                          "rockcitykicks":rockcitykicks,
                          "shoegallerymiami":shoegallerymiami,
                          "shopnicekicks":shopnicekicks,
                          "socialstatuspgh":socialstatuspgh,
                          "yeezysupply":yeezysupply]
    
    static let allSites = [String(describing: a_ma_maniere),
                           String(describing: apbstore),
                           String(describing: bowsandarrows),
                           String(describing: deadstock),
                           String(describing: exclucitylife),
                           String(describing: notre),
                           String(describing: rockcitykicks),
                           String(describing: shoegallerymiami),
                           String(describing: shopnicekicks),
                           String(describing: socialstatuspgh),
                           String(describing: yeezysupply)]
}
