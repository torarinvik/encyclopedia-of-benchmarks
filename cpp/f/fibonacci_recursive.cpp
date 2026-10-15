// Naive recursive Fibonacci on a deliberately small domain.
#include <cstdint>

static std::int64_t fibonacci_value(std::int64_t n) {
    if (n < 2) return n;
    return fibonacci_value(n - 1) + fibonacci_value(n - 2);
}

extern "C" std::int64_t fibonacci_recursive(std::int64_t n) noexcept {
    if (n < 0 || n > 30) return -1;
    return fibonacci_value(n);
}
