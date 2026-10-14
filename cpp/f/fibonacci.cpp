/* Portable Fibonacci for the shared signed 64-bit benchmark contract. */
#include <cstdint>

extern "C" std::int64_t fibonacci(std::int64_t n) noexcept
{
    if (n < 0 || n > 92) {
        return -1;
    }
    if (n == 0) {
        return 0;
    }

    std::int64_t previous = 0;
    std::int64_t current = 1;
    for (std::int64_t index = 1; index < n; ++index) {
        const std::int64_t next = previous + current;
        previous = current;
        current = next;
    }
    return current;
}
