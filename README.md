PerfectBlink
=================================

[![Twitter](https://img.shields.io/badge/twitter-@Digipolitan-blue.svg?style=flat)](http://twitter.com/Digipolitan)

Perfect Blink middleware swift is a request parser

Parse incoming request body, query, url parameters before the route handler, data available under the context.blink.

## Installation

### Swift Package Manager

To install PerfectBlink with SPM, add the following lines to your `Package.swift`.

```swift
import PackageDescription

let package = Package(
    name: "XXX",
    dependencies: [
        .Package(url: "https://github.com/Digipolitan/perfect-blink-swift.git", majorVersion: 1)
    ]
)
```

## The Basics

Create a RouterMiddleware and register the blink middleware before all routes handlers

```swift
let server = HTTPServer()

let router = RouterMiddleware()

router.use(event: .beforeAll, middleware: Blink.shared)

router.post(path: "/").bind { (context) in
  guard let body = context.blink.body as? [String: Any],
        let name = body["name"] as? String else {
        context.next()
        return
    }
    context.response.setBody(string: name).completed()
    context.next()
}

server.use(router: router)

server.serverPort = 8887

do {
    try server.start()
    print("Server listening on port \(server.serverPort)")
} catch PerfectError.networkError(let err, let msg) {
    print("Network error thrown: \(err) \(msg)")
}
```

It's possible to register a specific type to parse for only one route as follow :
```swift
router.post(path: "/")
  .bind(Blink.shared.json())
  .bind { (context) in
    guard let body = context.blink.body as? [String: Any] {
      context.next()
      return
    }
    print(body)
    context.next()
}
```

You can parse query parameters and url parameters for only one route as follow :
```swift
router.get(path: "/")
  .bind(Blink.shared.query())
  .bind(Blink.shared.params())
  .bind { (context) in
    guard let query = context.blink.query,
      let name = query["name"] {
      context.next()
      return
    }
    context.response.setBody(string: name).completed()
    context.next()
}
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for more details!

This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md).
By participating, you are expected to uphold this code. Please report
unacceptable behavior to [contact@digipolitan.com](mailto:contact@digipolitan.com).

## License

PerfectBlink is licensed under the [BSD 3-Clause license](LICENSE).
