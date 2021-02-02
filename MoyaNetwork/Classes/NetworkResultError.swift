//
//  NetworkResultError.swift
//  MoyaNetwork
//
//  Created by huangkun on 2021/2/2.
//

import Moya

public struct NetworkResultCode {
    /// 成功
    static let success = 200
    /// 失败
    static let failure = 400
    /// 未登录
    static let unauth = 401
    /// 重定向
    static let redirect = 403
    static let urlLost = 404
    /// 服务繁忙，无效相应
    static let serverBusy = 502
    /// 服务不可用
    static let badGateway = 503
    /// 缺少参数
    static let needParam = 4011
    /// 超时
    static let timeout = -1001
    /// 没有网络
    static let noNetwork = -1009
    /// 无主机链接
    static let unConnectHost = -1003
    /// 目前不允许链接
    static let notAllowConnect = -1020
}

class NetworkResultError: LocalizedError {
    
    var msg = ""
    var code = 200
    
    convenience init(msg:String, code:Int) {
        self.init()
        self.msg = msg
        self.code = code
    }
}

extension NetworkResultError {
    
    var errorDescription: String {
        return msg
    }
    
    var localizedDescription: String {
        return msg
    }
}

func NetworkErrorDescription(_ error: Error) -> String {
    
    func message(with code:Int) -> String? {
        
        if [NetworkResultCode.timeout,
            NetworkResultCode.serverBusy,
            NetworkResultCode.badGateway,
            NetworkResultCode.urlLost,
            NetworkResultCode.notAllowConnect].contains(code) {
            return "网络请求失败，请稍后重试"
        }
        
        if code == NetworkResultCode.noNetwork ||
            code == NetworkResultCode.notAllowConnect {
            return "似乎已断开与互联网的连接"
        }
        return nil
    }
    
    if let error = error as? NetworkResultError {
        if  error.code == NetworkResultCode.unauth {
            return error.msg
        }
        
        if let message = message(with: error.code) {
            return message
        }
        
        return error.errorDescription
    }
    
    if let error = error as? MoyaError {
        switch error {
        case .underlying(let error, _):
            if (error as NSError).code < 0 {
                return "网络请求失败，请稍后重试"
            }
        default:
            return error.localizedDescription
        }
    }
    
    let error = error as NSError
    if let message = message(with: error.code) {
        return message
    }
    
    return error.localizedDescription
}

func NetworkErrorCode(_ error:Error) -> Int {
    
    if let error = error as? NetworkResultError {
        return error.code
    }
    
    if let error = error as? MoyaError {
        switch error {
        case .underlying(let error, _):
            return (error as NSError).code
        default:
            return error.response?.statusCode ?? -1
        }
    }
    
    if let error = error as NSError? {
        return error.code
    }
    
    return -1
}
