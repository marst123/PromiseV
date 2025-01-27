# PromiseV

PromiseV is a lightweight and powerful Swift library that simplifies asynchronous programming with chainable promises. It provides a clean and type-safe way to handle asynchronous tasks, manage errors, and combine multiple promises.

## Features

- **Promise State Management**: Supports `pending`, `fulfilled`, and `rejected` states.
- **Chaining**: Use `then` and `catch` for clean and flexible chaining of asynchronous tasks.
- **Error Handling**: Built-in error propagation with type-safe handling.
- **Promise Combination**: Combine multiple promises using `thenZip` and `waitAll`.
- **Timeouts**: Add timeout logic to ensure tasks complete within a specific time.
- **Cancellation**: Optional support for canceling tasks.
- **Progress Updates**: Track and notify task progress.

## Usage

### Basic

```swift
let promise = PromiseV<Int> { resolve, reject in
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

### Combining WaitAll

```swift
let promise_Array = PromiseV<[Int]> { resolve, reject in
    DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
        resolve([42, 1])
    }
}

let promise_String = PromiseV<String> { resolve, reject in
    DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
        resolve("YES")
    }
}

let promise = PromiseV<([Int], String)>.thenZip(promise_Array, promise_String) { (array, string) in
    print("------- Promise then -------")
    print("Promise fulfilled with value: \(array)")
    print("Promise fulfilled with value: \(string)")

} onRejected: { error in
    print("Promise rejected with error: \(error)")
}

let wait = PromiseV<([Int], String)>.waitAll(promises: promise) {
    print("Promise waitAll!")
}

```

### Adding Timeouts

```swift
let promise_Array = ...

let promise_String = ...

let promise = promise = PromiseV<([Int], String)>.thenZip(promise_Array, promise_String) { (array, string) in
	...

let wait = PromiseV<([Int], String)>.waitAll(promises: promise) {
    print("Promise waitAll!")
}
```

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests to help improve PromiseV.

## Author

marst123, tianlan2325@qq.com

## License

PromiseV is available under the MIT license. See the [LICENSE][1] file for more information.


[1]:	LICENSE