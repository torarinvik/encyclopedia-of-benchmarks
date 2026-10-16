#include <math.h>
#include <stdint.h>
#include <string.h>

#define MIN_VALUE 1e-6
#define MAX_VALUE 1e6

double fast_inverse_sqrt_cpp(double value)
{
    if (!isfinite(value) || value < MIN_VALUE || value > MAX_VALUE) return -1.0;
    double y = value;
    const double x2 = y * 0.5;
    int64_t bits;
    memcpy(&bits, &y, sizeof(bits));
    bits = INT64_C(0x5fe6eb50c7b537a9) - (bits >> 1);
    memcpy(&y, &bits, sizeof(y));
    y = y * (1.5 - (x2 * y * y));
    y = y * (1.5 - (x2 * y * y));
    return y;
}
