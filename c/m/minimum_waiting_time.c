#include <stddef.h>
#include <stdint.h>

int64_t minimum_waiting_time(const int64_t *values, size_t length)
{
    if (length > 64 || (length != 0 && values == NULL)) return INT64_MIN;
    int64_t durations[64];
    for (size_t i = 0; i < length; ++i) {
        if (values[i] < 0 || values[i] > 1000) return INT64_MIN;
        durations[i] = values[i];
    }
    for (size_t i = 1; i < length; ++i) {
        const int64_t key = durations[i];
        size_t j = i;
        while (j > 0 && durations[j - 1] > key) {
            durations[j] = durations[j - 1];
            --j;
        }
        durations[j] = key;
    }
    int64_t total = 0;
    for (size_t i = 0; i < length; ++i)
        total += durations[i] * (int64_t)(length - i - 1);
    return total;
}
