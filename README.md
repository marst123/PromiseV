# PromiseV

PromiseV is a lightweight and powerful Swift library that simplifies asynchronous programming with chainable promises. It provides a clean and type-safe way to handle asynchronous tasks, manage errors, and combine multiple promises.

---

## Features

- **Promise State Management**: Supports `pending`, `fulfilled`, and `rejected` states.
- **Chaining**: Use `then` and `catch` for clean and flexible chaining of asynchronous tasks.
- **Error Handling**: Built-in error propagation with type-safe handling.
- **Promise Combination**: Combine multiple promises using `thenZip` and `waitAll`.
- **Timeouts**: Add timeout logic to ensure tasks complete within a specific time.
- **Cancellation**: Optional support for canceling tasks.
- **Progress Updates**: Track and notify task progress.

---

## Installation

### Swift Package Manager (SPM)
Add the following to your `Package.swift` file:

```swift
let package = Package(
    dependencies: [
        .package(url: "https://github.com/your-repo/PromiseV.git", from: "1.0.0")
    ]
)
```

---

## Usage

### Basic Usage

```swift
let promise = PromiseV<Int> { resolve, reject in
    DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
        resolve(42) // Simulate an asynchronous operation
    }
}

promise.then { value in
    print("Promise fulfilled with value: \(value)")
}.catch { error in
    print("Promise rejected with error: \(error)")
}
```

### Combining Promises

```swift
let promise1 = PromiseV<Int> { resolve, _ in resolve(10) }
let promise2 = PromiseV<Int> { resolve, _ in resolve(20) }

PromiseV.thenZip(promise1, promise2) { (value1, value2) in
    print("Combined result: \(value1 + value2)")
}.catch { error in
    print("Error: \(error)")
}
```

### Adding Timeouts

```swift
let promise = PromiseV<Int> { resolve, _ in
    DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
        resolve(42)
    }
}

promise.timeout(seconds: 3, onTimeout: {
    print("Promise timed out")
}).then { value in
    print("Result: \(value)")
}
```

---

## Advanced Features

### Waiting for All Promises

```swift
let promises = [
    PromiseV<Int> { resolve, _ in resolve(1) },
    PromiseV<Int> { resolve, _ in resolve(2) },
    PromiseV<Int> { resolve, _ in resolve(3) }
]

PromiseV.waitAll(promises).then { results in
    print("All promises completed: \(results)")
}.catch { error in
    print("Error: \(error)")
}
```

### Progress Updates

```swift
let promise = PromiseV<Int> { resolve, _ in
    DispatchQueue.global().async {
        for progress in 1...100 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(progress) * 0.01) {
                promise.updateProgress(progress)
            }
        }
        resolve(42)
    }
}

promise.progress { progress in
    print("Progress: \(progress)%")
}.then { value in
    print("Result: \(value)")
}
```

---

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests to help improve PromiseV.

---

## License

PromiseV is available under the MIT license. See the [LICENSE](LICENSE) file for more information.

---

## Contact

For questions or feedback, please reach out to [your-email@example.com](mailto:your-email@example.com).
