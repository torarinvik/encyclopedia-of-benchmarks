module time_conversions

import math

#include <math.h>
fn C.fma(first f64, second f64, third f64) f64

fn seconds_factor(code f64) f64 {
	if code == 0.0 { return 1.0 }
	if code == 1.0 { return 60.0 }
	if code == 2.0 { return 3600.0 }
	if code == 3.0 { return 86400.0 }
	if code == 4.0 { return 604800.0 }
	if code == 5.0 { return 2629800.0 }
	if code == 6.0 { return 31557600.0 }
	return 0.0
}

fn inverse_factor(code f64) f64 {
	if code == 0.0 { return 1.0 }
	if code == 1.0 { return 0.016666666666666666 }
	if code == 2.0 { return 0.0002777777777777778 }
	if code == 3.0 { return 0.000011574074074074073 }
	if code == 4.0 { return 0.0000016534391534391535 }
	if code == 5.0 { return 0.0000003802570537683474 }
	if code == 6.0 { return 0.00000003168808781402895 }
	return 0.0
}

fn round_three_ties_even(value f64) f64 {
	scaled := value * 1000.0
	lower := math.floor(scaled)
	fraction := scaled - lower
	residual := C.fma(value, 1000.0, -scaled)
	mut rounded := lower
	if fraction > 0.5 || (fraction == 0.5 && (residual > 0.0 || (residual == 0.0 && i64(lower) % 2 != 0))) { rounded = lower + 1.0 }
	return rounded / 1000.0
}

@[export: 'time_conversions']
pub fn time_conversions(time_value f64, from_code f64, to_code f64) f64 {
	if math.is_nan(time_value) || time_value < 0.0 || time_value > 10000.0 { return -1e300 }
	source := seconds_factor(from_code)
	inverse := inverse_factor(to_code)
	if source == 0.0 || inverse == 0.0 { return -1e300 }
	scaled := time_value * source
	return round_three_ties_even(scaled * inverse)
}
