/* Black-Scholes European call/put price. Inputs use thousandths. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double black_scholes_option_price(const int64_t *values, size_t length)
{
    if (values == NULL || length != 6) return INVALID_RESULT;
    const int64_t kind = values[0];
    const int64_t spot_units = values[1];
    const int64_t strike_units = values[2];
    const int64_t time_units = values[3];
    const int64_t volatility_units = values[4];
    const int64_t rate_units = values[5];
    if ((kind != 0 && kind != 1) || spot_units < 10 || spot_units > 1000000000LL ||
        strike_units < 10 || strike_units > 1000000000LL || time_units < 1 ||
        time_units > 100000 || volatility_units < 1 || volatility_units > 5000 ||
        rate_units < -1000 || rate_units > 1000) return INVALID_RESULT;

    const double spot = (double)spot_units / 1000.0;
    const double strike = (double)strike_units / 1000.0;
    const double time = (double)time_units / 1000.0;
    const double volatility = (double)volatility_units / 1000.0;
    const double rate = (double)rate_units / 1000.0;
    const double sigma_sqrt_time = volatility * sqrt(time);
    const double d1 = (log(spot / strike) + (rate + volatility * volatility / 2.0) * time) / sigma_sqrt_time;
    const double d2 = d1 - sigma_sqrt_time;
    const double cdf_d1 = 0.5 * erfc(-d1 / sqrt(2.0));
    const double cdf_d2 = 0.5 * erfc(-d2 / sqrt(2.0));
    if (kind == 0) return spot * cdf_d1 - strike * exp(-rate * time) * cdf_d2;
    return strike * exp(-rate * time) * (0.5 * erfc(d2 / sqrt(2.0))) - spot * (0.5 * erfc(d1 / sqrt(2.0)));
}
