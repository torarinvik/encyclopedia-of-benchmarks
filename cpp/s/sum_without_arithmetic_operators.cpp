// Java int addition by recursive XOR and shifted carry, modulo 2^32.
#include <cstdint>

namespace {
std::uint32_t add_recursive(std::uint32_t a, std::uint32_t b) {
    if (b == 0) return a;
    return add_recursive(a ^ b, (a & b) << 1);
}
}

extern "C" std::int64_t sum_without_arithmetic_operators(std::int64_t a, std::int64_t b) noexcept {
    if (a < INT32_MIN || a > INT32_MAX || b < INT32_MIN || b > INT32_MAX) return -INT64_C(2147483649);
    const auto bits = add_recursive(static_cast<std::uint32_t>(a), static_cast<std::uint32_t>(b));
    return bits <= INT32_MAX ? static_cast<std::int64_t>(bits) : static_cast<std::int64_t>(bits) - INT64_C(4294967296);
}
