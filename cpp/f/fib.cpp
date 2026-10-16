#include <cstdint>

extern "C" std::int64_t fib(std::int64_t n) noexcept {
    if (n < 0 || n > 90) return -1;
    std::int64_t previous = 1, current = 2;
    for (std::int64_t i = 0; i < n; ++i) { auto next = previous + current; previous = current; current = next; }
    return previous;
}
