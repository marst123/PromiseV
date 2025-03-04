/*
 这段代码是一个用Swift语言实现的Promise模式库。
 它提供了一种异步编程的范式，允许开发者更清晰地处理异步操作和链式调用。
 在使用上，开发者可以创建Promise对象，通过then、catch等方法添加回调，以及通过wait、then等方法处理多个Promise的情况。
 
 
 
 */

import Foundation

/// 表示 Promise 状态
/// - pending: 初始状态，尚未完成或被拒绝
/// - fulfilled: 已完成状态，携带结果值
/// - rejected: 已拒绝状态，携带错误信息
/// - cancelled: 取消状态
public enum PromiseState<T> {
    case pending
    
    case fulfilled(T)
    
    case rejected(Error)
    
    case cancelled  // 新增明确取消状态
}


public class PromiseV<T> {
    
    // MARK: - 私有属性
    
    /// 当前 Promise 的状态
    private var state: PromiseState<T> = .pending
    
    /// 成功回调队列
    private var onFulfilled: [(T) -> Void] = []
    
    /// 失败回调队列
    private var onRejected: [(Error) -> Void] = []

    /// 取消回调队列
    private var onCancel: [() -> Void] = []
    
    /// 进度回调队列
    private var onProgress: [(Float) -> Void] = []
    
    /// 并发队列
    private let queue = DispatchQueue(label: "com.example.promiseQueue", attributes: .concurrent)

    // MARK: - 初始化
    
    /// 初始化 Promise 并立即执行执行器
    /// - Parameter executor: 执行器函数，接收 resolve 和 reject 两个回调；扩展 progress 回调
    /// - Note: 执行器函数应正确处理异步操作，在适当时候调用 resolve/reject
    
    public init(
        _ executor: (
            @escaping (T) -> Void, // resolve
            @escaping (Error) -> Void, // reject
            @escaping (Float) -> Void // progress
        ) -> Void
    ) {
        executor({ value in
            self.queue.async(flags: .barrier) {
                self.handleFulfillment(value)
            }
        }, { error in
            self.queue.async(flags: .barrier) {
                self.handleRejection(error)
            }
        }, { progress in
            self.queue.async(flags: .barrier) {
                self.handleProgress(progress)
            }
        })
    }
    
    // MARK: - 状态处理方法
    
    /// 处理完成
    private func handleFulfillment(_ value: T) {
        queue.async(flags: .barrier) {
            guard case .pending = self.state else { return }
            
            self.state = .fulfilled(value)
            let callbacks = self.onFulfilled
            self.cleanup()
            
            for callback in callbacks {
                callback(value)
            }
        }
    }

    /// 处理拒绝
    private func handleRejection(_ error: Error) {
        queue.async(flags: .barrier) {
            guard case .pending = self.state else { return }
            
            self.state = .rejected(error)
            let callbacks = self.onRejected
            self.cleanup()
            
            for callback in callbacks {
                callback(error)
            }
        }
    }
    
    /// 处理进度
    private func handleProgress(_ progress: Float) {
        queue.async(flags: .barrier) {
            guard case .pending = self.state else { return }
            
            for callback in self.onProgress {
                callback(progress)
            }
        }
    }
    
    /// 清空队列
    private func cleanup() {
        onFulfilled.removeAll()
        onRejected.removeAll()
        onProgress.removeAll()
        onCancel.removeAll()
    }
    
    // MARK: - 核心方法

    /// then处理方法（只处理成功回调，不处理错误）
    /// - 参数 onFulfilled: 转换成功值的闭包
    /// - 返回: 新的 Promise<U> 实例
    /// - Note: 错误会自动向下传递
    public func then<U>(_ onFulfilled: @escaping (T) -> U) -> PromiseV<U> {
        return then(onFulfilled: onFulfilled, onRejected: { throw $0 })
    }

    /// then处理方法
    /// - 参数 onFulfilled: 转换成功值的闭包（可能抛出异常）
    /// - 参数 onRejected: 处理错误的闭包（可能抛出异常）
    /// - 返回: 新的 Promise<U> 实例
    /// - Important: 当原 Promise 已完成时立即执行回调，否则存储回调
    public func then<U>(
        onFulfilled: @escaping (T) throws -> U,
        onRejected: @escaping (Error) throws -> Void
    ) -> PromiseV<U> {
        return PromiseV<U> { resolve, reject, _  in
            self.queue.async {
                switch self.state {
                case .fulfilled(let value):
                    do {
                        let transformedValue = try onFulfilled(value)
                        resolve(transformedValue)
                    } catch {
                        reject(error)
                    }
                case .rejected(let error):
                    do {
                        try onRejected(error)
                        reject(error)
                    } catch {
                        reject(error)
                    }
                case .cancelled:
                    reject(PromiseError.cancelled)
                case .pending:
                    self.onFulfilled.append { value in
                        do {
                            let transformedValue = try onFulfilled(value)
                            resolve(transformedValue)
                        } catch {
                            reject(error)
                        }
                    }
                    self.onRejected.append { error in
                        do {
                            try onRejected(error)
                            reject(error)
                        } catch {
                            reject(error)
                        }
                    }
                }
            }
        }
    }

    /// 错误处理方法
    /// - 参数 onRejected: 转换错误的闭包
    /// - 返回: 新的 Promise<U> 实例
    /// - Important: 如果原 Promise 已完成，直接拒绝并返回类型转换错误
    public func `catch`<U>(_ onRejected: @escaping (Error) throws -> U) -> PromiseV<U> {
        return PromiseV<U> { resolve, reject, _ in
            self.queue.async {
                switch self.state {
                case .fulfilled:
                    reject(PromiseError.invalidState("Promise is already fulfilled"))
                case .rejected(let error):
                    do {
                        let transformedValue = try onRejected(error)
                        resolve(transformedValue)
                    } catch {
                        reject(error)
                    }
                case .cancelled:
                    reject(PromiseError.cancelled)
                case .pending:
                    self.onRejected.append { error in
                        do {
                            let transformedValue = try onRejected(error)
                            resolve(transformedValue)
                        } catch {
                            reject(error)
                        }
                    }
                }
            }
        }
    }

    // MARK: - wait

    /// 等待所有 Promise 完成（无论成功失败）
    /// - 参数 promises: 要等待的 Promise 数组
    /// - 参数 completion: 完成回调
    /// - 返回: 包含所有结果的 Promise
    /// - Note: 结果顺序与输入顺序一致，包含成功/失败的结果
    public static func wait<T>(
        promises: [PromiseV<T>],
        completion: @escaping ([Result<T, Error>]) -> Void
    ) -> PromiseV<[Result<T, Error>]> {
        return PromiseV<[Result<T, Error>]> { resolve, _, _ in
            let lockQueue = DispatchQueue(label: "com.example.promiseWaitAllLock")
            var results: [Result<T, Error>] = Array(repeating: .failure(PromiseError.pending), count: promises.count)
            var completedCount = 0

            func handleCompletion() {
                lockQueue.sync {
                    completedCount += 1
                    if completedCount == promises.count {
                        DispatchQueue.main.async {
                            completion(results)
                            resolve(results)
                        }
                    }
                }
            }

            for (index, promise) in promises.enumerated() {
                promise.then { value in
                    lockQueue.sync { results[index] = .success(value) }
                    handleCompletion()
                }.catch { error in
                    lockQueue.sync { results[index] = .failure(error) }
                    handleCompletion()
                }
            }
        }
    }
    
    // MARK: - zip
    
    /// 组合两个 Promise
    public static func zip<T1, T2>(
        _ p1: PromiseV<T1>,
        _ p2: PromiseV<T2>
    ) -> PromiseV<(T1, T2)> {
        return PromiseV<(T1, T2)> { resolve, reject, _ in
            let lockQueue = DispatchQueue(label: "com.example.promiseZipLock")
            var result1: T1?
            var result2: T2?
            var isCompleted = false
            
            // 统一处理完成逻辑
            func handleCompletion() {
                lockQueue.sync {
                    guard !isCompleted else { return }
                    if let result1, let result2 {
                        isCompleted = true
                        resolve((result1, result2))
                    }
                }
            }
            
            // 统一处理错误逻辑
            func handleError(_ error: Error) {
                lockQueue.sync {
                    guard !isCompleted else { return }
                    isCompleted = true
                    reject(error)
                }
            }
            
            // 订阅每个 Promise 的结果
            p1.then { value in
                lockQueue.sync { result1 = value }
                handleCompletion()
            }.catch { error in
                handleError(error)
            }
            
            p2.then { value in
                lockQueue.sync { result2 = value }
                handleCompletion()
            }.catch { error in
                handleError(error)
            }
        }
    }
    
    /// 组合三个 Promise
    public static func zip<T1, T2, T3>(
        _ p1: PromiseV<T1>,
        _ p2: PromiseV<T2>,
        _ p3: PromiseV<T3>
    ) -> PromiseV<(T1, T2, T3)> {
        return PromiseV<(T1, T2, T3)> { resolve, reject, _ in
            let lockQueue = DispatchQueue(label: "com.example.promiseZipLock")
            var result1: T1?
            var result2: T2?
            var result3: T3?
            var isCompleted = false
            
            // 统一处理完成逻辑
            func handleCompletion() {
                lockQueue.sync {
                    guard !isCompleted else { return }
                    if let result1, let result2, let result3 {
                        isCompleted = true
                        resolve((result1, result2, result3))
                    }
                }
            }
            
            // 统一处理错误逻辑
            func handleError(_ error: Error) {
                lockQueue.sync {
                    guard !isCompleted else { return }
                    isCompleted = true
                    reject(error)
                }
            }
            
            // 订阅每个 Promise 的结果
            p1.then { value in
                lockQueue.sync { result1 = value }
                handleCompletion()
            }.catch { error in
                handleError(error)
            }
            
            p2.then { value in
                lockQueue.sync { result2 = value }
                handleCompletion()
            }.catch { error in
                handleError(error)
            }
            
            p3.then { value in
                lockQueue.sync { result3 = value }
                handleCompletion()
            }.catch { error in
                handleError(error)
            }
        }
    }
    
    /// 组合四个 Promise
    public static func zip<T1, T2, T3, T4>(
        _ p1: PromiseV<T1>,
        _ p2: PromiseV<T2>,
        _ p3: PromiseV<T3>,
        _ p4: PromiseV<T4>
    ) -> PromiseV<(T1, T2, T3, T4)> {
        return PromiseV<(T1, T2, T3, T4)> { resolve, reject, _ in
            let lockQueue = DispatchQueue(label: "com.example.promiseZipLock")
            var result1: T1?
            var result2: T2?
            var result3: T3?
            var result4: T4?
            var isCompleted = false

            func handleCompletion() {
                lockQueue.sync {
                    guard !isCompleted else { return }
                    if let result1, let result2, let result3, let result4 {
                        isCompleted = true
                        resolve((result1, result2, result3, result4))
                    }
                }
            }

            func handleError(_ error: Error) {
                lockQueue.sync {
                    guard !isCompleted else { return }
                    isCompleted = true
                    reject(error)
                }
            }

            p1.then { value in
                lockQueue.sync { result1 = value }
                handleCompletion()
            }.catch { error in
                handleError(error)
            }

            p2.then { value in
                lockQueue.sync { result2 = value }
                handleCompletion()
            }.catch { error in
                handleError(error)
            }

            p3.then { value in
                lockQueue.sync { result3 = value }
                handleCompletion()
            }.catch { error in
                handleError(error)
            }

            p4.then { value in
                lockQueue.sync { result4 = value }
                handleCompletion()
            }.catch { error in
                handleError(error)
            }
        }
    }

    // MARK: - 超时处理
    
    /// 任务超时处理
    public func timeout(seconds: TimeInterval) -> PromiseV<T> {
        return PromiseV<T> {[self] resolve, reject, _ in
            let timer = DispatchSource.makeTimerSource(queue: self.queue)
            timer.schedule(deadline: .now() + seconds)
            
            let lock = NSLock()
            var timedOut = false
            
            // 超时处理闭包
            let timeoutHandler = { [weak self] in
                lock.lock()
                defer { lock.unlock() }
                guard !timedOut else { return }
                timedOut = true
                
                self?.queue.async(flags: .barrier) {
                    guard case .pending = self?.state else { return }
                    
                    // 触发取消逻辑并传递超时错误
                    self?.triggerCancellation(error: PromiseError.timeout)
                    reject(PromiseError.timeout)
                }
            }
            
            timer.setEventHandler(handler: timeoutHandler)
            timer.resume()
            
            // 订阅原Promise的结果
            self.then { value in
                lock.lock()
                defer { lock.unlock() }
                guard !timedOut else { return }
                
                timer.cancel()
                resolve(value)
            }.catch { error in
                lock.lock()
                defer { lock.unlock() }
                guard !timedOut else { return }
                
                timer.cancel()
                reject(PromiseError.other(error))
            }
        }
    }

    // 修改triggerCancellation以支持错误传递
    private func triggerCancellation(error: Error) {
        queue.async(flags: .barrier) {
            guard case .pending = self.state else { return }
            
            self.state = .cancelled
            self.cleanup()
            self.triggerCancelCallbacks()
            
            // 传递取消原因到onRejected队列（可选）
            let cancellationError = PromiseError.cancelled
            self.onRejected.forEach { $0(cancellationError) }
        }
    }

    
    // MARK: - 进度处理 （用于上传/下载的特殊任务）
    
    /// 进度回调事件
    @discardableResult
    public func onProgress(_ callback: @escaping (Float) -> Void) -> Self {
        queue.async(flags: .barrier) {
            self.onProgress.append(callback)
        }
        return self
    }

    
    // MARK: - 取消处理
    
    /// 取消
    public func cancel() {
        queue.async(flags: .barrier) {
            guard case .pending = self.state else { return }
            self.state = .cancelled
            let cancelCallbacks = self.onCancel
            self.cleanup()
            
            for callback in cancelCallbacks {
                callback()
            }
        }
    }

    
    /// 取消回调
    @discardableResult
    public func onCancel(_ handler: @escaping () -> Void) -> Self {
        queue.async(flags: .barrier) {
            if case .cancelled = self.state {
                handler()
            } else {
                self.onCancel.append(handler)
            }
        }
        return self
    }

    
    /// 触发所有取消回调
    private func triggerCancelCallbacks() {
        let callbacks = onCancel
        DispatchQueue.global().async {
            for callback in callbacks {
                callback()
            }
        }
    }

    // MARK: - 获取: 当前状态
    
    /// 获取当前状态
    /// - Warning: 由于状态可能在后台队列修改，获取的状态可能不是最新的
    public func checkState() -> PromiseState<T> {
        return queue.sync {
            self.state
        }
    }
}

public protocol PromiseConvertible {
    func asAnyPromise() -> PromiseV<Any>
}

extension PromiseV: PromiseConvertible {
    public func asAnyPromise() -> PromiseV<Any> {
        return self.then { value in
            return value as Any
        }
    }
}

/// 定义统一的Promise错误类型

public enum PromiseError: Error {
    case timeout
    case cancelled
    case invalidState(String)
    case pending
    case other(Error)
}

extension PromiseError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .timeout:
            return "Operation timed out."
        case .cancelled:
            return "Operation was cancelled."
        case .invalidState(let message):
            return "Invalid state: \(message)"
        case .pending:
            return "Operation is still pending."
        case .other(let error):
            return error.localizedDescription
        }
    }
}
