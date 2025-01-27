//
//  ViewController.swift
//  PromiseV
//
//  Created by marst123 on 01/27/2025.
//  Copyright (c) 2025 marst123. All rights reserved.
//

import UIKit
import PromiseV
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        let promise = PromiseV<Int> { resolve, reject in
//            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
//                resolve(42) // Simulate an asynchronous operation
//            }
//        }
//
//        promise.then { value in
//            print("Promise fulfilled with value: \(value)")
//        } onRejected: { error in
//            print("Promise rejected with error: \(error)")
//        }

        
//        let promise_Array = PromiseV<[Int]> { resolve, reject in
//            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
//                resolve([42, 1]) // Simulate an asynchronous operation
//            }
//        }
//        
//        let promise_String = PromiseV<String> { resolve, reject in
//            // 模拟异步操作，成功时调用resolve，失败时调用reject
//            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
//                resolve("YES") // Simulate an asynchronous operation
//            }
//        }
//        
//        let promise = PromiseV<([Int], String?)>.thenZip(promise_Array, promise_String) { (array, string) in
//            print("------- Promise then -------")
//            print("Promise fulfilled with value: \(array)")
//            print("Promise fulfilled with value: \(string)")
//
//        } onRejected: { error in
//            print("Promise rejected with error: \(error)")
//        }
//        
//        let wait = PromiseV<([Int], String)>.waitAll(promises: promise) {
//            print("Promise waitAll!")
//        }

//        let promise = PromiseV<Int> { resolve, _ in
//            DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
//                resolve(42)
//            }
//        }
//
//        promise.timeout(seconds: 3, onTimeout: {
//            print("Promise timed out")
//        }).then { value in
//            print("Result: \(value)")
//        }
        

//        start()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

//    func start() {
//        let promise = PromiseV<[Int]> { resolve, reject in
//            DispatchQueue.global().asyncAfter(deadline: .now() + 3.0) {
//                let mockResponse = [1, 2, 3]
//                print("Mock Step 1: \(mockResponse)")
//                resolve(mockResponse)
//            }
//        }
//
//        promise.then { value in
//            
//            print("Step 1: \(value)")
//            
//            return PromiseV<String> { resolve, reject in
//                DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
//                    let mockUploadResponse = "UploadedImageID_12345"
//                    print("Mock Step 2: \(mockUploadResponse)")
//                    resolve(mockUploadResponse)
//                }
//            }.then { value1 in
//                
//                print("Step 2: \(value1)")
//                
//                return PromiseV<Void> { resolve, reject in
//                    
//                    DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
//                        print("Mock Step 3: Download completed")
//                        resolve(())
//                    }
//                }
//            }.catch { error in
//                print("Error String occurred: \(error)")
//            }
//            
//            
//        }.catch { error in
//            print("Error [Int] occurred: \(error)")
//        }
//    }
    
}

