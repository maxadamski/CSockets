
public indirect enum Error: ErrorProtocol {
	case GetAddressInfoError(Error)
	case GetNameInfoError(Error)
	
	case SetSocketOptionError(Error)
	case GetSocketOptionError(Error)
	
	case CreateError(Error)
	case ConnectError(Error)
	case BindError(Error)
	case ListenError(Error)
	case AcceptError(Error)
	case ReceiveError(Error)
	case SendError(Error)
	case ShutdownError(Error)
	case CloseError(Error)
	
	case Unknown(message: String)
}
