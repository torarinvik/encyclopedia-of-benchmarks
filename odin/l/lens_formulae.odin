package lens_formulae

import "core:c"

@(export)
lens_formulae :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 3 do return -1.0e300
	operation := values[0]
	first := values[1]
	second := values[2]
	if operation < 0 || operation > 2 || first == 0 || second == 0 || first < -1_000_000 || first > 1_000_000 || second < -1_000_000 || second > 1_000_000 do return -1.0e300
	if operation == 0 {
		if first == second do return -1.0e300
		return 1.0 / ((1.0 / f64(second)) - (1.0 / f64(first)))
	}
	if operation == 1 {
		if first == second do return -1.0e300
		return 1.0 / ((1.0 / f64(second)) - (1.0 / f64(first)))
	}
	if first == -second do return -1.0e300
	return 1.0 / ((1.0 / f64(second)) + (1.0 / f64(first)))
}
