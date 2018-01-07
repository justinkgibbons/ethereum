import Foundation

class Ethereum {

  //MARK: Properties
  let node: String
  let rpcVersion = "2.0"
  var requestId = 0

  //MARK: Initializer
  init(_ node: String) {
    self.node = node
  }

  //MARK: Methods
  func jsonData(with method: String, and params: [String]) -> Data? {
    var json = [String: Any]()
    json["jsonrpc"] = rpcVersion
    json["id"] = requestId
    json["method"] = method
    json["params"] = params
    let data = try? JSONSerialization.data(withJSONObject: json, options: [])
    return data
  }

  func networkRequest(with json: Data, dataRetrieved: @escaping (String) -> Void) {
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
          dataRetrieved(result as! String)
        } catch {
          print("Error: \(error)")
        }
      }
    }

    //Execute Task
    let task = session.dataTask(with: request, completionHandler: requestFinished)

    task.resume()
    self.requestId += 1
  }

  //Convenience Methods
  func balance(of wallet: String, callback: @escaping (String) -> Void) {
    let json = self.jsonData(with: "eth_getBalance", and: [wallet, "latest"])
    self.networkRequest(with: json!, dataRetrieved: callback)
  }

}
