import CCurl
import C7

public typealias Headers = [(String,String)]

public enum Method: String {
    case HEAD, GET, POST, PUT, DELETE
}

public struct Curl {
    private class WriteStorage {
        var data = Data()
    }
    
    public var timeout = 3
    public var verbose = false
    
    public func get(url: String, headers: Headers) -> Data? {
        return sendRequest(method: .GET, url: url, headers: headers)
    }
    
    public func post(url: String, headers: Headers, body: Data?) -> Data? {
        if let body = body {
            return sendRequest(method: .POST, url: url, headers: headers, body: body)
        } else {
            return sendRequest(method: .POST, url: url, headers: headers)
        }
    }
    
    private func sendRequest(method: Method, url: String, headers: Headers, body: Data = Data()) -> Data? {
        let handle = curl_easy_init()
        
        // set url
        url.withCString { url -> Void in
            curlHelperSetOptString(handle, CURLOPT_URL, UnsafeMutablePointer(mutating: url))
        }
        
        // set timeout
        curlHelperSetOptInt(handle, CURLOPT_TIMEOUT, timeout)
        
        // set verbose
        curlHelperSetOptBool(handle, CURLOPT_VERBOSE, verbose ? CURL_TRUE : CURL_FALSE)
        
        // set method
        switch method {
        case .HEAD:
            curlHelperSetOptBool(handle, CURLOPT_NOBODY, CURL_TRUE)
            method.rawValue.withCString { method -> Void in
                curlHelperSetOptString(handle, CURLOPT_CUSTOMREQUEST, UnsafeMutablePointer(mutating: method))
            }
        case .GET:
            curlHelperSetOptBool(handle, CURLOPT_HTTPGET, CURL_TRUE)
        case .POST:
            curlHelperSetOptBool(handle, CURLOPT_POST, CURL_TRUE)
        default:
            method.rawValue.withCString { method -> Void in
                curlHelperSetOptString(handle, CURLOPT_CUSTOMREQUEST, UnsafeMutablePointer(mutating: method))
            }
        }
        
        // set headers
        var headersList: UnsafeMutablePointer<curl_slist>?
        for (key, value) in headers {
            let header = "\(key): \(value)"
            header.withCString { ptr in
                headersList = curl_slist_append(headersList, ptr)
            }
        }
        if let _ = headersList {
            curlHelperSetOptHeaders(handle, headersList!)
        }
        
        // set body
        if body.count > 0 {
            curlHelperSetOptInt(handle, CURLOPT_POSTFIELDSIZE, body.count)
            curlHelperSetOptString(handle, CURLOPT_POSTFIELDS, UnsafeMutableRawPointer(mutating: body.bytes).assumingMemoryBound(to: Int8.self))
        }
        
        // set write func
        var writeStorage = WriteStorage()
        curlHelperSetOptWriteFunc(handle, &writeStorage) { (ptr, size, nMemb, privateData) -> Int in
            let storage = UnsafeRawPointer(privateData)?.assumingMemoryBound(to: WriteStorage.self)
            let realsize = size * nMemb
            
            var bytes: [UInt8] = [UInt8](repeating: 0, count: realsize)
            memcpy(&bytes, ptr, realsize)
            
            for byte in bytes {
                storage?.pointee.data.append(byte)
            }
            return realsize
        }
        
        // perform
        var responseData: Data? = nil
        let ret = curl_easy_perform(handle)
        if ret == CURLE_OK {
            responseData = writeStorage.data
        } else {
            let error = curl_easy_strerror(ret)
            if let errStr = String(validatingUTF8: error!) {
                print("error = \(errStr)")
            }
            print("ret = \(ret)")
        }
        
        // cleanup
        curl_easy_cleanup(handle)
        
        if let _ = headersList {
            curl_slist_free_all(headersList!)
        }
        
        return responseData
    }
}
