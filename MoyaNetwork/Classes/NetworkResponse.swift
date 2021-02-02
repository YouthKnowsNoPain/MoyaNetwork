//
//  NetworkResponse.swift
//  MoyaNetwork
//
//  Created by huangkun on 2021/2/2.
//

import Moya
import RxSwift
import HandyJSON

public extension ObservableType where E == ResultModel {
    /// 对 data 是字典的处理
    /// - Parameters:
    ///   - type: model type HandyJSON
    /// - Returns: Observable
    func mapModel<T: HandyJSON>(_ type: T.Type) -> Observable<T?> {
        return flatMap({ (result) -> Observable<T?> in
            return Observable.just(result.parseToObj(T.self))
        })
    }
    
    /// 对 data 是数组的处理
    /// - Parameters:
    ///   - type: model type HandyJSON
    /// - Returns: Observable
    func mapArrayModel<T: HandyJSON>(_ type: T.Type) -> Observable<[T]?> {
        return flatMap({ (result) -> Observable<[T]?> in
            return Observable.just(result.parseToArray(T.self)?.compactMap({$0}))
        })
    }
    
    /// 对 data 是字符串的处理
    /// - Parameters:
    /// - Returns: Observable
    func mapStringValue() -> Observable<String> {
        return flatMap({ (result) -> Observable<String> in
            return Observable.just(result.parseToString())
        })
    }
}

extension Response {
    
    func mapModel<T: HandyJSON>(_ type: T.Type) throws -> T? {
        
        do {
            if let dict = try mapJSON() as? [String:Any] {
                return JSONDeserializer<T>.deserializeFrom(dict: dict)
            } else {
                throw NetworkResultError(msg: "未知错误", code: 0)
            }
        } catch _ as MoyaError {
            throw NetworkResultError(msg: self.description, code: self.statusCode)
        } catch let error as NetworkResultError {
            throw error
        }
    }
}
