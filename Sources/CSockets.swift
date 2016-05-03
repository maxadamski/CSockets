
#if os(Linux)
	import Glibc
#else
	import Darwin
#endif

public typealias CSocketAddressStorage = sockaddr_storage
public typealias CSocketAddress = sockaddr
public typealias CAddressInfo = addrinfo
public typealias Byte = CChar

public enum AddressFamily {
	case Inet6, Inet, Unspecified
	
	public var cValue: Int32 {
		switch self {
		case .Unspecified: return AF_UNSPEC
		case .Inet6: return AF_INET6
		case .Inet: return AF_INET
		}
	}
	
	public var length: Int32 {
		switch self {
		case .Inet6: return INET6_ADDRSTRLEN
		case .Inet: return INET_ADDRSTRLEN
		default: return 0
		}
	}
}

public enum SocketType {
	case Stream, Datagram, Raw
	
	public var cValue: Int32 {
		switch self {
		case .Datagram: return SOCK_DGRAM
		case .Stream: return SOCK_STREAM
		case .Raw: return SOCK_RAW
		}
	}
}

public enum ShutdownMode {
	case ReadWrite, Read, Write
	
	public var cValue: Int32 {
		switch self {
		case .ReadWrite: return SHUT_RDWR
		case .Write: return SHUT_WR
		case .Read: return SHUT_RD
		}
	}
}

public enum SocketOption {
	case ReuseAddress(Bool)
	case KeepAlive(Bool)
	case ReceiveBufferSize(Int)
	case SendBufferSize(Int)
	case OOBInline(Bool)
}

public struct MessageOptions: OptionSet {
	public var rawValue: Int32
	public init(rawValue: Int32) {
		self.rawValue = rawValue
	}
	
	public static let DontWait = MessageOptions(rawValue: MSG_DONTWAIT)
	public static let WaitAll = MessageOptions(rawValue: MSG_WAITALL)
	public static let Trunc = MessageOptions(rawValue: MSG_TRUNC)
	public static let Peek = MessageOptions(rawValue: MSG_PEEK)
	public static let OOB = MessageOptions(rawValue: MSG_OOB)
}

public struct NameLookupOptions: OptionSet {
	public var rawValue: Int32
	public init(rawValue: Int32) {
		self.rawValue = rawValue
	}
	
	public static let NumericService = NameLookupOptions(rawValue: NI_NUMERICSERV)
	public static let NumericHost = NameLookupOptions(rawValue: NI_NUMERICHOST)
}

// MARK: - Address Lookup

public func getaddrinfo(host: String? = nil, service: String, hints: CAddressInfo) throws -> [CAddressInfo] {
	var info: UnsafeMutablePointer<CAddressInfo>? = nil
	var addresses = [CAddressInfo]()
	var hintsCopy = hints
	let status: Int32
	
	if let host = host {
		status = getaddrinfo(host, service, &hintsCopy, &info)
	} else {
		status = getaddrinfo(nil, service, &hintsCopy, &info)
	}
	
	while let i = info?.pointee {
		addresses.append(i)
		info = i.ai_next
	}
	
	freeaddrinfo(info)
	
	guard status != -1 else {
		let message = String(cString: gai_strerror(status))
		throw Error.GetAddressInfoError(.Unknown(message: message))
	}
	
	return addresses
}

public func getnameinfo(address: CSocketAddressStorage, options: Int32) throws -> (host: String, service: String) {
	var addrcopy = address
	let addrptr = withUnsafeMutablePointer(&addrcopy) { return UnsafeMutablePointer<sockaddr>($0) }
	var host = [Byte](repeating: 0, count: Int(NI_MAXHOST))
	var serv = [Byte](repeating: 0, count: Int(NI_MAXSERV))
	let addrlen = UInt32(address.ss_len)
	let hostlen = UInt32(host.capacity)
	let servlen = UInt32(serv.capacity)
	let status = getnameinfo(addrptr, addrlen, &host, hostlen, &serv, servlen, options)
	guard status == 0 else {
		let message = String(cString: gai_strerror(status))
		throw Error.GetNameInfoError(.Unknown(message: message))
	}
	return (String(cString: host), String(cString: serv))
}

public func getnameinfo(address: CSocketAddressStorage, options: NameLookupOptions = []) throws -> (host: String, service: String) {
	return try getnameinfo(address: address, options: options.rawValue)
}

// MARK: - Options

public func setsockopt<T>(socket s: Int32, level: Int32, option: Int32, value: T) throws {
	let length = UInt32(sizeof(T))
	var valueCopy = value
	let status = setsockopt(s, level, option, &valueCopy, length)
	guard status != -1 else { throw Error.SetSocketOptionError(Error()) }
}

public func getsockopt<T>(socket s: Int32, level: Int32, option: Int32, type: T.Type) throws -> T? {
	var length = UInt32(sizeof(T))
	var value: T? = nil
	let status = getsockopt(s, level, option, &value, &length)
	guard status != -1 else { throw Error.GetSocketOptionError(Error()) }
	return value
}

public func setsockopt(socket s: Int32, option: SocketOption) throws {
	switch option {
	case .ReuseAddress(let v):
		let value: Int32 = v == true ? 1 : 0
		try setsockopt(socket: s, level: SOL_SOCKET, option: SO_REUSEADDR, value: value)
	case .KeepAlive(let v):
		let value: Int32 = v == true ? 1 : 0
		try setsockopt(socket: s, level: SOL_SOCKET, option: SO_KEEPALIVE, value: value)
	case .ReceiveBufferSize(let v):
		try setsockopt(socket: s, level: SOL_SOCKET, option: SO_RCVBUF, value: Int32(v))
	case .SendBufferSize(let v):
		try setsockopt(socket: s, level: SOL_SOCKET, option: SO_SNDBUF, value: Int32(v))
	case .OOBInline(let v):
		let value: Int32 = v == true ? 1 : 0
		try setsockopt(socket: s, level: SOL_SOCKET, option: SO_OOBINLINE, value: value)
	}
}

// MARK: - Socket Factory

public func socket(family: Int32, type: Int32, proto: Int32) throws -> Int32 {
	let fd = socket(family, type, proto)
	guard fd > 0 else { throw Error.CreateError(Error()) }
	return fd
}

public func socket(family: AddressFamily, type: SocketType) throws -> Int32 {
	return try socket(family: family.cValue, type: type.cValue, proto: family.cValue)
}

public func socket(info: CAddressInfo) throws -> Int32 {
	return try socket(family: info.ai_family, type: info.ai_socktype, proto: info.ai_protocol)
}


// MARK: - Shutdown & Close

public func shutdown(socket s: Int32, mode: Int32) throws {
	let status = shutdown(s, mode)
	guard status > -1 else { throw Error.ShutdownError(Error()) }
}

public func shutdown(socket s: Int32, mode: ShutdownMode) throws {
	try shutdown(socket: s, mode: mode.cValue)
}

public func close(socket s: Int32) throws {
	let status = close(s)
	guard status == 0 else { throw Error.CloseError(Error()) }
}

// MARK: - Receive

public func recv(socket s: Int32, count: Int, options: Int32 = 0) throws -> [Byte] {
	var buffer = [CChar](repeating: 0, count: count)
	let received = recv(s, &buffer, buffer.capacity, options)
	guard received > -1 else { throw Error.ReceiveError(Error()) }
	return Array(buffer[0..<received])
}

public func recv(socket s: Int32, count: Int, options: MessageOptions = []) throws -> [Byte] {
	return try recv(socket: s, count: count, options: options.rawValue)
}

/// - warning: Result is not null terminated. Before converting into a string append a zero.
public func recv(socket s: Int32, chunkLength: Int = 128, options: Int32) throws -> [Byte] {
	var bytes = [Int8]()
	while true {
		let chunk = try recv(socket: s, count: chunkLength, options: options)
		bytes += chunk
		if chunk.count < chunkLength {
			break
		}
	}
	return bytes
}

public func recv(socket s: Int32, chunkLength: Int = 128, options: MessageOptions = []) throws -> [Byte] {
	return try recv(socket: s, chunkLength: chunkLength, options: options.rawValue)
}

// MARK: - Send

public func send(socket s: Int32, bytes: [Byte], options: Int32) throws {
	let sent = send(s, bytes, bytes.count, options)
	guard sent == bytes.count else { throw Error.SendError(Error()) }
}

public func send(socket s: Int32, bytes: [Byte], options: MessageOptions = []) throws {
	try send(socket: s, bytes: bytes, options: options.rawValue)
}

// MARK: - Server Socket

public func listen(socket s: Int32, backlog: Int) throws {
	let status = listen(s, Int32(backlog))
	guard status > -1 else { throw Error.ListenError(Error()) }
}

public func bind(socket s: Int32, info: CAddressInfo) throws {
	let status = bind(s, info.ai_addr, info.ai_addrlen)
	guard status > -1 else { throw Error.BindError(Error()) }
}

/// - returns:
///		- socket: Descriptor of the accepted socket
///		- address: Address of the accepted socket
public func accept(socket s: Int32) throws -> (socket: Int32, address: CSocketAddressStorage) {
	var length = UInt32(sizeof(CSocketAddressStorage))
	var address = CSocketAddressStorage()
	let pointer = withUnsafeMutablePointer(&address) { UnsafeMutablePointer<sockaddr>($0) }
	let client = accept(s, pointer, &length)
	guard client > -1 else { throw Error.AcceptError(Error()) }
	return (client, address)
}

// MARK: - Client Socket

public func connect(socket s: Int32, info: CAddressInfo) throws {
	let status = connect(s, info.ai_addr, info.ai_addrlen)
	guard status > -1 else { throw Error.ConnectError(Error()) }
}

// MARK: - Helpers

public extension CSocketAddressStorage {
	public init(address: CSocketAddress) {
		var copy = address
		self = withUnsafeMutablePointer(&copy) {
			UnsafeMutablePointer<CSocketAddressStorage>($0).pointee
		}
	}
	
	public var asSockaddrIn6: sockaddr_in6 {
		var address = self
		return withUnsafeMutablePointer(&address) {
			UnsafeMutablePointer<sockaddr_in6>($0).pointee
		}
	}
	
	public var asSockaddrIn: sockaddr_in {
		var address = self
		return withUnsafeMutablePointer(&address) {
			UnsafeMutablePointer<sockaddr_in>($0).pointee
		}
	}
}

public extension CAddressInfo {
	public init(builder: (inout CAddressInfo) -> Void) {
		var object = CAddressInfo()
		builder(&object)
		self = object
	}
}

extension Error {
	init() {
		switch errno {
		default:
			let error = String(cString: strerror(errno)) ?? ""
			self = .Unknown(message: "<Error \(errno)>: \(error)")
		}
	}
}
