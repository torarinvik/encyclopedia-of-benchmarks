#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t maximum_sum_of_distinct_subarrays_with_length_k(const std::int64_t *values, std::size_t length) noexcept
{
    constexpr std::int64_t invalid = INT64_MIN;
    constexpr std::size_t max_n = 8192, capacity = 16384, mask = capacity - 1;
    if (values == nullptr || length < 3 || length > max_n + 2) return invalid;
    const std::int64_t n_value = values[0], k_value = values[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n) || k_value < 1 || k_value > n_value ||
        length != static_cast<std::size_t>(n_value) + 2) return invalid;
    const auto n = static_cast<std::size_t>(n_value), k = static_cast<std::size_t>(k_value);
    std::array<std::int32_t, capacity> keys{};
    std::array<std::int32_t, capacity> last_plus_one{};
    std::int64_t current_sum = 0, maximum_sum = 0;
    std::size_t distinct_start = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const std::int64_t input = values[i + 2];
        if (input < INT32_MIN || input > INT32_MAX) return invalid;
        const auto value = static_cast<std::int32_t>(input);
        if (i < k) current_sum += value;
        else {
            current_sum -= values[i - k + 2];
            current_sum += value;
        }
        std::size_t slot = static_cast<std::size_t>((input + 2147483648LL) % capacity);
        while (last_plus_one[slot] != 0 && keys[slot] != value) slot = (slot + 1) & mask;
        if (last_plus_one[slot] != 0) {
            const auto previous = static_cast<std::size_t>(last_plus_one[slot] - 1);
            if (previous >= distinct_start) distinct_start = previous + 1;
        } else keys[slot] = value;
        last_plus_one[slot] = static_cast<std::int32_t>(i + 1);
        if (i + 1 >= k) {
            const std::size_t start = i + 1 - k;
            if (start >= distinct_start && current_sum > maximum_sum) maximum_sum = current_sum;
        }
    }
    return maximum_sum;
}
