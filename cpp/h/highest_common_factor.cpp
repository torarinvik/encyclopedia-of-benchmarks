// Recursive subtractive greatest common factor from the pinned MATLAB source.
#include <cstdint>

namespace {
std::uint64_t highest_common_factor_impl(std::uint64_t x, std::uint64_t y) noexcept {
    if (x == 0) return y;
    if (y == 0) return x;
    if (x == y) return x;
    if (y > x) return highest_common_factor_impl(y - x, x);
    return highest_common_factor_impl(x - y, y);
}
}

extern "C" std::int64_t highest_common_factor(std::uint64_t x, std::uint64_t y) noexcept {
    return static_cast<std::int64_t>(highest_common_factor_impl(x, y));
}
