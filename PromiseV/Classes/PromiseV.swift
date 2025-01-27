/*
 这段代码是一个用Swift语言实现的Promise模式库。
 它提供了一种异步编程的范式，允许开发者更清晰地处理异步操作和链式调用。
 在使用上，开发者可以创建Promise对象，通过then、catch等方法添加回调，以及通过waitAll、thenZip等方法处理多个Promise的情况。
 
 
 
 */

import Foundation

// Promise状态的枚举
public enum PromiseState<T> {
    // 等待状态
    case pending
    // 已完成
    case fulfilled(T)
    // 已失败
    case rejected(Error)
}

// Promise实现的类
public class PromiseV<T> {
    // Promise的当前状态
    private var state: PromiseState<T> = .pending
    // 存储成功回调的数组
    private var onFulfilled: [(T) -> Void] = []
    // 存储失败回调的数组
    private var onRejected: [(Error) -> Void] = []
    // 用于异步操作的队列
    private let queue = DispatchQueue(label: "com.example.promiseQueue")

    // 初始化方法，接受一个executor闭包用于执行异步操作
    public init(_ executor: (@escaping (T) -> Void, @escaping (Error) -> Void) -> Void) {
        executor({ value in
            self.queue.async {
                // 异步执行成功回调
                self.handleFulfillment(value)
            }
        }, { error in
            self.queue.async {
                // 异步执行失败回调
                self.handleRejection(error)
            }
        })
    }
    
    private func handleFulfillment(_ value: T) {
        self.state = .fulfilled(value)
        for callback in self.onFulfilled {
            callback(value)
        }
    }

    private func handleRejection(_ error: Error) {
        self.state = .rejected(error)
        for callback in self.onRejected {
            callback(error)
        }
    }

    // then方法，用于处理成功回调
    public func then<U>(_ onFulfilled: @escaping (T) -> U) -> PromiseV<U> {
        return then(onFulfilled: onFulfilled, onRejected: { _ in })
    }

    // then方法的重载，用于同时处理成功和失败回调
    public func then<U>(onFulfilled: @escaping (T) -> U, onRejected: @escaping (Error) -> Void) -> PromiseV<U> {
        let newPromise = PromiseV<U> { resolve, reject in
            switch self.state {
            case .fulfilled(let value):
                self.queue.async {
                    do {
                        // 使用可选绑定确保在执行成功回调之前状态没有变化
                        guard case .fulfilled = self.state else { return }
                        
                        // 如果Promise已完成，异步执行成功回调，并将结果传递给新Promise的resolve
                        let transformedValue = try onFulfilled(value)
                        resolve(transformedValue)
                    } catch {
                        // 如果转换失败，将错误传递给新Promise的reject
                        reject(error)
                    }
                }
            case .rejected(let error):
                self.queue.async {
                    // 如果Promise已失败，异步执行失败回调，并将结果传递给新Promise的reject
                    onRejected(error)
                    reject(error)
                }
            case .pending:
                self.onFulfilled.append { value in
                    self.queue.async {
                        // 使用可选绑定确保在执行成功回调之前状态没有变化
                        guard case .fulfilled = self.state else { return }
                        
                        do {
                            // 如果Promise仍在pending状态，将成功回调添加到数组中，并将结果传递给新Promise的resolve
                            let transformedValue = try onFulfilled(value)
                            resolve(transformedValue)
                        } catch {
                            // 如果转换失败，将错误传递给新Promise的reject
                            reject(error)
                        }
                    }
                }
                self.onRejected.append { error in
                    self.queue.async {
                        // 将失败回调添加到数组中，并将结果传递给新Promise的reject
                        onRejected(error)
                        reject(error)
                    }
                }
            }
        }
        return newPromise
    }


    // catch方法的重载，用于处理失败回调并返回不同类型的Promise
    public func `catch`<U>(_ onRejected: @escaping (Error) -> U) -> PromiseV<U> {
        let newPromise = PromiseV<U> { resolve, reject in
            switch self.state {
            case .fulfilled(let value):
                // 如果Promise已完成，直接调用成功回调
                resolve(value as! U) // Assumes a safe cast, adjust as needed
            case .rejected(let error):
                self.queue.async {
                    // 如果Promise已失败，异步执行失败回调，并将结果传递给新Promise的reject
                    let transformedValue = onRejected(error)
                    if let transformedError = transformedValue as? Error {
                        reject(transformedError)
                    } else {
                        // 如果转换失败，创建一个新的Error对象
                        let typeMismatchError = NSError(domain: "Promise", code: 2, userInfo: [NSLocalizedDescriptionKey: "Type mismatch in catch block"])
                        reject(typeMismatchError)
                    }
                }
            case .pending:
                // 如果Promise仍在pending状态，将成功和失败回调添加到数组中
                self.onFulfilled.append { value in
                    resolve(value as! U) // Assumes a safe cast, adjust as needed
                }
                self.onRejected.append { error in
                    let transformedValue = onRejected(error)
                    if let transformedError = transformedValue as? Error {
                        reject(transformedError)
                    } else {
                        let typeMismatchError = NSError(domain: "Promise", code: 2, userInfo: [NSLocalizedDescriptionKey: "Type mismatch in catch block"])
                        reject(typeMismatchError)
                    }
                }
            }
        }
        return newPromise
    }


    
    // progress方法，用于添加进度通知逻辑
    public func progress<U>(_ onProgress: @escaping (Float) -> U) -> PromiseV<U> {
        let newPromise = PromiseV<U> { resolve, _ in
            // 添加进度通知逻辑
            // Example: notify progress and pass the transformed result to the resolve
            resolve(onProgress(0.5))
        }
        return newPromise
    }

    // waitAll方法，等待多个Promise完成，然后触发completion回调
    // 建议使用PromiseV<Bool>
    public static func waitAll<U>(promises: PromiseV<U>..., completion: @escaping () -> Void) -> PromiseV<U> {
        return PromiseV<U> { resolve, reject in
            var fulfilledCount = 0
            let totalPromises = promises.count
            
            for promise in promises {
                promise.then({ value in
                    fulfilledCount += 1
                    if fulfilledCount == totalPromises {
                        completion()
                    }
                }).catch(reject)
            }
        }
    }

    public static func thenZip<T1, T2>(_ promise1: PromiseV<T1>, _ promise2: PromiseV<T2>, onZipFulfilled: @escaping ((T1, T2)) -> Void, onRejected: @escaping (Error) -> Void) -> PromiseV<(T1, T2)> {
        return PromiseV<(T1, T2)> { resolve, reject in
            var result1: T1?
            var result2: T2?

            // Define a helper function to check if both promises have resolved
            func checkCompletion() {
                if let result1 = result1, let result2 = result2 {
                    onZipFulfilled((result1, result2))
                    resolve((result1, result2))
                }
            }

            // Helper function to handle a promise and set the result
            func handlePromise<T>(_ promise: PromiseV<T>, completion: @escaping (T) -> Void) {
                promise.then { value in
                    let localResult = value
                    completion(localResult)
                    // Check completion after handling the promise
                    checkCompletion()
                }.catch { error in
                    // Call onRejected callback if the promise is rejected
                    onRejected(error)
                    reject(error)
                }
            }

            // Handle the first promise
            handlePromise(promise1) { value in
                result1 = value
            }

            // Handle the second promise
            handlePromise(promise2) { value in
                result2 = value
            }
        }
    }


    
    public static func thenZip<T1, T2, T3>(_ promise1: PromiseV<T1>, _ promise2: PromiseV<T2>, _ promise3: PromiseV<T3>, _ onZipFulfilled: @escaping ((T1, T2, T3)) -> Void) -> PromiseV<(T1, T2, T3)> {
        return PromiseV<(T1, T2, T3)> { resolve, reject in
            var result1: T1?
            var result2: T2?
            var result3: T3?

            // Define a helper function to check if all promises have resolved
            func checkCompletion() {
                if let result1 = result1, let result2 = result2, let result3 = result3 {
                    onZipFulfilled((result1, result2, result3))
                    resolve((result1, result2, result3))
                }
            }

            // Helper function to handle a promise and set the result
            func handlePromise<T>(_ promise: PromiseV<T>, completion: @escaping (T) -> Void) {
                promise.then { value in
                    let localResult = value
                    completion(localResult)
                    checkCompletion()
                }.catch(reject)
            }

            // Handle the first promise
            handlePromise(promise1) { value in
                result1 = value
                // Check completion after handling the first promise
                checkCompletion()
            }

            // Handle the second promise
            handlePromise(promise2) { value in
                result2 = value
                // Check completion after handling the second promise
                checkCompletion()
            }

            // Handle the third promise
            handlePromise(promise3) { value in
                result3 = value
                // Check completion after handling the third promise
                checkCompletion()
            }
        }
    }
    
    
    // timeout方法，添加Promise的超时处理逻辑
    public func timeout<U>(seconds: TimeInterval, onTimeout: @escaping () -> U) -> PromiseV<U> {
        // 添加超时处理逻辑
        let newPromise = PromiseV<U> { _, _ in }
        DispatchQueue.global().asyncAfter(deadline: .now() + seconds) {
            if case .pending = self.state {
                self.state = .rejected(NSError(domain: "Promise", code: 1, userInfo: [NSLocalizedDescriptionKey: "Promise timed out"]))
                _ = onTimeout()
            }
        }
        return newPromise
    }

    // cancel方法，添加取消Promise的逻辑
    public func cancel<U>() -> PromiseV<U> {
        // 添加取消Promise的逻辑
        let newPromise = PromiseV<U> { _, _ in }
        // Your cancellation logic here
        return newPromise
    }

    // checkState方法，添加获取Promise当前状态的逻辑
    public func checkState<U>() -> PromiseState<U> {
        // 添加获取Promise当前状态的逻辑
        return state as! PromiseState<U> // Assumes a safe cast, adjust as needed
    }

}

public protocol PromiseConvertible {
    func asAnyPromise() -> PromiseV<Any>
}

extension PromiseV: PromiseConvertible {
    public func asAnyPromise() -> PromiseV<Any> {
        return self.then({ value in
            return value as Any
        })
    }
}



/*
 
 模型1:
 
 let promise = PromiseV<[CustomGetResponse]> { resolve, reject in
     // 异步操作，成功时调用resolve，失败时调用reject
     polars(requestArray: .weather, object: CustomGetResponse.self)
         .subscribe(onSuccess: { (response) in
             // 处理成功的响应
             resolve(response)
         }, onError: { (error) in
             reject(error)
         })
         .disposed(by: self.rx.disposeBag)
 }
 
 方法一:
 promise.then { value in
     // 处理成功回调
     XLog.breakpoint(value, title: "响应1 success")
 }.catch { error in
     XLog.breakpoint(error, title: "响应1 error")
 }
 
 方法二:
 promise.then { value in
     XLog.breakpoint(value, title: "响应2 success")
 } onRejected: { error in
     XLog.breakpoint(error, title: "响应2 error")
 }
 
 
 模型2:
 
 let promise_0 = PromiseV<[CustomGetResponse]> { resolve, reject in
     // 异步操作，成功时调用resolve，失败时调用reject
     polars(requestArray: .weather, object: CustomGetResponse.self)
         .subscribe(onSuccess: { (response) in
             // 处理成功的响应
             resolve(response)
         }, onError: { (error) in
             reject(error)
         })
         .disposed(by: self.rx.disposeBag)
 }
 
 let promise_1 = PromiseV<String?> { resolve, reject in
     // 模拟异步操作，成功时调用resolve，失败时调用reject
     if let image = "11111".toImageAssets {
         polars(upload: .tupian, image: image, fileType: .init(name: "feifei", fileName: "feifei.jpg", mimeType: "image/jpeg"))
             .subscribe(onSuccess: { (response) in
                 // 处理成功的响应
                 resolve(response)
             }, onError: { (error) in
                 reject(error)
             })
             .disposed(by: self.rx.disposeBag)
     }
 }
 
 方法三:
 let promise = PromiseV<([CustomGetResponse], String?)>.thenZip(promise_0, promise_1) { (model, string) in
     XLog.breakpoint("", title: "------- promise then ------- ")
     XLog.breakpoint(model, title: "promise then model-- ")
     XLog.breakpoint(string, title: "promise then string-- ")
 } onRejected: { error in
     XLog.breakpoint(error, title: "响应3 error")
 }
 
 方法四:
 let wait = PromiseV<([CustomGetResponse], String?)>.waitAll(promises: promise) {
     XLog.breakpoint("我完成了", title: "promise then waitAll--")
 }
 
 */
