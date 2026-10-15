/* Count low-order zero bits by shifting away factors of two. */
#include <cstdint>

extern "C" std::int64_t binary_count_trailing_zeros(std::int64_t n) noexcept {
    if (n < 0) return -1;
    std::int64_t count = 0;
    while (n > 0 && (n & 1) == 0) {
        n >>= 1;
        ++count;
    }
    return count;
}
