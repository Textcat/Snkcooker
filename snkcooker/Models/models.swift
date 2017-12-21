//
//  models.swift
//  snkcooker
//
//  Created by 刘业臻 on 2017/12/17.
//  Copyright © 2017年 luiyezheng. All rights reserved.
//

import Foundation

struct BotTarget {
    let site:Site
    var quantity:Int
    var size:Double
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
            if let abbr = value["abbr"] {
                options[abbr] = value[abbr]
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
}
