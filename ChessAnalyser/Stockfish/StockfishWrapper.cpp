// StockfishWrapper.cpp
//
// C-compatible wrapper around the real Stockfish engine.
// Redirects std::cin/std::cout streambufs to in-memory queues.

#include "include/StockfishWrapper.h"

#include <string>
#include <queue>
#include <mutex>
#include <thread>
#include <condition_variable>
#include <cstring>
#include <cstdlib>
#include <iostream>
#include <atomic>

// Stockfish headers
#include "src/bitboard.h"
#include "src/misc.h"
#include "src/position.h"
#include "src/tune.h"
#include "src/uci.h"

// ─── Thread-safe string queue ───────────────────────────────────────

class ThreadSafeQueue {
public:
    void push(const std::string& value) {
        std::lock_guard<std::mutex> lock(mutex_);
        queue_.push(value);
        cv_.notify_one();
    }

    bool tryPop(std::string& value) {
        std::lock_guard<std::mutex> lock(mutex_);
        if (queue_.empty()) return false;
        value = queue_.front();
        queue_.pop();
        return true;
    }

    bool empty() {
        std::lock_guard<std::mutex> lock(mutex_);
        return queue_.empty();
    }

    bool waitPop(std::string& value, int timeoutMs) {
        std::unique_lock<std::mutex> lock(mutex_);
        if (cv_.wait_for(lock, std::chrono::milliseconds(timeoutMs),
                         [this] { return !queue_.empty(); })) {
            value = queue_.front();
            queue_.pop();
            return true;
        }
        return false;
    }

private:
    std::queue<std::string> queue_;
    mutable std::mutex mutex_;
    std::condition_variable cv_;
};

// ─── Custom streambufs ──────────────────────────────────────────────

class InputStreamBuf : public std::streambuf {
public:
    InputStreamBuf(ThreadSafeQueue& queue) : queue_(queue) {}

protected:
    int_type underflow() override {
        if (gptr() == egptr()) {
            std::string line;
            while (!queue_.waitPop(line, 100)) {
                if (shutdown_.load()) return traits_type::eof();
            }
            line += '\n';
            buffer_ = line;
            setg(&buffer_[0], &buffer_[0], &buffer_[0] + buffer_.size());
        }
        return traits_type::to_int_type(*gptr());
    }

public:
    std::atomic<bool> shutdown_{false};

private:
    ThreadSafeQueue& queue_;
    std::string buffer_;
};

class OutputStreamBuf : public std::streambuf {
public:
    OutputStreamBuf(ThreadSafeQueue& queue) : queue_(queue) {}

protected:
    int_type overflow(int_type ch) override {
        if (ch == '\n') {
            if (!line_.empty()) {
                queue_.push(line_);
            }
            line_.clear();
        } else if (ch != traits_type::eof()) {
            line_ += static_cast<char>(ch);
        }
        return ch;
    }

    std::streamsize xsputn(const char* s, std::streamsize n) override {
        for (std::streamsize i = 0; i < n; ++i) {
            overflow(traits_type::to_int_type(s[i]));
        }
        return n;
    }

    int sync() override {
        if (!line_.empty()) {
            queue_.push(line_);
            line_.clear();
        }
        return 0;
    }

private:
    ThreadSafeQueue& queue_;
    std::string line_;
};

// ─── Global state ───────────────────────────────────────────────────

static ThreadSafeQueue*  g_inputQueue  = nullptr;
static ThreadSafeQueue*  g_outputQueue = nullptr;
static InputStreamBuf*   g_inputBuf    = nullptr;
static OutputStreamBuf*  g_outputBuf   = nullptr;
static std::streambuf*   g_origCinBuf  = nullptr;
static std::streambuf*   g_origCoutBuf = nullptr;
static std::thread*      g_engineThread = nullptr;
static std::atomic<bool> g_initialized{false};
static std::string       g_resourcePath;

// ─── C Interface ────────────────────────────────────────────────────

extern "C" {

int stockfish_init(const char* resourcePath) {
    if (g_initialized.load()) return 0;

    // Store resource path
    if (resourcePath) {
        g_resourcePath = std::string(resourcePath);
        // Ensure trailing slash
        if (!g_resourcePath.empty() && g_resourcePath.back() != '/') {
            g_resourcePath += '/';
        }
    }

    g_inputQueue  = new ThreadSafeQueue();
    g_outputQueue = new ThreadSafeQueue();
    g_inputBuf    = new InputStreamBuf(*g_inputQueue);
    g_outputBuf   = new OutputStreamBuf(*g_outputQueue);

    // Redirect std::cin / std::cout
    g_origCinBuf  = std::cin.rdbuf(g_inputBuf);
    g_origCoutBuf = std::cout.rdbuf(g_outputBuf);

    // Start engine on a background thread
    g_engineThread = new std::thread([] {
        Stockfish::Bitboards::init();
        Stockfish::Position::init();

        std::string fakeBinary = g_resourcePath + "stockfish";
        std::vector<char> arg0(fakeBinary.begin(), fakeBinary.end());
        arg0.push_back('\0');
        char* argv[] = { arg0.data(), nullptr };
        int   argc   = 1;

        auto uci = std::make_unique<Stockfish::UCIEngine>(argc, argv);
        Stockfish::Tune::init(uci->engine_options());

        uci->loop();
    });

    g_initialized.store(true);
    return 0;
}

void stockfish_command(const char* command) {
    if (!g_initialized.load() || !g_inputQueue) return;
    g_inputQueue->push(std::string(command));
}

char* stockfish_read_line(void) {
    if (!g_initialized.load() || !g_outputQueue) return nullptr;
    std::string line;
    if (g_outputQueue->tryPop(line)) {
        char* result = (char*)malloc(line.size() + 1);
        if (result) {
            std::strcpy(result, line.c_str());
        }
        return result;
    }
    return nullptr;
}

int stockfish_output_available(void) {
    if (!g_initialized.load() || !g_outputQueue) return 0;
    return g_outputQueue->empty() ? 0 : 1;
}

void stockfish_shutdown(void) {
    if (!g_initialized.load()) return;

    if (g_inputQueue) g_inputQueue->push("quit");
    if (g_inputBuf)   g_inputBuf->shutdown_.store(true);

    if (g_engineThread && g_engineThread->joinable()) {
        g_engineThread->join();
    }

    if (g_origCinBuf)  std::cin.rdbuf(g_origCinBuf);
    if (g_origCoutBuf) std::cout.rdbuf(g_origCoutBuf);

    delete g_engineThread;   g_engineThread = nullptr;
    delete g_inputBuf;       g_inputBuf     = nullptr;
    delete g_outputBuf;      g_outputBuf    = nullptr;
    delete g_inputQueue;     g_inputQueue   = nullptr;
    delete g_outputQueue;    g_outputQueue  = nullptr;
    g_origCinBuf  = nullptr;
    g_origCoutBuf = nullptr;
    g_resourcePath.clear();

    g_initialized.store(false);
}

} // extern "C"
