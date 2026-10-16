// Iterative bitwise XOR for two nonnegative integers in the exact uint53 range.
#include <cstdint>

namespace {
constexpr std::int64_t max_uint53 = 9007199254740991;
}

extern "C" std::int64_t uint53_xor(std::int64_t left, std::int64_t right) noexcept {
    if (left < 0 || left > max_uint53 || right < 0 || right > max_uint53) return -1;
    std::int64_t result = 0;
    std::int64_t bit = 1;
    while (left != 0 && right != 0) {
        const std::int64_t left_bit = left % 2;
        const std::int64_t right_bit = right % 2;
        result += ((left_bit + right_bit) % 2) * bit;
        left = (left - left_bit) / 2;
        right = (right - right_bit) / 2;
        bit *= 2;
    }
    return result + (left + right) * bit;
}
