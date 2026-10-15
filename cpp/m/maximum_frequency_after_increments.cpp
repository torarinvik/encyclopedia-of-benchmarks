#include <cstddef>
#include <cstdint>

extern "C" std::int64_t maximum_frequency_after_increments(const std::int64_t *input, std::size_t length) {
    if (length < 1 || length > 257 || input == nullptr) return -1;
    const std::int64_t budget = input[0];
    const std::size_t count = length - 1;
    if (budget < 0 || budget > 1'000'000) return -1;
    std::int64_t values[256];
    for (std::size_t index = 0; index < count; ++index) {
        const std::int64_t value = input[index + 1];
        if (value < 1 || value > 10'000) return -1;
        std::size_t position = index;
        while (position > 0 && values[position - 1] > value) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = value;
    }
    std::size_t left = 0;
    std::int64_t window_sum = 0;
    std::size_t best = 0;
    for (std::size_t right = 0; right < count; ++right) {
        window_sum += values[right];
        while (values[right] * static_cast<std::int64_t>(right - left + 1) - window_sum > budget) {
            window_sum -= values[left++];
        }
        const std::size_t window_length = right - left + 1;
        if (window_length > best) best = window_length;
    }
    return static_cast<std::int64_t>(best);
}
