package nth_root

import "core:math"

INVALID_RESULT :: -1.0e300

@(export)
nth_root :: proc "c" (radicand, index, tolerance: f64) -> f64 {
	if math.isnan_f64(radicand) || math.isnan_f64(index) || math.isnan_f64(tolerance) ||
		radicand < 0.5 || radicand > 1000.0 || index < 3.0 || index > 8.0 ||
		index != math.floor_f64(index) || tolerance < 1.0e-12 || tolerance > 1.0e-3 do return INVALID_RESULT
	new_approximation := radicand
	old_approximation := new_approximation + tolerance + 0.1
	for tolerance <= math.abs_f64(old_approximation-new_approximation) {
		old_approximation = new_approximation
		first_summand := (index-1.0)/index * old_approximation
		second_summand := radicand / (index * math.pow_f64(old_approximation,index-1.0))
		new_approximation = first_summand + second_summand
	}
	return new_approximation
}
