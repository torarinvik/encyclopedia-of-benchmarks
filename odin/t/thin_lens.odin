package thin_lens

import "core:c"

@(export)
thin_lens :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 3 do return -1.0e300
	operation, a, b := values[0], values[1], values[2]
	if a < -1000 || a > 1000 || b < -1000 || b > 1000 do return -1.0e300
	if operation == 0 {
		if a == 0 || b == 0 || a == b do return -1.0e300
		f, u := f64(a), f64(b)
		return 1.0 / ((1.0 / f) - (1.0 / u))
	}
	if operation == 1 {
		if b == 0 do return -1.0e300
		return f64(a) / f64(b)
	}
	if operation == 2 {
		if b != 0 do return -1.0e300
		if a > 0 do return 1.0
		return 0.0
	}
	return -1.0e300
}
