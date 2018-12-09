//
//  APIManager.swift
//  SuryaSoftDemo
//
//  Created by SUBAHAN on 07/12/18.
//  Copyright © 2018 SUBAHAN. All rights reserved.
//

import Foundation
import UIKit

class APIService: NSObject {
    

    
    func getDataWith(email : String,completion: @escaping (Result<[[String: AnyObject]]>) -> Void) {
        
        let params = ["emailId": email] as Dictionary<String, String>
        
        var request = URLRequest(url: URL(string: "http://surya-interview.appspot.com/list")!)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            guard error == nil else { return completion(.Error(error!.localizedDescription)) }
            guard let data = data else { return completion(.Error(error?.localizedDescription ?? "There are no new Items to show"))
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: [.mutableContainers]) as? [String: AnyObject] {
                    guard let itemsJsonArray = json["items"] as? [[String: AnyObject]] else {
                        return completion(.Error(error?.localizedDescription ?? "There are no new Items to show"))
                    }
                    DispatchQueue.main.async {
                        completion(.Success(itemsJsonArray))
                    }
                }
            } catch let error {
                return completion(.Error(error.localizedDescription))
            }
            }.resume()
    }
}

enum Result<T> {
    case Success(T)
    case Error(String)
}


