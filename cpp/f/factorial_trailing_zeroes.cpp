/* Count factors of five in n!, which determine its trailing decimal zeros. */
#include <cstdint>

extern "C" std::int64_t factorial_trailing_zeroes(std::int64_t n) noexcept {
    if (n < 0 || n > 1'000'000'000) return -1;
    std::int64_t count = 0;
    while (n > 0) {
        n /= 5;
        count += n;
    }
    return count;
}
