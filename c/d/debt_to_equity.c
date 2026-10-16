/* Cross-platform scalar implementation of debt_to_equity. */
#include <stddef.h>
#include <stdint.h>
#define INVALID_RESULT (-1.0e300)

double debt_to_equity(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return INVALID_RESULT;
    const int64_t debt = values[0];
    const int64_t equity = values[1];
    if (debt < 0 || debt > 1000000 || equity < 1 || equity > 1000000) return INVALID_RESULT;
    return ((double)debt) / ((double)equity);
}
