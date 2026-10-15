#include <cstdint>
extern "C" std::int64_t lucas_series(std::int64_t n) noexcept {
    if (n < 0 || n > 90) return -1;
    if (n == 0) return 2;
    std::int64_t previous = 2, current = 1;
    for (std::int64_t i = 2; i <= n; ++i) { auto next = previous + current; previous = current; current = next; }
    return current;
}
