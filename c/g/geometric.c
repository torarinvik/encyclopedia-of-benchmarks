#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

/* Operation 0 tests a geometric sequence; operation 1 computes its mean. */
double geometric(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2) return INVALID_RESULT;
    const int64_t operation = values[0];
    const size_t count = length - 1;
    if (operation == 0) {
        if (count > 16) return INVALID_RESULT;
        for (size_t i = 1; i < length; ++i)
            if (values[i] < -100 || values[i] > 100) return INVALID_RESULT;
        if (count == 1) return 1.0;
        if (values[1] == 0) return 0.0;
        const double common_ratio = (double)values[2] / (double)values[1];
        for (size_t i = 0; i + 1 < count; ++i) {
            if (values[i + 1] == 0) return 0.0;
            if ((double)values[i + 2] / (double)values[i + 1] != common_ratio) return 0.0;
        }
        return 1.0;
    }
    if (operation == 1) {
        if (count > 7) return INVALID_RESULT;
        int64_t product = 1;
        for (size_t i = 1; i < length; ++i) {
            if (values[i] < 0 || values[i] > 100) return INVALID_RESULT;
            product *= values[i];
        }
        return pow((double)product, 1.0 / (double)count);
    }
    return INVALID_RESULT;
}
