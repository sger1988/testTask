//
//  GetUserReposRequest.swift
//  GitHubReposTask
//
//  Created by Sergey Gerashchenko on 4/4/18.
//  Copyright © 2018 Sergey Gerashchenko. All rights reserved.
//

import Foundation

class GetUserReposRequest {
  
  static func fire(userName: String, pageToLoad: Int = 1, completion: @escaping (_ data: Data?, _ error: Any?) -> Void) {
    let sessionConfig = URLSessionConfiguration.default
    let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
    guard var URL = URL(string: Constants.RequestStrings.URL.source + Constants.RequestStrings.URL.users + userName + Constants.RequestStrings.URL.repositiries) else { return }
    let URLParams = [
      Constants.RequestStrings.Params.perPage: String(Constants.pageSize),
      Constants.RequestStrings.Params.page   : String(pageToLoad),
      ]
    URL = URL.appendingQueryParameters(URLParams)
    var request = URLRequest(url: URL)
    request.httpMethod = Constants.RequestStrings.Methods.get
    
    let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Any?) -> Void in
      if (error == nil) {
        guard let receivedData = data else { return }
        let statusCode = (response as! HTTPURLResponse).statusCode
        
        switch statusCode {
        case 300...599:
          completion(receivedData, Constants.Messages.erorrResponse)
        default:
          completion(receivedData, nil)
        }
      } else {
        completion(data, error)
      }
    })
    
    task.resume()
    session.finishTasksAndInvalidate()
  }
  
}

protocol URLQueryParameterStringConvertible {
  var queryParameters: String { get }
}

extension Dictionary : URLQueryParameterStringConvertible {
  
  var queryParameters: String {
    var parts: [String] = []
    for (key, value) in self {
      let part = String(format: "%@=%@",
                        String(describing: key).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!,
                        String(describing: value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
      parts.append(part as String)
    }
    return parts.joined(separator: "&")
  }
  
}

extension URL {
  
  func appendingQueryParameters(_ parametersDictionary : Dictionary<String, String>) -> URL {
    let URLString : String = String(format: "%@?%@", self.absoluteString, parametersDictionary.queryParameters)
    return URL(string: URLString)!
  }
  
}
