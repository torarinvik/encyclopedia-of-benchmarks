// Complement every bit in the fixed-width unsigned 53-bit domain.
#include <cstdint>

namespace {
constexpr std::int64_t max_uint53 = 9007199254740991;
constexpr std::int64_t two_to_53 = 9007199254740992;
}

extern "C" std::int64_t uint53_bitwise_not(std::int64_t n) noexcept {
    if (n < 0 || n > max_uint53) return -1;

    std::int64_t result = 0;
    std::int64_t bit = 1;
    while (n >= 255) {
        const std::int64_t byte = n % 256;
        result += (255 - byte) * bit;
        n = (n - byte) / 256;
        bit *= 256;
    }
    while (n != 0) {
        const std::int64_t n_bit = n % 2;
        result += (1 - n_bit) * bit;
        n = (n - n_bit) / 2;
        bit *= 2;
    }

    return two_to_53 - bit + result;
}
