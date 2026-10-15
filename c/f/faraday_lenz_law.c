#include <stddef.h>
#include <stdint.h>

int64_t faraday_lenz_law(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3 || values[0] < -1000000000 || values[0] > 1000000000 ||
        values[1] < -1000000000 || values[1] > 1000000000 || values[2] < 1 || values[2] > 1000000000)
        return INT64_MIN;
    const int64_t numerator = -(values[0] - values[1]) * 10;
    const int64_t magnitude = numerator < 0 ? -numerator : numerator;
    int64_t quotient = magnitude / values[2];
    const int64_t remainder = magnitude % values[2];
    if (2 * remainder > values[2] || (2 * remainder == values[2] && quotient % 2 != 0)) ++quotient;
    return numerator < 0 ? -quotient : quotient;
}
