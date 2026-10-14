/* Compute Fibonacci numbers by portable 64-bit fast doubling. */
#include <cstdint>

extern "C" std::int64_t fibonacci_fast(std::int64_t input) noexcept {
    if (input < 0 || input > 92) return -1;
    const std::uint64_t n = static_cast<std::uint64_t>(input);
    std::uint64_t bit = 1;
    while (bit <= n / 2) bit <<= 1;
    std::uint64_t current = 0, next = 1;
    while (bit != 0) {
        const std::uint64_t even = current * (2 * next - current);
        const std::uint64_t odd = current * current + next * next;
        if ((n & bit) != 0) {
            current = odd;
            next = even + odd;
        } else {
            current = even;
            next = odd;
        }
        bit >>= 1;
    }
    return static_cast<std::int64_t>(current);
}
