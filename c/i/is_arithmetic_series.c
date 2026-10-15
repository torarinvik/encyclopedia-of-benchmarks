#include <stddef.h>
#include <stdint.h>
#define MAX_LENGTH 64
#define MAX_ABS_VALUE INT64_C(1000000)
int64_t is_arithmetic_series(const int64_t *values, size_t length) {
    if (values == NULL || length == 0 || length > MAX_LENGTH) return -1;
    for (size_t i = 0; i < length; ++i) if (values[i] < -MAX_ABS_VALUE || values[i] > MAX_ABS_VALUE) return -1;
    if (length == 1) return 1;
    const int64_t difference = values[1] - values[0];
    for (size_t i = 1; i + 1 < length; ++i) if (values[i + 1] - values[i] != difference) return 0;
    return 1;
}
