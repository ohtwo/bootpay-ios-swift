//
//  BootpayAnalytics.swift
//  client_bootpay_swift
//
//  Created by YoonTaesup on 2017. 10. 27..
//  Copyright © 2017년 bootpay.co.kr. All rights reserved.
//
import Foundation

 

//MARK: Bootpay Rest Api for Analytics
@objc public class BootpayAnalytics:  NSObject {
    @objc public static func userTrace(id: String, email: String, gender: Int,
                                       birth: String, phone: String, area: String, applicationId: String?) {
        if Bootpay.shared.payload?.userInfo?.id == "" { Bootpay.shared.payload?.userInfo?.id = id }
        if Bootpay.shared.payload?.userInfo?.email == "" { Bootpay.shared.payload?.userInfo?.email = email }
        if Bootpay.shared.payload?.userInfo?.gender == 0 { Bootpay.shared.payload?.userInfo?.gender = gender }
        if Bootpay.shared.payload?.userInfo?.birth == "" { Bootpay.shared.payload?.userInfo?.birth = birth }
        if Bootpay.shared.payload?.userInfo?.phone == "" { Bootpay.shared.payload?.userInfo?.phone = phone }
        if Bootpay.shared.payload?.userInfo?.area == "" { Bootpay.shared.payload?.userInfo?.area = area }
        
        let uri = "https://analytics.bootpay.co.kr/login"
        var params: [String: Any]
        params = [
            "ver": Bootpay.shared.ver,
            "application_id": applicationId ?? Bootpay.shared.payload?.applicationId ?? "",
            "id": id,
            "email": email,
            "gender": "\(gender)",
            "birth": birth,
            "phone": phone,
            "area": area
        ]
        
        let json = Bootpay.stringify(params)
        do {
            let aesBody = try json.aesEncrypt(key: Bootpay.shared.key, iv: Bootpay.shared.iv)
            params = [
                "data": aesBody,
                "session_key": Bootpay.getSessionKey()
            ]
            post(url: uri, params: params, isLogin: true)
            
        } catch {}
    }
    
    @objc public static func userTrace() {
        if(Bootpay.shared.payload?.userInfo?.id == "") {
            NSLog("Bootpay Analytics Warning: postLogin() not Work!! Please check id is not empty")
            return
        }
        userTrace(id: Bootpay.shared.payload?.userInfo?.id ?? "",
                  email: Bootpay.shared.payload?.userInfo?.email ?? "",
                  gender: Bootpay.shared.payload?.userInfo?.gender ?? -1,
                  birth: Bootpay.shared.payload?.userInfo?.birth ?? "",
                  phone: Bootpay.shared.payload?.userInfo?.phone ?? "",
                  area: Bootpay.shared.payload?.userInfo?.area ?? "",
                  applicationId: Bootpay.shared.application_id ?? Bootpay.shared.payload?.applicationId ?? ""
        )
    }
    
    @objc public static  func pageTrace(_ url: String, _ page_type: String? = nil) {
        pageTrace(url, items: [], page_type)
    }
    
    @objc public static  func pageTrace(_ url: String, items: [BootpayStatItem], _ page_type: String? = nil) {
        let uri = "https://analytics.bootpay.co.kr/call"
        
        if let json = items.toJSONString() {
            let params = [
                "ver": Bootpay.shared.ver,
                "application_id": Bootpay.shared.payload?.applicationId ?? "",
                "uuid": Bootpay.shared.getUUID(),
                "referer": "",
                "sk": Bootpay.shared.sk,
                "user_id": Bootpay.shared.payload?.userInfo?.id ?? "",
                "url": url,
                "page_type": page_type ?? "",
                "items": json
            ]
            
            let json = Bootpay.stringify(params)
            do {
                let aesBody = try json.aesEncrypt(key: Bootpay.shared.key, iv: Bootpay.shared.iv)
                let params = [
                    "data": aesBody,
                    "session_key": Bootpay.getSessionKey()
                ]
                post(url: uri, params: params, isLogin: false)
                
            } catch {}
        }
    }
    
    @objc public static func post(url: String, params: [String: Any], isLogin: Bool) {
        let session = URLSession.shared
        let request = NSMutableURLRequest(url: NSURL(string: url)! as URL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        do{
            let jsonData = try JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions())
            request.httpBody = jsonData
            let task = session.dataTask(with: request as URLRequest as URLRequest, completionHandler: {(data, response, error) in
                guard error == nil else { return }
                if isLogin == false { return }
                guard let data = data else { return }
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                        if let data = json["data"] as? [String : Any], let user_id = data["user_id"] as? String {
                            Bootpay.shared.payload?.userInfo?.id = user_id
                        }
                    }
                } catch let error {
                    print(error.localizedDescription)
                }
            })
            task.resume()
        }catch _ {
            print ("Oops something happened buddy")
        }
    }
}
