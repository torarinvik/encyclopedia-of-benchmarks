#include <cmath>
#include <cstddef>
#include <cstdint>

static size_t lower_bound(const double *sorted, size_t size, double value)
{
    size_t low = 0, high = size;
    while (low < high) {
        const size_t middle = low + (high - low) / 2;
        if (sorted[middle] < value) low = middle + 1;
        else high = middle;
    }
    return low;
}

extern "C" int64_t median_filter(const double *input, size_t length,
                                 double *output, size_t output_capacity)
{
    if (input == nullptr || length < 2 || length > 2 + 64) return -1;
    const double window_value = input[0], count_value = input[1];
    if (!std::isfinite(window_value) || std::floor(window_value) != window_value || window_value < 1.0 || window_value > 16.0 ||
        !std::isfinite(count_value) || std::floor(count_value) != count_value || count_value < 0.0 || count_value > 64.0) return -1;
    const size_t window = static_cast<size_t>(window_value), count = static_cast<size_t>(count_value);
    if (length != 2 + count) return -1;
    double samples[64];
    for (size_t index = 0; index < count; ++index) {
        const double value = input[2 + index];
        if (!std::isfinite(value) || value < -1000000.0 || value > 1000000.0) return -1;
        samples[index] = value;
    }
    if (output == nullptr || output_capacity < count) return -2;

    double arrival[16], sorted[16], result[64];
    size_t size = 0, oldest = 0;
    for (size_t index = 0; index < count; ++index) {
        const double value = samples[index];
        if (size == window) {
            const size_t position = lower_bound(sorted, size, arrival[oldest]);
            for (size_t shift = position + 1; shift < size; ++shift) sorted[shift - 1] = sorted[shift];
            --size;
        }
        const size_t position = lower_bound(sorted, size, value);
        for (size_t shift = size; shift > position; --shift) sorted[shift] = sorted[shift - 1];
        sorted[position] = value;
        arrival[oldest] = value;
        oldest = (oldest + 1) % window;
        ++size;
        const size_t middle = size / 2;
        result[index] = (size % 2 != 0) ? sorted[middle] : 0.5 * (sorted[middle - 1] + sorted[middle]);
    }
    for (size_t index = 0; index < count; ++index) output[index] = result[index];
    return static_cast<int64_t>(count);
}
