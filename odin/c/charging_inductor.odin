package charging_inductor

import "core:c"
import "core:math"

INVALID_RESULT :: -1.0e300

round_three_python :: proc "contextless" (value: f64) -> f64 {
	if value == 0.0 do return value
	negative := value < 0.0
	normalized := if negative do -value else value
	exponent := 0
	for normalized >= 1.0 { normalized *= 0.5; exponent += 1 }
	for normalized < 0.5 { normalized *= 2.0; exponent -= 1 }
	significand := u64(normalized * 9_007_199_254_740_992.0)
	numerator := significand * 1000
	shift := 53 - exponent
	milliunits: u64 = 0
	if shift < 0 { milliunits = numerator << u32(-shift) }
	else if shift == 0 { milliunits = numerator }
	else if shift < 64 {
		denominator := u64(1) << u32(shift)
		milliunits = numerator >> u32(shift)
		remainder := numerator & (denominator - 1)
		half := denominator >> 1
		if remainder > half || (remainder == half && milliunits & 1 != 0) { milliunits += 1 }
	}
	rounded := f64(milliunits) / 1000.0
	if negative do return -rounded
	return rounded
}

@(export)
charging_inductor :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 4 do return INVALID_RESULT
	voltage_micro, resistance_micro := values[0], values[1]
	inductance_micro, time_micro := values[2], values[3]
	if voltage_micro < 1 || voltage_micro > 1_000_000_000_000 ||
		resistance_micro < 10_000 || resistance_micro > 1_000_000_000_000_000 ||
		inductance_micro < 1 || inductance_micro > 1_000_000_000_000 ||
		time_micro < -1_000_000_000_000 || time_micro > 1_000_000_000_000 do return INVALID_RESULT
	source_voltage := f64(voltage_micro) / 1_000_000.0
	resistance := f64(resistance_micro) / 1_000_000.0
	inductance := f64(inductance_micro) / 1_000_000.0
	time_sec := f64(time_micro) / 1_000_000.0
	exponent := (-time_sec * resistance) / inductance
	if exponent > 10.0 do return INVALID_RESULT
	return round_three_python(source_voltage / resistance * (1.0 - math.exp_f64(exponent)))
}
