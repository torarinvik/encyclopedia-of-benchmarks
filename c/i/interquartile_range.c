/* Interquartile range using the source lower/upper-half median rule. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

static double median(const int64_t *values, size_t count) {
    if (count % 2 != 0) return (double)values[count / 2];
    return ((double)values[count / 2 - 1] + (double)values[count / 2]) / 2.0;
}

double interquartile_range(const int64_t *values, size_t length) {
    if (length < 2 || length > 64 || values == NULL) return INVALID_RESULT;
    int64_t sorted[64];
    for (size_t i = 0; i < length; ++i) {
        if (values[i] < -1000000 || values[i] > 1000000) return INVALID_RESULT;
        sorted[i] = values[i];
    }
    for (size_t i = 1; i < length; ++i) {
        const int64_t key = sorted[i];
        size_t j = i;
        while (j > 0 && sorted[j - 1] > key) { sorted[j] = sorted[j - 1]; --j; }
        sorted[j] = key;
    }
    const size_t half = length / 2;
    const size_t upper_start = half + (length % 2);
    return median(sorted + upper_start, half) - median(sorted, half);
}
