# PromiseV

PromiseV is a lightweight and powerful Swift library that simplifies asynchronous programming with chainable promises. It provides a clean and type-safe way to handle asynchronous tasks, manage errors, and combine multiple promises.

## Features

- **Promise State Management**: Supports `pending`, `fulfilled`, and `rejected` states.
- **Chaining**: Use `then` and `catch` for clean and flexible chaining of asynchronous tasks.
- **Error Handling**: Built-in error propagation with type-safe handling.
- **Promise Combination**: Combine multiple promises using `zip` and `wait`.
- **Timeouts**: Add timeout logic to ensure tasks complete within a specific time.
- **Cancellation**: Optional support for canceling tasks.
- **Progress Updates**: Track and notify task progress.

## Usage

### Basic

```swift
let promise = PromiseV<Int> { resolve, reject, _ in
    DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
        resolve(42)
    }
}


promise.then { value in
    print("Promise fulfilled with value: \(value)")
}.catch { error in
    print("Promise rejected with error: \(error)")
}


promise.then { value in
	print("Promise fulfilled with value: \(value)")
} onRejected: { error in
	print("Promise rejected with error: \(error)")
}

```

### Zip

```swift
let promise1 = PromiseV<[Int]> { resolve, reject, _ in
    DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
        resolve([42, 1])
    }
}
        
let promise2 = PromiseV<String> { resolve, reject, _ in
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

```

### Combining Wait

```swift
let promise1 = PromiseV<Int> { resolve, reject, _ in
    DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
        resolve(42)
    }
}

let promise2 = PromiseV<String> { resolve, reject, _ in
    DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
        resolve("Hello")
    }
}

let promise3 = PromiseV<Bool> { resolve, reject, _ in
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

```

### Add Timeouts

```swift
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

```

### Add Timeouts (Zip)

```swift
let promise1 = PromiseV<Int> { resolve, reject, _ in
    DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
        resolve(42)
    }
}

let promise2 = PromiseV<String> { resolve, reject, _ in
    DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
        resolve("Hello")
    }
}

let promise3 = PromiseV<Bool> { resolve, reject, _ in
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

```

### PromiseV Links*

```swift
let promise = PromiseV<[Int]> { resolve, reject, _ in
    DispatchQueue.global().asyncAfter(deadline: .now() + 3.0) {
        let mockResponse = [1, 2, 3]
        resolve(mockResponse)
    }
}.timeout(seconds: 5)

promise.then { value in
    
    print("Step 1 [then]: \(value)")
    
    return PromiseV<String> { resolve, reject, _ in
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
            let mockUploadResponse = "UploadedImageID_12345"
            resolve(mockUploadResponse)
        }
    }.timeout(seconds: 3).then { value1 in
        
        print("Step 2 [then]: \(value1)")
        
        return PromiseV<Void> { resolve, reject, _ in
            
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

```

### Cancel

```swift
let promise = PromiseV<Int> { resolve, reject, _ in
    DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
        resolve(100)
    }
}

DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
    promise.cancel()
}

promise
    .onCancel {
        print("Task was cancelled")
    }
    .then { value in
        print("Task completed with value: \(value)")
    }
    .catch { error in
        print("Task failed with error: \(error)")
    }

```

### Progress 100%

```swift
let promise = PromiseV<Float> { resolve, reject, progress in
    // 模拟异步任务
    DispatchQueue.global().async {
        for i in 0..<10 {
            Thread.sleep(forTimeInterval: 0.5)
            let currentProgress = Float(i + 1) / 10.0
            progress(currentProgress) // 报告进度
        }
        resolve(100) // 完成任务
    }
}

promise
    .onProgress { progress in
        print("进度: \(progress * 100)%")
    }
    .then { value in
        print("Task completed with value: \(value)")
    }
    .catch { error in
        print("Task failed with error: \(error)")
    }

```

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests to help improve PromiseV.

## Author

marst123, tianlan2325@qq.com

## License

PromiseV is available under the MIT license. See the [LICENSE][1] file for more information.


[1]:	LICENSE
