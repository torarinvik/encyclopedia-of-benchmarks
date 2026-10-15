/* Bounded selector wrapper for the Java thin-lens operations. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double thin_lens(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3) return INVALID_RESULT;
    const int64_t operation = values[0], a = values[1], b = values[2];
    if (a < -1000 || a > 1000 || b < -1000 || b > 1000) return INVALID_RESULT;
    if (operation == 0) {
        if (a == 0 || b == 0 || a == b) return INVALID_RESULT;
        const double f = (double)a, u = (double)b;
        return 1.0 / ((1.0 / f) - (1.0 / u));
    }
    if (operation == 1) {
        if (b == 0) return INVALID_RESULT;
        return (double)a / (double)b;
    }
    if (operation == 2) {
        if (b != 0) return INVALID_RESULT;
        return a > 0 ? 1.0 : 0.0;
    }
    return INVALID_RESULT;
}
