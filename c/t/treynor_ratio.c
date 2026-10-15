/* Treynor ratio: (portfolio return - risk-free rate) / beta. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double treynor_ratio(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3) return INVALID_RESULT;
    const int64_t portfolio_return = values[0];
    const int64_t risk_free_rate = values[1];
    const int64_t beta = values[2];
    if (portfolio_return < -1000 || portfolio_return > 1000 ||
        risk_free_rate < -1000 || risk_free_rate > 1000 ||
        beta < -1000 || beta > 1000 || beta == 0) return INVALID_RESULT;
    return ((double)(portfolio_return - risk_free_rate)) / (double)beta;
}
