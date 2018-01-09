import Foundation

public class Ethereum {

  //MARK: Properties
  public let node: String
  public let rpcVersion = "2.0"
  public var requestId = 0

  //MARK: Initializer
  public init(using node: String) {
    self.node = node
  }

  //MARK: Methods
  public func jsonData(method: String, params: [String]) -> Data? {
    var json = [String: Any]()
    json["jsonrpc"] = rpcVersion
    json["id"] = requestId
    json["method"] = method
    json["params"] = params
    let data = try? JSONSerialization.data(withJSONObject: json, options: [])
    return data
  }

  public func xRequest(with json: Data) -> URLRequest {
    let url = URL(string: self.node)!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = json
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    return request
  }

  public var networkSession: URLSession {
    return URLSession.shared
  }

  public func networkRequest(with json: Data, dataRetrieved: @escaping (String) -> Void) {
    //URL Request
    let url = URL(string: self.node)!
    let session = URLSession.shared
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = json
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")

    let requestFinished: (Data?, URLResponse?, Error?) -> Void  = { data, response, error in
      if let data = data {
        do {
          let jsonSerialized = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
          let result = jsonSerialized["result"]!
          dataRetrieved(result as! String) //make as! Any
        } catch {
          print("Network error: \(error)")
        }
      }
    }

    //Execute Task
    let task = session.dataTask(with: request, completionHandler: requestFinished)

    task.resume()
    self.requestId += 1
  }

  //Convenience Methods
  public func balance(of wallet: String, callback: @escaping (String) -> Void) {
    let json = self.jsonData(method: "eth_getBalance", params: [wallet, "latest"])
    self.networkRequest(with: json!, dataRetrieved: callback)
  }

  public func newAccount(password: String, callback: @escaping (String) -> Void) {
    let json = self.jsonData(method: "personal_newAccount", params: [password])
    self.networkRequest(with: json!, dataRetrieved: callback)
  }

  public func accounts(dataRetrieved: @escaping ([String]) -> Void) {
    let json = self.jsonData(method: "personal_listAccounts", params: [])
    let request = self.xRequest(with: json!)
    let task = self.networkSession.dataTask(with: request) {
      data, response, error in

      if let data = data {
        do {
          let jsonSerialized = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
          let result = jsonSerialized["result"]
          dataRetrieved(result as! [String])
        } catch {
          print("Error: \(error)")
        }
      }
    }
    task.resume()
  }

}
