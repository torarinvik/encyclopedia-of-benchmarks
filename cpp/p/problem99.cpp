#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_PAIR_COUNT = 1000;
constexpr std::int64_t MAX_BASE = 1'000'000;
constexpr std::int64_t MAX_EXPONENT = 1'200'000;
}

extern "C" std::int64_t problem99(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length < 1) return -1;
    const auto pair_count_value = input[0];
    if (pair_count_value < 0 || pair_count_value > static_cast<std::int64_t>(MAX_PAIR_COUNT)) return -1;
    const auto pair_count = static_cast<std::size_t>(pair_count_value);
    if (length != 1 + 2 * pair_count) return -1;

    double largest = 0.0;
    std::int64_t result = 0;
    for (std::size_t index = 0; index < pair_count; ++index) {
        const auto base = input[1 + 2 * index];
        const auto exponent = input[2 + 2 * index];
        if (base < 1 || base > MAX_BASE || exponent < 0 || exponent > MAX_EXPONENT) return -1;
        const double value = static_cast<double>(exponent) * std::log10(static_cast<double>(base));
        if (value > largest) {
            largest = value;
            result = static_cast<std::int64_t>(index + 1);
        }
    }
    return result;
}
