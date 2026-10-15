package real_and_reactive_power

import "core:c"
import "core:math"

@(export)
real_and_reactive_power :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 3 do return -1.0e300
	operation := values[0]
	apparent_power := values[1]
	factor_units := values[2]
	if (operation != 0 && operation != 1) || apparent_power < -1000000000 || apparent_power > 1000000000 || factor_units < -10000 || factor_units > 10000 do return -1.0e300
	power_factor := f64(factor_units) / 10000.0
	if operation == 0 do return f64(apparent_power) * power_factor
	return f64(apparent_power) * math.sqrt(1.0 - math.pow(power_factor, 2.0))
}
