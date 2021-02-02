//
//  BaseMoyaNetwork.swift
//  MoyaNetwork
//
//  Created by huangkun on 2021/2/2.
//

@_exported import Moya
@_exported import HandyJSON
@_exported import RxSwift

/// 登陆过期通知
public let UnauthNotify = NSNotification.Name(rawValue: "UnauthNotify")

public struct BaseNetworkConfig {
    public var requestTimeOut:Double = 10
    public var plugins:[PluginType] = [NormalRequestPlugin()]
    
    public init() {}
    public init(timeOut:Double = 10,plugins:[PluginType] = [NormalRequestPlugin()]) {
        self.requestTimeOut = timeOut
        self.plugins = plugins
    }
}

public class BaseMoyaNetwork<Target:TargetType> {
    
    private var network:MoyaProvider<Target>!
    private var headerFieldsCourse:(() -> [String:String])?
    private var config = BaseNetworkConfig()
    
    public init(config:BaseNetworkConfig = BaseNetworkConfig(), headerFieldsCourse:(() -> [String:String])? = nil) {
        self.config = config
        self.headerFieldsCourse = headerFieldsCourse
        network = MoyaProvider<Target>(endpointClosure: myEndpointClosure,
                                            requestClosure: myRequestClosure,
                                            plugins: config.plugins)
    }
    
    /// 网络请求
    /// - Parameters:
    ///   - token: api
    ///   - callbackQueue: 线程
    ///   - notifyUnauth: 是否需要 登录验证相关处理
    /// - Returns: ResultModel
    public func request(_ token: Target,
                        callbackQueue:DispatchQueue? = nil,
                        notifyUnauth: Bool = true) -> Observable<ResultModel>  {
        return Observable<ResultModel>.create { (observer) -> Disposable in
            return self.network.rx.request(token, callbackQueue: callbackQueue)
                .subscribe(onSuccess: { (response) in
                    do{
                        if let result = try response.mapModel(ResultModel.self) {
                            // 这里处理 请求结果
                            if result.isSuccess {
                                observer.onNext(result)
                                observer.onCompleted()
                            } else if result.code == NetworkResultCode.unauth {
                                // 这里处理登录过期的问题
                                if notifyUnauth {
                                    NotificationCenter.default.post(name: UnauthNotify, object: result)
                                }
                                
                                let error = NetworkResultError(msg: result.message ?? "登录过期",
                                                               code: result.code ?? 0)
                                observer.onError(error)
                    
                            } else {
                                let error = NetworkResultError(msg: result.message ?? "未知错误",
                                                               code: result.code ?? 0)
                                observer.onError(error)
                            }
                        } else {
                            let error = NetworkResultError(msg: "未知错误", code: 0)
                            observer.onError(error)
                        }
                    } catch {
                        observer.onError(error)
                    }

                }, onError: {(error) in
                    observer.onError(error)
                })
        }
    }
    
    public func requestProgress(_ token: Target,
                                callbackQueue:DispatchQueue? = nil) -> Observable<ProgressResponse> {
        return Observable<ProgressResponse>.create { (observer) -> Disposable in
            return self.network.rx.requestWithProgress(token, callbackQueue: callbackQueue)
                .subscribe(onNext: { (progressResponse) in
                    // 进度
                    observer.onNext(progressResponse)
                }, onError: { (error) in
                    // 报错
                    observer.onError(error)
                }, onCompleted: {
                    // 完成
                    observer.onCompleted()
                })
        }
    }
    
    private func myEndpointClosure(_ target: Target) -> Endpoint {
        // headeFields
        let headers = target.headers ?? [:]
        // 这里是默认传的 headers
        var defaultHeaders = headerFieldsCourse?() ?? [:]
        
        // 合并，新值覆盖旧值
        defaultHeaders.merge(headers, uniquingKeysWith: {(_, new) in new})

        let endpoint = Endpoint (
            url: URL(target: target).absoluteString,
            sampleResponseClosure: { .networkResponse(200, target.sampleData) },
            method: target.method,
            task: target.task,
            httpHeaderFields: defaultHeaders
        )
        return endpoint
    }

    private func myRequestClosure(endpoint:Endpoint, closure: MoyaProvider<Target>.RequestResultClosure) {
        
        do {
            var request = try endpoint.urlRequest()
            //设置请求时长
            request.timeoutInterval = config.requestTimeOut
            closure(.success(request))
        } catch MoyaError.requestMapping(let url) {
            closure(.failure(MoyaError.requestMapping(url)))
        } catch MoyaError.parameterEncoding(let error) {
            closure(.failure(MoyaError.parameterEncoding(error)))
        } catch {
            closure(.failure(MoyaError.underlying(error, nil)))
        }
    }
}

///插件
public class NormalRequestPlugin: PluginType {
    
    public init() {}
    
    /// 准备发送请求
    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        
        return request
    }
    
    /// 将要发送请求
    public func willSend(_ request: RequestType, target: TargetType) {
        
        #if DEBUG
        print("******************************请求开始\(target.path)******************************")
        print("请求地址：\(request.request?.url?.absoluteString ?? "")")
        print("请求头部：\(request.request?.allHTTPHeaderFields ?? [:])")
        switch target.task {
        case let .requestParameters(parameters, _):
            print("请求参数：\(parameters)")
            break
        default:
            break
        }
        #endif
    }
    
    public func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        #if DEBUG
        print("******************************请求结束\(target.path)******************************")
        print("响应头部：\(result)")
        switch result {
        case .success(let re):
            print("返回错误 = \(String(describing: try? re.mapJSON()))")
        case .failure(let error):
            print("返回错误 = \(error)")
        }
        #endif
    }
}
