#include <array>
#include <cstdint>
#include <cstddef>

namespace {
std::array<int,10> digit_counts(std::int64_t value) noexcept {
    std::array<int,10> counts{};
    while (value > 0) { ++counts[static_cast<std::size_t>(value % 10)]; value /= 10; }
    return counts;
}
bool same_digits(std::int64_t left, std::int64_t right) noexcept { return digit_counts(left) == digit_counts(right); }
}
extern "C" std::int64_t problem52(std::int64_t unused) noexcept {
    if (unused != 0) return -1;
    for (std::int64_t value = 1;; ++value) {
        bool matches = true;
        for (std::int64_t multiplier = 2; multiplier <= 6 && matches; ++multiplier)
            matches = same_digits(value, multiplier * value);
        if (matches) return value;
    }
}
