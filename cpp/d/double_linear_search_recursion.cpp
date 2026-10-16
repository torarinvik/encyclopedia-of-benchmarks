/* Search from both ends inward, matching the recursive source's visit order. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MAX_ITEMS = 1024;
constexpr std::int64_t INVALID_RESULT = -2;

std::int64_t search_range(const std::int64_t *values, std::int64_t key,
                          std::int64_t left, std::int64_t right, std::size_t offset) noexcept
{
    if (left > right) return -1;
    if (values[offset + static_cast<std::size_t>(left)] == key) return left;
    if (values[offset + static_cast<std::size_t>(right)] == key) return right;
    return search_range(values, key, left + 1, right - 1, offset);
}
}

extern "C" std::int64_t double_linear_search_recursion(const std::int64_t *input,
                                                        std::size_t length) noexcept
{
    if (input == nullptr || length < 2 || length > MAX_ITEMS + 2) return INVALID_RESULT;
    const auto count_value = input[0];
    const auto key = input[1];
    if (count_value < 0 || count_value > MAX_ITEMS || key < INT32_MIN || key > INT32_MAX ||
        length != static_cast<std::size_t>(2 + count_value)) return INVALID_RESULT;
    for (std::int64_t index = 0; index < count_value; ++index) {
        if (input[2 + index] < INT32_MIN || input[2 + index] > INT32_MAX) return INVALID_RESULT;
    }
    return search_range(input, key, 0, count_value - 1, 2);
}
