#include <stddef.h>
#include <stdint.h>
#define MAX_LENGTH 64
#define MAX_ABS_VALUE INT64_C(1000000)
double arithmetic_mean(const int64_t *values, size_t length) {
    if (values == NULL || length == 0 || length > MAX_LENGTH) return -1.0e300;
    int64_t total = 0;
    for (size_t i = 0; i < length; ++i) { if (values[i] < -MAX_ABS_VALUE || values[i] > MAX_ABS_VALUE) return -1.0e300; total += values[i]; }
    return (double)total / (double)length;
}
