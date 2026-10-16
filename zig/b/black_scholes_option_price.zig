/// Black-Scholes European call/put price. Inputs use thousandths.
const std = @import("std");

export fn black_scholes_option_price(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 6) return -1.0e300;
    const kind = values[0];
    const spot_units = values[1];
    const strike_units = values[2];
    const time_units = values[3];
    const volatility_units = values[4];
    const rate_units = values[5];
    if ((kind != 0 and kind != 1) or spot_units < 10 or spot_units > 1_000_000_000 or
        strike_units < 10 or strike_units > 1_000_000_000 or time_units < 1 or time_units > 100_000 or
        volatility_units < 1 or volatility_units > 5_000 or rate_units < -1_000 or rate_units > 1_000)
        return -1.0e300;
    const spot = @as(f64, @floatFromInt(spot_units)) / 1_000.0;
    const strike = @as(f64, @floatFromInt(strike_units)) / 1_000.0;
    const time = @as(f64, @floatFromInt(time_units)) / 1_000.0;
    const volatility = @as(f64, @floatFromInt(volatility_units)) / 1_000.0;
    const rate = @as(f64, @floatFromInt(rate_units)) / 1_000.0;
    const sigma_sqrt_time = volatility * @sqrt(time);
    const d1 = (@log(spot / strike) + (rate + volatility * volatility / 2.0) * time) / sigma_sqrt_time;
    const d2 = d1 - sigma_sqrt_time;
    const cdf_d1 = 0.5 * std.math.erfc(-d1 / @sqrt(2.0));
    const cdf_d2 = 0.5 * std.math.erfc(-d2 / @sqrt(2.0));
    if (kind == 0) return spot * cdf_d1 - strike * @exp(-rate * time) * cdf_d2;
    return strike * @exp(-rate * time) * (0.5 * std.math.erfc(d2 / @sqrt(2.0))) -
        spot * (0.5 * std.math.erfc(d1 / @sqrt(2.0)));
}
