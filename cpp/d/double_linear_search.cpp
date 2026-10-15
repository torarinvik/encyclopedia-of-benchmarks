/* Two-ended linear search with source-compatible endpoint priority. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t double_linear_search(const std::int64_t *values,
                                              std::size_t length) noexcept
{
    constexpr std::int64_t max_items = 100000;
    constexpr std::int64_t max_safe_integer = 9007199254740991;
    if (values == nullptr || length < 2 || length > 100002) return -1;
    const std::int64_t target = values[0];
    const std::int64_t count_value = values[1];
    if (target < -max_safe_integer || target > max_safe_integer || count_value < 0 ||
        count_value > max_items || length != static_cast<std::size_t>(count_value) + 2) return -1;

    const std::size_t count = static_cast<std::size_t>(count_value);
    for (std::size_t index = 0; index < count; ++index) {
        if (values[index + 2] < -max_safe_integer || values[index + 2] > max_safe_integer) return -1;
    }
    std::size_t start = 0, right = count;
    while (start < right) {
        if (values[start + 2] == target) return static_cast<std::int64_t>(start);
        if (values[right + 1] == target) return static_cast<std::int64_t>(right - 1);
        ++start;
        --right;
    }
    return -1;
}
