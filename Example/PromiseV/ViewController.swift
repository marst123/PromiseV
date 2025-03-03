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
        
        // Usage
        
        // #1
        //method_1()

        // #2
        //method_2()
        
        // #3
        //method_3()

        // #4
        //method_4_1()
        
        // #4.2
        //method_4_2()

        // #5
        //method_5()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func method_1() {
        let promise = PromiseV<Int> { resolve, reject in
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                resolve(42)
            }
        }

        promise.then { value in
            print("Promise fulfilled with value: \(value)")
        } onRejected: { error in
            print("Promise rejected with error: \(error)")
        }
    }
    
    func method_2() {
        let promise1 = PromiseV<[Int]> { resolve, reject in
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                resolve([42, 1])
            }
        }
        
        let promise2 = PromiseV<String> { resolve, reject in
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                resolve("YES")
            }
        }
        
        let promise = PromiseV<([Int], String?)>.zip(promise1, promise2)
        
        promise.then { zip in
            print("------- Promise then -------")
            print("Promise fulfilled with value: \(zip.0)")
            print("Promise fulfilled with value: \(zip.1)")
        } onRejected: { error in
            print("Promise rejected with error: \(error)")

        }

    }
    
    func method_3() {
        let promise1 = PromiseV<Int> { resolve, reject in
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                resolve(42)
            }
        }

        let promise2 = PromiseV<String> { resolve, reject in
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                resolve("Hello")
            }
        }

        let promise3 = PromiseV<Bool> { resolve, reject in
            DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                resolve(true)
            }
        }
        
        let promise = PromiseV<(Int, String, Bool)>.zip(promise1, promise2, promise3)
        
        promise.then { zip in
            print("------- Promise then -------")
            
            print("Promise fulfilled with value: \(zip.0)")
            print("Promise fulfilled with value: \(zip.1)")
            print("Promise fulfilled with value: \(zip.2)")
        } onRejected: { error in
            print("Promise rejected with error: \(error)")

        }

        let waitPromise = PromiseV<(Int, String, Bool)>.wait(promises: [promise]) { results in
            print("All promises completed!")
            for result in results {
                switch result {
                case .success(let value):
                    print("Success: \(value)")
                case .failure(let error):
                    print("\(error)")
                }
            }
        }
        
    }
    
    func method_4_1() {
        let promise = PromiseV<Int> { resolve, _ in
            DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                resolve(42)
            }
        }.timeout(seconds: 3)

        promise.then { value in
            print("Promise fulfilled with value: \(value)")
        }.catch { error in
            print("Promise rejected with error: \(error.localizedDescription)")
        }
    }
    
    func method_4_2() {
        let promise1 = PromiseV<Int> { resolve, reject in
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                resolve(42)
            }
        }

        let promise2 = PromiseV<String> { resolve, reject in
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                resolve("Hello")
            }
        }

        let promise3 = PromiseV<Bool> { resolve, reject in
            DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                resolve(true)
            }
        }

        let promise = PromiseV<(Int, String, Bool)>.zip(promise1, promise2, promise3)
        
        promise.timeout(seconds: 1).then { zip in
            print("------- Promise then -------")
            print("Promise fulfilled with value: \(zip.0)")
            print("Promise fulfilled with value: \(zip.1)")
            print("Promise fulfilled with value: \(zip.2)")
        } onRejected: { error in
            print("Promise rejected with error: \(error.localizedDescription)")
        }

    }

    func method_5() {
        let promise = PromiseV<[Int]> { resolve, reject in
            DispatchQueue.global().asyncAfter(deadline: .now() + 3.0) {
                let mockResponse = [1, 2, 3]
                resolve(mockResponse)
            }
        }.timeout(seconds: 5)
        
        promise.then { value in
            
            print("Step 1 [then]: \(value)")
            
            return PromiseV<String> { resolve, reject in
                DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                    let mockUploadResponse = "UploadedImageID_12345"
                    resolve(mockUploadResponse)
                }
            }.timeout(seconds: 3).then { value1 in
                
                print("Step 2 [then]: \(value1)")
                
                return PromiseV<Void> { resolve, reject in
                    
                    DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                        resolve(())
                    }
                }.timeout(seconds: 0.5).then { _ in
                    print("Step 3 [then]: \(value1)")
                }.catch { error in
                    print("Step 3 Error null occurred: \(error)")
                }
            }.catch { error in
                print("Step 2 Error String occurred: \(error)")
            }
            
            
        }.catch { error in
            print("Step 1 Error [Int] occurred: \(error)")
        }
    }
    
}

