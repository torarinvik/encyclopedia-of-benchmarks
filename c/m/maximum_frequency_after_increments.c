#include <stddef.h>
#include <stdint.h>

int64_t maximum_frequency_after_increments(const int64_t *input, size_t length) {
    if (length < 1 || length > 257 || input == NULL) return -1;
    const int64_t budget = input[0];
    const size_t count = length - 1;
    if (budget < 0 || budget > 1000000) return -1;
    int64_t values[256];
    for (size_t index = 0; index < count; ++index) {
        const int64_t value = input[index + 1];
        if (value < 1 || value > 10000) return -1;
        size_t position = index;
        while (position > 0 && values[position - 1] > value) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = value;
    }
    size_t left = 0;
    int64_t window_sum = 0;
    size_t best = 0;
    for (size_t right = 0; right < count; ++right) {
        window_sum += values[right];
        while (values[right] * (int64_t)(right - left + 1) - window_sum > budget) {
            window_sum -= values[left++];
        }
        const size_t window_length = right - left + 1;
        if (window_length > best) best = window_length;
    }
    return (int64_t)best;
}
