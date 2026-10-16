package time_conversions

import "core:math"

seconds_factor :: proc(code: f64) -> f64 {
	if code == 0.0 do return 1.0
	if code == 1.0 do return 60.0
	if code == 2.0 do return 3600.0
	if code == 3.0 do return 86400.0
	if code == 4.0 do return 604800.0
	if code == 5.0 do return 2629800.0
	if code == 6.0 do return 31557600.0
	return 0.0
}

inverse_factor :: proc(code: f64) -> f64 {
	if code == 0.0 do return 1.0
	if code == 1.0 do return 0.016666666666666666
	if code == 2.0 do return 0.0002777777777777778
	if code == 3.0 do return 0.000011574074074074073
	if code == 4.0 do return 0.0000016534391534391535
	if code == 5.0 do return 0.0000003802570537683474
	if code == 6.0 do return 0.00000003168808781402895
	return 0.0
}

round_three_ties_even :: proc(value: f64) -> f64 {
	scaled := value * 1000.0
	lower := math.floor(scaled)
	residual := math.fused_mul_add(value, 1000.0, -scaled)
	fraction := scaled - lower
	rounded := lower
	if fraction > 0.5 || (fraction == 0.5 && (residual > 0.0 || (residual == 0.0 && i64(lower) % 2 != 0))) do rounded = lower + 1.0
	return rounded / 1000.0
}

@(export)
time_conversions :: proc "c" (time_value, from_code, to_code: f64) -> f64 {
	if math.is_nan(time_value) || time_value < 0.0 || time_value > 10000.0 do return -1e300
	source := seconds_factor(from_code)
	inverse := inverse_factor(to_code)
	if source == 0.0 || inverse == 0.0 do return -1e300
	scaled := time_value * source
	return round_three_ties_even(scaled * inverse)
}
