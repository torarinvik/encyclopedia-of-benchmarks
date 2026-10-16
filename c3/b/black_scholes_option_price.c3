module black_scholes_option_price;

const double INVALID_RESULT = -1.0e300;
extern fn double sqrt(double value);
extern fn double log(double value);
extern fn double exp(double value);
extern fn double erfc(double value);

fn double black_scholes_option_price(long* values, usz length) @export("black_scholes_option_price") {
    if (values == null || length != 6) return INVALID_RESULT;
    long kind = values[0], spot_units = values[1], strike_units = values[2];
    long time_units = values[3], volatility_units = values[4], rate_units = values[5];
    if ((kind != 0 && kind != 1) || spot_units < 10 || spot_units > 1000000000 ||
        strike_units < 10 || strike_units > 1000000000 || time_units < 1 || time_units > 100000 ||
        volatility_units < 1 || volatility_units > 5000 || rate_units < -1000 || rate_units > 1000)
        return INVALID_RESULT;
    double spot = (double)spot_units / 1000.0;
    double strike = (double)strike_units / 1000.0;
    double time = (double)time_units / 1000.0;
    double volatility = (double)volatility_units / 1000.0;
    double rate = (double)rate_units / 1000.0;
    double sigma_sqrt_time = volatility * sqrt(time);
    double d1 = (log(spot / strike) + (rate + volatility * volatility / 2.0) * time) / sigma_sqrt_time;
    double d2 = d1 - sigma_sqrt_time;
    double cdf_d1 = 0.5 * erfc(-d1 / sqrt(2.0));
    double cdf_d2 = 0.5 * erfc(-d2 / sqrt(2.0));
    if (kind == 0) return spot * cdf_d1 - strike * exp(-rate * time) * cdf_d2;
    return strike * exp(-rate * time) * (0.5 * erfc(d2 / sqrt(2.0))) - spot * (0.5 * erfc(d1 / sqrt(2.0)));
}
