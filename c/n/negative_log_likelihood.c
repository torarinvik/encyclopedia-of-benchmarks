/* Binary negative log-likelihood with source-ordered accumulation. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_COUNT 64
#define SCALE 1000000.0
#define INVALID_RESULT (-1.0e300)

double negative_log_likelihood(const int64_t *values, size_t length)
{
    if (values == NULL || length < 1) return INVALID_RESULT;
    const int64_t count = values[0];
    if (count < 1 || count > MAX_COUNT || length != 1 + 2 * (size_t)count) return INVALID_RESULT;
    double total = 0.0;
    for (size_t i = 0; i < (size_t)count; i++) {
        const int64_t actual_scaled = values[1 + i];
        const int64_t predicted_scaled = values[1 + (size_t)count + i];
        if (actual_scaled < 0 || actual_scaled > 1000000 ||
            predicted_scaled < 1 || predicted_scaled > 999999) return INVALID_RESULT;
        const double actual = (double)actual_scaled / SCALE;
        const double predicted = (double)predicted_scaled / SCALE;
        total += -actual * log(predicted) - (1.0 - actual) * log(1.0 - predicted);
    }
    return total / (double)count;
}
