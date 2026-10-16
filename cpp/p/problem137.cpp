#include <cstdint>

extern "C" std::int64_t problem137(std::int64_t n) noexcept
{
    if (n < 1 || n > 23) return -1;
    std::int64_t previous = 1;
    std::int64_t current = 1;
    for (std::int64_t index = 0; index < 2 * n - 1; ++index) {
        const auto next = previous + current;
        previous = current;
        current = next;
    }
    return previous * current;
}
