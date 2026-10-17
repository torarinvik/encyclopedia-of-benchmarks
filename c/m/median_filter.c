#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_WINDOW = 16, MAX_SAMPLES = 64 };

static size_t lower_bound(const double *sorted, size_t size, double value)
{
    size_t low = 0, high = size;
    while (low < high) {
        size_t middle = low + (high - low) / 2;
        if (sorted[middle] < value) low = middle + 1;
        else high = middle;
    }
    return low;
}

int64_t median_filter(const double *input, size_t length, double *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || length > 2 + MAX_SAMPLES) return -1;
    double window_value = input[0], count_value = input[1];
    if (!isfinite(window_value) || floor(window_value) != window_value || window_value < 1.0 || window_value > MAX_WINDOW ||
        !isfinite(count_value) || floor(count_value) != count_value || count_value < 0.0 || count_value > MAX_SAMPLES) return -1;
    size_t window = (size_t)window_value, count = (size_t)count_value;
    if (length != 2 + count) return -1;
    double samples[MAX_SAMPLES];
    for (size_t index = 0; index < count; ++index) {
        double value = input[2 + index];
        if (!isfinite(value) || value < -1000000.0 || value > 1000000.0) return -1;
        samples[index] = value;
    }
    if (output == NULL || output_capacity < count) return -2;

    double arrival[MAX_WINDOW], sorted[MAX_WINDOW], result[MAX_SAMPLES];
    size_t size = 0, oldest = 0;
    for (size_t index = 0; index < count; ++index) {
        double value = samples[index];
        if (size == window) {
            size_t position = lower_bound(sorted, size, arrival[oldest]);
            for (size_t shift = position + 1; shift < size; ++shift) sorted[shift - 1] = sorted[shift];
            --size;
        }
        size_t position = lower_bound(sorted, size, value);
        for (size_t shift = size; shift > position; --shift) sorted[shift] = sorted[shift - 1];
        sorted[position] = value;
        arrival[oldest] = value;
        oldest = (oldest + 1) % window;
        ++size;
        size_t middle = size / 2;
        result[index] = (size % 2 != 0) ? sorted[middle] : 0.5 * (sorted[middle - 1] + sorted[middle]);
    }
    for (size_t index = 0; index < count; ++index) output[index] = result[index];
    return (int64_t)count;
}
