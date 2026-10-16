#include <stddef.h>
#include <stdint.h>

#define MAX_COUNT 128
#define MAX_I32 2147483647LL

int64_t find_min_iterator(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_COUNT + 1) return -1;
    if (input[0] < 0 || input[0] > MAX_COUNT || length != (size_t)input[0] + 1) return -1;
    const size_t count = (size_t)input[0];
    if (count == 0) return -1;
    int64_t minimum = MAX_I32;
    for (size_t i = 0; i < count; ++i) {
        const int64_t value = input[i + 1];
        if (value < 0 || value > MAX_I32) return -1;
        if (value < minimum) minimum = value;
    }
    return minimum;
}
