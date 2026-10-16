#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t invalid_result = INT64_MIN;
constexpr std::int64_t int32_min_value = -2147483648LL;
constexpr std::int64_t int32_max_value = 2147483647LL;
}

extern "C" std::int64_t find_second_largest_element(const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > 10001) return invalid_result;
    const auto n = input[0];
    if (n < 2 || n > 10000 || length != static_cast<std::size_t>(n) + 1) return invalid_result;
    std::int64_t largest = int32_min_value;
    for (std::size_t i = 0; i < static_cast<std::size_t>(n); ++i) {
        const auto value = input[i + 1];
        if (value < int32_min_value || value > int32_max_value) return invalid_result;
        if (value > largest) largest = value;
    }
    std::int64_t second = int32_min_value - 1;
    for (std::size_t i = 0; i < static_cast<std::size_t>(n); ++i) {
        const auto value = input[i + 1];
        if (value < largest && value > second) second = value;
    }
    return second == int32_min_value - 1 ? invalid_result : second;
}
