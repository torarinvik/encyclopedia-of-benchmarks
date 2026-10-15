#include <cstddef>
#include <cstdint>

extern "C" std::int64_t max_sum_sliding_window(const std::int64_t *values, std::size_t length) noexcept
{
    constexpr std::int64_t invalid = INT64_MIN;
    if (values == nullptr || length < 3 || length > 100002) return invalid;
    const std::int64_t n_value = values[0], k_value = values[1];
    if (n_value < 1 || n_value > 100000 || k_value < 1 || k_value > n_value ||
        length != static_cast<std::size_t>(n_value) + 2) return invalid;
    const std::size_t n = static_cast<std::size_t>(n_value), k = static_cast<std::size_t>(k_value);
    std::int64_t current_sum = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const auto value = values[i + 2];
        if (value < -1000000000 || value > 1000000000) return invalid;
        if (i < k) current_sum += value;
    }
    std::int64_t maximum_sum = current_sum;
    for (std::size_t i = 0; i < n - k; ++i) {
        current_sum = current_sum - values[i + 2] + values[i + k + 2];
        if (current_sum > maximum_sum) maximum_sum = current_sum;
    }
    return maximum_sum;
}
