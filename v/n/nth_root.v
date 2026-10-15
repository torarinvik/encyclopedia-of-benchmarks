module nth_root

import math

const invalid_result = -1.0e300

@[export: 'nth_root']
pub fn nth_root(radicand f64, index f64, tolerance f64) f64 {
	if math.is_nan(radicand) || math.is_inf(radicand, false) || math.is_nan(index) || math.is_inf(index, false) || math.is_nan(tolerance) || math.is_inf(tolerance, false) ||
		radicand < 0.5 || radicand > 1000.0 || index < 3.0 || index > 8.0 ||
		index != math.floor(index) || tolerance < 1.0e-12 || tolerance > 1.0e-3 {
		return invalid_result
	}
	mut new_approximation := radicand
	mut old_approximation := new_approximation + tolerance + 0.1
	for tolerance <= math.abs(old_approximation - new_approximation) {
		old_approximation = new_approximation
		first_summand := (index - 1.0) / index * old_approximation
		second_summand := radicand / (index * math.pow(old_approximation, index - 1.0))
		new_approximation = first_summand + second_summand
	}
	return new_approximation
}
