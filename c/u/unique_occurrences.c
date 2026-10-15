#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

int64_t unique_occurrences(const int64_t *values, size_t length) {
    if (length > 1000 || (length != 0 && values == NULL)) {
        return -1;
    }
    int64_t counts[2001] = {0};
    bool seen_frequencies[1001] = {false};
    for (size_t index = 0; index < length; ++index) {
        int64_t value = values[index];
        if (value < -1000 || value > 1000) return -1;
        ++counts[(size_t)(value + 1000)];
    }
    for (size_t index = 0; index < 2001; ++index) {
        int64_t frequency = counts[index];
        if (frequency == 0) continue;
        if (seen_frequencies[(size_t)frequency]) return 0;
        seen_frequencies[(size_t)frequency] = true;
    }
    return 1;
}
