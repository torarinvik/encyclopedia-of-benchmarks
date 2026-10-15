// XOR two values in the bounded unsigned 53-bit domain.
#include <cstdint>

namespace {
constexpr std::uint64_t max_uint53 = 9007199254740991;
constexpr std::int64_t invalid_result = -1;
}

extern "C" std::int64_t uint53_bitwise_xor(std::uint64_t n, std::uint64_t m) noexcept {
    if (n > max_uint53 || m > max_uint53) return invalid_result;

    std::uint64_t result = 0;
    std::uint64_t bit = 1;
    while (n != 0 && m != 0) {
        const std::uint64_t n_bit = n % 2;
        const std::uint64_t m_bit = m % 2;
        result += ((n_bit + m_bit) % 2) * bit;
        n = (n - n_bit) / 2;
        m = (m - m_bit) / 2;
        bit *= 2;
    }
    return static_cast<std::int64_t>(result + (n + m) * bit);
}
