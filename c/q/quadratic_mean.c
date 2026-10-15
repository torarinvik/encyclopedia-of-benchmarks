/* Quadratic mean, also known as root mean square. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 64
#define INVALID_RESULT (-1.0e300)

double quadratic_mean(const int64_t *values, size_t length)
{
    if (values == NULL || length == 0 || length > MAX_LENGTH) return INVALID_RESULT;
    double square_sum = 0.0;
    for (size_t index = 0; index < length; ++index) {
        const int64_t value = values[index];
        if (value < -1000 || value > 1000) return INVALID_RESULT;
        const double converted = (double)value;
        square_sum += converted * converted;
    }
    return sqrt(square_sum / (double)length);
}
