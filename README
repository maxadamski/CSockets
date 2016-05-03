
![Platform: Linux | OS X](https://img.shields.io/badge/Platform-Linux | OS X-lightgrey.svg)
![Swift Package Manager: compatible](https://img.shields.io/badge/Swift PM-Compatible-green.svg)
![swift: 3.0-dev [April 25, 2016]](https://img.shields.io/badge/Swift-3.0--dev [April 25, 2016]-orange.svg)

# CSockets

CSockets is a binding of the POSIX sockets API (often called Berkeley sockets). It makes sockets programming more digestible for Swift users while retaining the familiarity of the original API. For example CSockets abstracts away inconveniences like pointer casting, linked list pointers and character buffers. To ensure safety, enums and option sets were created to replace C constants and macros. And did I mention that all functions use the Swift 2.2 error handling?

# Example

## Server socket

```Swift
var hints = CAddressInfo()
hints.ai_socktype = SocketType.Stream.cValue
hints.ai_family = AddressFamily.Inet6.cValue

let info = try getaddrinfo(service: "7676", hints: hints).first!
let s = try socket(info: info)

try setsockopt(socket: s, option: .ReuseAddress(true))
try bind(socket: s, info: info)
try listen(socket: s, backlog: 1024)

while true {
  let client = try accept(socket: s).socket
  let request = try recv(socket: client, chunkLength: 128)
  try send(socket: client, bytes: request)
  try close(socket: client)
}
```

## Client socket

```Swift
let request: [CChar] = ...
var hints = CAddressInfo()
hints.ai_socktype = SocketType.Stream.cValue

let info = try getaddrinfo(host: "www.github.com", service: "80", hints: hints).first!
let s = try socket(info: info)

try connect(socket: s, info: info)
try send(socket: s, bytes: request)
let response = try recv(socket: s, chunkLength: 128)
try close(socket: s)
```

# Installation

## Swift Package Manager

Add this to the `dependencies` array in your `Package.swift` file:

```Swift
.Package(url: "https://github.com/maxadamski/CSockets", versions: Version(1,0,0)..<Version(1,1,0))
```

# License

MIT
