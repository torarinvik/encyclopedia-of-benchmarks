/* Harmonic mean of positive values. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 64
#define INVALID_RESULT (-1.0e300)

double harmonic_mean(const int64_t *values, size_t length)
{
    if (values == NULL || length == 0 || length > MAX_LENGTH) return INVALID_RESULT;
    double reciprocal_sum = 0.0;
    for (size_t index = 0; index < length; ++index) {
        const int64_t value = values[index];
        if (value < 1 || value > 1000) return INVALID_RESULT;
        reciprocal_sum += 1.0 / (double)value;
    }
    return (double)length / reciprocal_sum;
}
