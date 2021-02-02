//
//  ViewController.swift
//  MoyaNetwork
//
//  Created by UI on 02/02/2021.
//  Copyright (c) 2021 UI. All rights reserved.
//

import UIKit
import MoyaNetwork

/// 全局网络请求
let BaseNetwork = BaseMoyaNetwork<MultiTarget> { () -> [String : String] in
    return ["Authorization":"Authorization"]
}

struct TestModel: HandyJSON {
    var name:String?
}

class ViewController: UIViewController {
    
    var dispadg = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        BaseNetwork.request(MultiTarget(TestAPI.test))
            .mapModel(TestModel.self)
            .subscribe(onNext: { (model) in
                
            }, onError: { (error) in
                
            }).disposed(by: dispadg)
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}


enum TestAPI {
    case test
}

extension TestAPI: TargetType {
    
    var baseURL: URL {
        return URL(string: "http://www.baidu.com")!
    }
    
    var method: Moya.Method {
        
        switch self {
        case .test:
            return .get
        }
    }
    
    var path: String {
        
        switch self {
        case .test:
            return ""
        }
    }
    
    var task: Task {
        
        switch self {
        case .test:
            return .requestPlain
        }
    }
    
    var headers: [String : String]? {
        return nil
    }
    
    var sampleData: Data {
        
        return Data()
    }
}

