// Count every pair of distinct indices whose values sum to the target.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t pairs_with_given_sum(const std::int64_t *input, std::size_t length) noexcept
{
    constexpr std::size_t max_input_length = 257;
    if (input == nullptr || length == 0 || length > max_input_length) return -2;
    for (std::size_t index = 0; index < length; ++index) {
        if (input[index] < INT64_C(-2147483648) || input[index] > INT64_C(2147483647)) return -2;
    }
    const std::int64_t target = input[0];
    const std::size_t value_count = length - 1;
    std::int64_t pairs = 0;
    for (std::size_t left = 0; left < value_count; ++left) {
        for (std::size_t right = left + 1; right < value_count; ++right) {
            if (input[left + 1] + input[right + 1] == target) ++pairs;
        }
    }
    return pairs;
}
