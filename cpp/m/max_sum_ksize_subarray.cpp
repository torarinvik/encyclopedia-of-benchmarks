// Maximum sum of a fixed-size window; the final packed value is k.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t max_sum_ksize_subarray(const std::int64_t *values, std::size_t length)
{
    if (length == 0 || length > 64 || values == nullptr) return -1;
    const std::size_t array_length = length - 1;
    const std::int64_t k_value = values[length - 1];
    if (k_value < 0 || static_cast<std::uint64_t>(k_value) > array_length) return -1;
    for (std::size_t index = 0; index < array_length; ++index)
        if (values[index] < -1000000 || values[index] > 1000000) return -1;
    if (k_value == 0) return 0;

    const std::size_t k = static_cast<std::size_t>(k_value);
    std::int64_t window_sum = 0;
    for (std::size_t index = 0; index < k; ++index) window_sum += values[index];
    std::int64_t maximum_sum = window_sum;
    for (std::size_t index = k; index < array_length; ++index) {
        window_sum += values[index] - values[index - k];
        if (window_sum > maximum_sum) maximum_sum = window_sum;
    }
    return maximum_sum;
}
