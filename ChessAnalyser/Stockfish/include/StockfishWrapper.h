#ifndef StockfishWrapper_h
#define StockfishWrapper_h

#ifdef __cplusplus
extern "C" {
#endif

/// Initialize the Stockfish engine.
/// @param resourcePath Path to the directory containing NNUE files.
///        Pass NULL to use the default (current directory).
/// Returns 0 on success, non-zero on failure.
int stockfish_init(const char* resourcePath);

/// Send a UCI command to the engine.
void stockfish_command(const char* command);

/// Read the next line of output from the engine.
/// Returns a newly allocated string that the caller must free(),
/// or NULL if no output is currently available.
char* stockfish_read_line(void);

/// Check if there is output available from the engine (non-blocking).
int stockfish_output_available(void);

/// Shut down the Stockfish engine and free resources.
void stockfish_shutdown(void);

#ifdef __cplusplus
}
#endif

#endif /* StockfishWrapper_h */
