/* Sherman rainfall intensity curve over bounded integer inputs. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double rainfall_intensity(const int64_t *values, size_t length)
{
    if (values == NULL || length != 6) return INVALID_RESULT;
    const int64_t k = values[0], a = values[1], b = values[2], c = values[3], period = values[4], duration = values[5];
    if (k < 1 || k > 1000 || a < 1 || a > 3 || b < 1 || b > 100 || c < 1 || c > 3 ||
        period < 1 || period > 100 || duration < 1 || duration > 1000) return INVALID_RESULT;
    return ((double)k * pow((double)period, (double)a)) / pow((double)(duration + b), (double)c);
}
