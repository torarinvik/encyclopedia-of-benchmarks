package neville

import "core:c"

@(export)
neville :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	invalid := -1.0e300
	if values == nil || length < 4 || length > 34 do return invalid
	count, target_i := values[0], values[1]
	if count < 1 || count > 16 || length != c.size_t(2 * count + 2) || target_i < -1_000_000 || target_i > 1_000_000 do return invalid
	var x, p: [16]f64
	for i := 0; i < int(count); i += 1 {
		xi, yi := values[2 + 2 * i], values[3 + 2 * i]
		if xi < -1_000_000 || xi > 1_000_000 || yi < -1_000_000 || yi > 1_000_000 do return invalid
		for j := 0; j < i; j += 1 { if values[2 + 2 * j] == xi do return invalid }
		x[i] = f64(xi); p[i] = f64(yi)
	}
	target := f64(target_i)
	for k := 1; k < int(count); k += 1 {
		for i := 0; i < int(count) - k; i += 1 { p[i] = ((target - x[i+k]) * p[i] + (x[i] - target) * p[i+1]) / (x[i] - x[i+k]) }
	}
	return p[0]
}
