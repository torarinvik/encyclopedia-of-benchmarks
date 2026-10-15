/* Solve Boyle's law for one omitted variable, rounded to 3 decimals. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

static int64_t rounded_milli(int64_t numerator, int64_t denominator)
{
    const int64_t scaled = numerator * 1000;
    int64_t quotient = scaled / denominator;
    const int64_t remainder = scaled % denominator;
    if (2 * remainder > denominator || (2 * remainder == denominator && quotient % 2 != 0))
        ++quotient;
    return quotient;
}

double boyles_law(const int64_t *values, size_t length)
{
    if (values == NULL || length != 4) return INVALID_RESULT;
    const int64_t target = values[0];
    const int64_t a = values[1], b = values[2], c = values[3];
    if (target < 0 || target > 3 || a < 1 || a > 1000 || b < 1 || b > 1000 || c < 1 || c > 1000)
        return INVALID_RESULT;
    int64_t numerator, denominator;
    switch (target) {
        case 0: numerator = c * a; denominator = b; break; /* v1 = p2*v2/p1 */
        case 1: numerator = b * a; denominator = c; break; /* v2 = p1*v1/p2 */
        case 2: numerator = c * b; denominator = a; break; /* p1 = p2*v2/v1 */
        default: numerator = c * a; denominator = b; break; /* p2 = p1*v1/v2 */
    }
    return (double)rounded_milli(numerator, denominator) / 1000.0;
}
