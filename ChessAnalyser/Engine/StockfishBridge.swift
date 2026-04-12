import Foundation

/// Swift wrapper around the C Stockfish interface.
/// Calls into StockfishWrapper.h functions via the bridging header.
final class StockfishBridge: @unchecked Sendable {
    private var isInitialized = false
    private let lock = NSLock()

    func initialize() throws {
        lock.lock()
        defer { lock.unlock() }
        guard !isInitialized else { return }
        CrashLogger.logEngine("StockfishBridge.initialize() starting")

        // Pass the bundle resource path so Stockfish can find NNUE files.
        // Stockfish derives the NNUE search directory from argv[0].
        let resourcePath = Bundle.main.resourcePath ?? Bundle.main.bundlePath
        let result = resourcePath.withCString { ptr in
            stockfish_init(ptr)
        }
        guard result == 0 else {
            throw StockfishError.initializationFailed
        }
        isInitialized = true
    }

    func send(command: String) {
        lock.lock()
        let initialized = isInitialized
        lock.unlock()
        guard initialized else { return }
        command.withCString { ptr in
            stockfish_command(ptr)
        }
    }

    func readLine() -> String? {
        lock.lock()
        let initialized = isInitialized
        lock.unlock()
        guard initialized else { return nil }
        guard let ptr = stockfish_read_line() else { return nil }
        let line = String(cString: ptr)
        free(ptr)
        return line
    }

    func isOutputAvailable() -> Bool {
        lock.lock()
        let initialized = isInitialized
        lock.unlock()
        guard initialized else { return false }
        return stockfish_output_available() != 0
    }

    func shutdown() {
        lock.lock()
        defer { lock.unlock() }
        guard isInitialized else { return }
        stockfish_shutdown()
        isInitialized = false
    }

    deinit {
        shutdown()
    }
}

enum StockfishError: Error, LocalizedError {
    case initializationFailed
    case engineNotReady
    case analysisTimeout
    case invalidPosition

    var errorDescription: String? {
        switch self {
        case .initializationFailed: return "Failed to initialize Stockfish engine"
        case .engineNotReady: return "Engine is not ready"
        case .analysisTimeout: return "Analysis timed out"
        case .invalidPosition: return "Invalid position"
        }
    }
}
