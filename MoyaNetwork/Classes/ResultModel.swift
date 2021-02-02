//
//  ResultModel.swift
//  MoyaNetwork
//
//  Created by huangkun on 2021/2/2.
//

import HandyJSON

public struct ResultModel: HandyJSON {
    var code:Int?
    var data:Any?
    var message:String?
    
    /// 是否成功
    public var isSuccess:Bool {
        return code == NetworkResultCode.success
    }
    
    /// 解析数组对象
    public func parseToArray<T:HandyJSON>(_ type: T.Type) -> [T?]? {
        return JSONDeserializer<T>.deserializeModelArrayFrom(array: data as? Array)
    }

    /// 解析单个对象
    public func parseToObj<T:HandyJSON>(_ type: T.Type) -> T? {
        return JSONDeserializer<T>.deserializeFrom(dict: data as? Dictionary)
    }
    
    /// 解析成字符串
    public func parseToString() -> String {
        return (data as? String) ?? ""
    }
    
    public init() {}
}

public struct ResultEmptyModel: HandyJSON {
    public init() {}
}


