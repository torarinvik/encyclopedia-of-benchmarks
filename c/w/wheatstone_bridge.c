/* Solve the unknown resistance in a balanced Wheatstone bridge. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double wheatstone_bridge(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3) return INVALID_RESULT;
    const int64_t resistance_1 = values[0];
    const int64_t resistance_2 = values[1];
    const int64_t resistance_3 = values[2];
    if (resistance_1 < 1 || resistance_1 > 1000000 ||
        resistance_2 < 1 || resistance_2 > 1000000 ||
        resistance_3 < 1 || resistance_3 > 1000000) return INVALID_RESULT;
    return ((double)resistance_2 / (double)resistance_1) * (double)resistance_3;
}
