/* Count decimal zero digits at the end of a nonnegative integer. */
#include <cstdint>

extern "C" std::int64_t trailing_zeroes(std::int64_t n) noexcept {
    if (n < 0) return -1;
    if (n == 0) return 1;
    std::int64_t count = 0;
    while (n % 10 == 0) {
        ++count;
        n /= 10;
    }
    return count;
}
