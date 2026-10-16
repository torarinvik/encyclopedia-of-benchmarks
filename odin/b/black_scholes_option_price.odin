package black_scholes_option_price

import "core:c"
import "core:math"

@(export)
black_scholes_option_price :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 6 do return -1.0e300
	kind, spot_units, strike_units := values[0], values[1], values[2]
	time_units, volatility_units, rate_units := values[3], values[4], values[5]
	if (kind != 0 && kind != 1) || spot_units < 10 || spot_units > 1000000000 || strike_units < 10 || strike_units > 1000000000 || time_units < 1 || time_units > 100000 || volatility_units < 1 || volatility_units > 5000 || rate_units < -1000 || rate_units > 1000 do return -1.0e300
	spot := f64(spot_units) / 1000.0
	strike := f64(strike_units) / 1000.0
	time := f64(time_units) / 1000.0
	volatility := f64(volatility_units) / 1000.0
	rate := f64(rate_units) / 1000.0
	sigma_sqrt_time := volatility * math.sqrt(time)
	d1 := (math.ln(spot / strike) + (rate + volatility * volatility / 2.0) * time) / sigma_sqrt_time
	d2 := d1 - sigma_sqrt_time
	cdf_d1 := 0.5 * math.erfc(-d1 / math.sqrt(2.0))
	cdf_d2 := 0.5 * math.erfc(-d2 / math.sqrt(2.0))
	if kind == 0 do return spot * cdf_d1 - strike * math.exp(-rate * time) * cdf_d2
	return strike * math.exp(-rate * time) * (0.5 * math.erfc(d2 / math.sqrt(2.0))) - spot * (0.5 * math.erfc(d1 / math.sqrt(2.0)))
}
