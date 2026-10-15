#include <cstddef>
#include <cstdint>

extern "C" std::int64_t min_sum_ksize_subarray(const std::int64_t *values, std::size_t length) noexcept
{
    constexpr std::int64_t invalid = INT64_MIN;
    if (values == nullptr || length < 2 || length > 100002) return invalid;
    const std::int64_t n_value = values[0], k_value = values[1];
    if (n_value < 0 || n_value > 100000 || k_value < 0 || k_value > 100000 ||
        length != static_cast<std::size_t>(n_value) + 2) return invalid;
    const std::size_t n = static_cast<std::size_t>(n_value), k = static_cast<std::size_t>(k_value);
    for (std::size_t i = 0; i < n; ++i)
        if (values[i + 2] < -10000 || values[i + 2] > 10000) return invalid;
    if (k > n) return -1;
    std::int64_t window_sum = 0;
    for (std::size_t i = 0; i < k; ++i) window_sum += values[i + 2];
    std::int64_t minimum_sum = window_sum;
    for (std::size_t i = k; i < n; ++i) {
        window_sum += values[i + 2] - values[i - k + 2];
        if (window_sum < minimum_sum) minimum_sum = window_sum;
    }
    return minimum_sum;
}
