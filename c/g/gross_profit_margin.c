/* Cross-platform scalar implementation of gross_profit_margin. */
#include <stddef.h>
#include <stdint.h>
#define INVALID_RESULT (-1.0e300)

double gross_profit_margin(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return INVALID_RESULT;
    const int64_t revenue = values[0];
    const int64_t cost = values[1];
    if (revenue < 1 || revenue > 1000000 || cost < 0 || cost > 1000000) return INVALID_RESULT;
    return (((double)revenue) - ((double)cost)) / ((double)revenue);
}
