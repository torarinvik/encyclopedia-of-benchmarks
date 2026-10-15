module real_and_reactive_power

import math

@[export: 'real_and_reactive_power']
pub fn real_and_reactive_power(values &i64, length usize) f64 {
	if length != 3 { return -1.0e300 }
	unsafe {
		operation := values[0]
		apparent_power := values[1]
		factor_units := values[2]
		if (operation != 0 && operation != 1) || apparent_power < -1000000000 || apparent_power > 1000000000 || factor_units < -10000 || factor_units > 10000 {
			return -1.0e300
		}
		power_factor := f64(factor_units) / 10000.0
		if operation == 0 { return f64(apparent_power) * power_factor }
		return f64(apparent_power) * math.sqrt(1.0 - math.pow(power_factor, 2.0))
	}
}
