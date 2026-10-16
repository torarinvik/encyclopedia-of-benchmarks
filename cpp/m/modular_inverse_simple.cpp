#include <cstdint>

namespace {
std::uint64_t gcd_u64(std::uint64_t left, std::uint64_t right) noexcept {
    while (right != 0) {
        const auto remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}
}

extern "C" std::int64_t modular_inverse_simple(std::int64_t x_input,
                                                 std::int64_t y_input) noexcept {
    if (x_input < 1 || x_input > 999 || y_input < 2 || y_input > 1000) return -1;
    const auto x = static_cast<std::uint64_t>(x_input);
    const auto y = static_cast<std::uint64_t>(y_input);
    if (gcd_u64(x, y) != 1) return -1;

    std::uint64_t auxiliary = 0, iteration = 0;
    do {
        auxiliary = y * iteration + 1;
        ++iteration;
    } while (auxiliary % x != 0);
    return static_cast<std::int64_t>(auxiliary / x);
}
