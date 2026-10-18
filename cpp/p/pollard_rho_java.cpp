#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t min_n = 2;
constexpr std::int64_t max_n = 46340;
constexpr std::int64_t max_steps = 4096;

std::int64_t java_remainder(std::int64_t value, std::int64_t modulus) noexcept {
    return value < 0 ? -((-value) % modulus) : value % modulus;
}

std::int64_t next_value(std::int64_t value, std::int64_t modulus) noexcept {
    return java_remainder(value * value - 1, modulus);
}

std::int64_t gcd_nonnegative(std::int64_t left, std::int64_t right) noexcept {
    while (right != 0) {
        const auto remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}
}

extern "C" std::int64_t pollard_rho_java(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length != 2) return -1;
    const auto n = input[0];
    const auto step_limit = input[1];
    if (n < min_n || n > max_n || step_limit < 1 || step_limit > max_steps) return -1;

    std::int64_t x = 2;
    std::int64_t y = 2;
    for (std::int64_t step = 0; step < step_limit; ++step) {
        x = next_value(x, n);
        y = next_value(next_value(y, n), n);
        const auto difference = x >= y ? x - y : y - x;
        const auto divisor = gcd_nonnegative(difference, n);
        if (divisor == 1) continue;
        return divisor == n ? 0 : divisor;
    }
    return -2;
}
