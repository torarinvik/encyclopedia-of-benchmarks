#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define KAHAN_MAX_LENGTH 256
#define KAHAN_MAX_ABS_VALUE 1.0e100

int64_t kahan_summation(const double *values, size_t length,
                        double *output, size_t capacity) {
    if (values == NULL || length > KAHAN_MAX_LENGTH) return -1;
    for (size_t i = 0; i < length; ++i) {
        if (!isfinite(values[i]) || fabs(values[i]) > KAHAN_MAX_ABS_VALUE) return -1;
    }
    if (output == NULL || capacity < 1) return -2;

    double sum = 0.0;
    double correction = 0.0;
    for (size_t i = 0; i < length; ++i) {
        const double adjusted = values[i] - correction;
        const double next = sum + adjusted;
        correction = (next - sum) - adjusted;
        sum = next;
    }
    output[0] = sum;
    return 1;
}
