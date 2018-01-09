import Foundation

public class Ethereum {

  //MARK: Properties
  public let node: String
  public let rpcVersion = "2.0"
  public var requestId = 0

  //MARK: Computed Properties
  public var networkSession: URLSession {
    return URLSession.shared
  }

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

  public func networkRequest(with json: Data) -> URLRequest {
    let url = URL(string: self.node)!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = json
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    return request
  }

  //Validate JSON
  func validated(_ data: Data?) -> Any? {
    let result: Any?
    if let data = data {
      do {
        let jsonSerialized = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        result = jsonSerialized["result"]
      } catch {
        print("Data error: \(error)")
        result = nil
      }
    } else {
      result = nil
    }
    return result
  }

  //Convenience Methods
  public func balance(of wallet: String, dataRetrieved: @escaping (String) -> Void) {
    let json = self.jsonData(method: "eth_getBalance", params: [wallet, "latest"])
    let request = self.networkRequest(with: json!)
    let task = self.networkSession.dataTask(with: request) {
      data, response, error in
      if let data = self.validated(data) {
        dataRetrieved(data as! String)
      }
    }
    task.resume()
  }

  public func newAccount(password: String, dataRetrieved: @escaping (String) -> Void) {
    let json = self.jsonData(method: "personal_newAccount", params: [password])
    let request = self.networkRequest(with: json!)
    let task = self.networkSession.dataTask(with: request) {
      data, response, error in
      if let data = self.validated(data) {
        dataRetrieved(data as! String)
      }
    }
    task.resume()
  }

  public func accounts(dataRetrieved: @escaping ([String]) -> Void) {
    let json = self.jsonData(method: "personal_listAccounts", params: [])
    let request = self.networkRequest(with: json!)
    let task = self.networkSession.dataTask(with: request) {
      data, response, error in
      if let data = self.validated(data) {
        dataRetrieved(data as! [String])
      }
    }
    task.resume()
  }

}
