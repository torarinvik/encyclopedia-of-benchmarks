module black_scholes_option_price

import math

@[export: 'black_scholes_option_price']
pub fn black_scholes_option_price(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 6 { return -1.0e300 }
	unsafe {
		kind := values[0]
		spot_units := values[1]
		strike_units := values[2]
		time_units := values[3]
		volatility_units := values[4]
		rate_units := values[5]
		if (kind != 0 && kind != 1) || spot_units < 10 || spot_units > 1000000000 || strike_units < 10 || strike_units > 1000000000 || time_units < 1 || time_units > 100000 || volatility_units < 1 || volatility_units > 5000 || rate_units < -1000 || rate_units > 1000 { return -1.0e300 }
		spot := f64(spot_units) / 1000.0
		strike := f64(strike_units) / 1000.0
		time := f64(time_units) / 1000.0
		volatility := f64(volatility_units) / 1000.0
		rate := f64(rate_units) / 1000.0
		sigma_sqrt_time := volatility * math.sqrt(time)
		d1 := (math.log(spot / strike) + (rate + volatility * volatility / 2.0) * time) / sigma_sqrt_time
		d2 := d1 - sigma_sqrt_time
		cdf_d1 := 0.5 * math.erfc(-d1 / math.sqrt(2.0))
		cdf_d2 := 0.5 * math.erfc(-d2 / math.sqrt(2.0))
		if kind == 0 { return spot * cdf_d1 - strike * math.exp(-rate * time) * cdf_d2 }
		return strike * math.exp(-rate * time) * (0.5 * math.erfc(d2 / math.sqrt(2.0))) - spot * (0.5 * math.erfc(d1 / math.sqrt(2.0)))
	}
}
