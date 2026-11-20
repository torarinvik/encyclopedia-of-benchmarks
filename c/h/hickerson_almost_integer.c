#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double hickerson_almost_integer(const int64_t *values, size_t length) {
    if (values == NULL || length != 1 || values[0] < 1 || values[0] > 17)
        return INVALID_RESULT;
    const double log_two = log(2.0);
    double value = 1.0 / (2.0 * log_two * log_two);
    for (int64_t n = 2; n <= values[0]; ++n)
        value = ((double)n / log_two) * value;
    return value;
}
