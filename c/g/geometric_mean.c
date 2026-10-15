#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 6
#define MAX_ABS_VALUE INT64_C(100)
#define INVALID_RESULT (-1.0e300)

double geometric_mean(const int64_t *values, size_t length)
{
    if (values == NULL || length == 0 || length > MAX_LENGTH) return INVALID_RESULT;
    int64_t product = 1;
    for (size_t i = 0; i < length; ++i) {
        if (values[i] < -MAX_ABS_VALUE || values[i] > MAX_ABS_VALUE) return INVALID_RESULT;
        product *= values[i];
    }
    if (product < 0 && length % 2 == 0) return INVALID_RESULT;
    double root = pow(fabs((double)product), 1.0 / (double)length);
    const double rounded = floor(root + 0.5);
    int64_t rounded_power = 1;
    for (size_t i = 0; i < length; ++i) rounded_power *= (int64_t)rounded;
    if ((product >= 0 && rounded_power == product)
        || (product < 0 && length % 2 == 1 && -rounded_power == product)) root = rounded;
    if (product < 0) root = -root;
    return root;
}
