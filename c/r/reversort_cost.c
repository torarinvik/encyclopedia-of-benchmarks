#include <stddef.h>
#include <stdint.h>

int64_t reversort_cost(const int64_t *values, size_t length) {
    if (length > 256) return -1;
    int64_t working[256];
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < INT32_MIN || values[index] > INT32_MAX) return -1;
        working[index] = values[index];
    }
    int64_t cost = 0;
    for (size_t index = 0; index + 1 < length; ++index) {
        size_t minimum = index;
        for (size_t probe = index + 1; probe < length; ++probe)
            if (working[probe] < working[minimum]) minimum = probe;
        for (size_t left = index, right = minimum; left < right; ++left, --right) {
            const int64_t temporary = working[left];
            working[left] = working[right];
            working[right] = temporary;
        }
        cost += (int64_t)(minimum - index + 1);
    }
    return cost;
}
