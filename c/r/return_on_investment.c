/* Cross-platform scalar implementation of return_on_investment. */
#include <stddef.h>
#include <stdint.h>
#define INVALID_RESULT (-1.0e300)

double return_on_investment(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return INVALID_RESULT;
    const int64_t gain = values[0];
    const int64_t cost = values[1];
    if (gain < -1000000 || gain > 1000000 || cost < 1 || cost > 1000000) return INVALID_RESULT;
    return (((double)gain) - ((double)cost)) / ((double)cost);
}
