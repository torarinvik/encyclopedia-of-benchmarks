/* Selector adapter for the source exponential-distribution statistics. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_RATE_MICRO INT64_C(1000000000)
#define INVALID_RESULT (-1.0e300)

double exponential_dist(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return INVALID_RESULT;
    const int64_t operation = values[0], rate_micro = values[1];
    if (operation < 0 || operation > 2 || rate_micro <= 0 || rate_micro > MAX_RATE_MICRO)
        return INVALID_RESULT;
    const double rate = (double)rate_micro / 1000000.0;
    if (operation == 1) return 1.0 / pow(rate, 2.0);
    return 1.0 / rate;
}
