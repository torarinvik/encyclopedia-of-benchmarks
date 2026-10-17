/* Search one bounded half-open segment and return the worker's found flag. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_count = 64;
constexpr std::size_t max_input_length = max_count + 5;
constexpr std::int64_t i32_min = -2147483648LL;
constexpr std::int64_t i32_max = 2147483647LL;
}

extern "C" std::int64_t linear_search_thread(const std::int64_t *input,
                                               std::size_t length) noexcept {
    if (input == nullptr || length < 4 || length > max_input_length) return -1;
    const std::int64_t count_arg = input[0], left = input[1], right = input[2], target = input[3];
    if (count_arg < 1 || count_arg > static_cast<std::int64_t>(max_count) ||
        length != static_cast<std::size_t>(count_arg) + 4) return -1;
    if (left < 0 || left > right || right > count_arg || target < i32_min || target > i32_max)
        return -1;
    const std::size_t count = static_cast<std::size_t>(count_arg);
    for (std::size_t i = 0; i < count; ++i)
        if (input[4 + i] < i32_min || input[4 + i] > i32_max) return -1;
    for (std::size_t i = static_cast<std::size_t>(left); i < static_cast<std::size_t>(right); ++i)
        if (input[4 + i] == target) return 1;
    return 0;
}
