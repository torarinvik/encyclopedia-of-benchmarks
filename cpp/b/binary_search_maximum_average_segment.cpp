/* Clean-room integer-threshold maximum-average segment profile. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 32;
constexpr std::size_t max_input = 35;
constexpr std::int64_t invalid_result = -1'000'001;

bool feasible(const std::int64_t *input, std::size_t n,
              std::size_t minimum_length, std::int64_t threshold) noexcept
{
    std::int64_t prefix[max_n + 1]{};
    for (std::size_t index = 0; index < n; ++index)
        prefix[index + 1] = prefix[index] + 1000 * input[index + 2] - threshold;
    std::int64_t minimum_prefix = INT64_MAX;
    for (std::size_t end = minimum_length; end <= n; ++end) {
        const auto eligible_start = end - minimum_length;
        if (prefix[eligible_start] < minimum_prefix) minimum_prefix = prefix[eligible_start];
        if (prefix[end] >= minimum_prefix) return true;
    }
    return false;
}
}

extern "C" std::int64_t binary_search_maximum_average_segment(
    const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length < 3 || length > max_input) return invalid_result;
    const auto n_value = input[0];
    const auto minimum_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n)
        || minimum_value < 1 || minimum_value > n_value
        || length != static_cast<std::size_t>(n_value + 2)) return invalid_result;
    const auto n = static_cast<std::size_t>(n_value);
    for (std::size_t index = 0; index < n; ++index)
        if (input[index + 2] < -1000 || input[index + 2] > 1000) return invalid_result;

    std::int64_t low = -1'000'000;
    std::int64_t high = 1'000'001;
    while (high - low > 1) {
        const auto middle = low + (high - low) / 2;
        if (feasible(input, n, static_cast<std::size_t>(minimum_value), middle)) low = middle;
        else high = middle;
    }
    return low;
}
