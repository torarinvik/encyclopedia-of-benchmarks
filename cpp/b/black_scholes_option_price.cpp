// Black-Scholes European call/put price. Inputs use thousandths.
#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" double black_scholes_option_price(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 6) return -1.0e300;
    const auto kind = values[0], spot_units = values[1], strike_units = values[2];
    const auto time_units = values[3], volatility_units = values[4], rate_units = values[5];
    if ((kind != 0 && kind != 1) || spot_units < 10 || spot_units > 1000000000LL ||
        strike_units < 10 || strike_units > 1000000000LL || time_units < 1 || time_units > 100000 ||
        volatility_units < 1 || volatility_units > 5000 || rate_units < -1000 || rate_units > 1000)
        return -1.0e300;
    const double spot = static_cast<double>(spot_units) / 1000.0;
    const double strike = static_cast<double>(strike_units) / 1000.0;
    const double time = static_cast<double>(time_units) / 1000.0;
    const double volatility = static_cast<double>(volatility_units) / 1000.0;
    const double rate = static_cast<double>(rate_units) / 1000.0;
    const double sigma_sqrt_time = volatility * std::sqrt(time);
    const double d1 = (std::log(spot / strike) + (rate + volatility * volatility / 2.0) * time) / sigma_sqrt_time;
    const double d2 = d1 - sigma_sqrt_time;
    const double cdf_d1 = 0.5 * std::erfc(-d1 / std::sqrt(2.0));
    const double cdf_d2 = 0.5 * std::erfc(-d2 / std::sqrt(2.0));
    if (kind == 0) return spot * cdf_d1 - strike * std::exp(-rate * time) * cdf_d2;
    return strike * std::exp(-rate * time) * (0.5 * std::erfc(d2 / std::sqrt(2.0))) -
        spot * (0.5 * std::erfc(d1 / std::sqrt(2.0)));
}
