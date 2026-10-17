#include <cstdint>

namespace {
constexpr std::int64_t min_n = 2;
constexpr std::int64_t max_n = 46340;

std::int64_t next_value(std::int64_t n, std::int64_t x) noexcept {
    return (x * x + 1) % n;
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

extern "C" std::int64_t pollards_rho_factorizing(std::int64_t n) noexcept {
    if (n < min_n || n > max_n) return -1;
    std::int64_t x = 2, y = 2, divisor = 1;
    while (divisor == 1) {
        x = next_value(n, x);
        y = next_value(n, next_value(n, y));
        const auto difference = x >= y ? x - y : y - x;
        divisor = gcd_nonnegative(difference, n);
    }
    return divisor;
}
