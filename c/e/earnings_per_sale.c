/* Cross-platform scalar implementation of earnings_per_sale. */
#include <stddef.h>
#include <stdint.h>
#define INVALID_RESULT (-1.0e300)

double earnings_per_sale(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3) return INVALID_RESULT;
    const int64_t net_income = values[0];
    const int64_t preferred_dividend = values[1];
    const int64_t average_shares = values[2];
    if (net_income < -1000000 || net_income > 1000000 || preferred_dividend < 0 || preferred_dividend > 1000000 || average_shares < 1 || average_shares > 1000000) return INVALID_RESULT;
    return (((double)net_income) - ((double)preferred_dividend)) / ((double)average_shares);
}
