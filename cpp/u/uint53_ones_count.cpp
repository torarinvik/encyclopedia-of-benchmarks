// Count set bits in the bounded unsigned 53-bit domain, byte by byte.
#include <cstdint>

namespace {
constexpr std::int64_t max_uint53 = 9007199254740991;

std::int64_t count_byte_ones(std::int64_t byte) noexcept {
    std::int64_t ones = 0;
    while (byte > 0) {
        const std::int64_t bit = byte % 2;
        ones += bit;
        byte = (byte - bit) / 2;
    }
    return ones;
}
}

extern "C" std::int64_t uint53_ones_count(std::int64_t n) noexcept {
    if (n < 0 || n > max_uint53) return -1;

    std::int64_t ones = 0;
    while (n != 0) {
        const std::int64_t byte = n % 256;
        ones += count_byte_ones(byte);
        n = (n - byte) / 256;
    }
    return ones;
}
