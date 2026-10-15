package sphere

import "core:c"

@(export)
sphere :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length != 2 do return -1.0e300
	mode := input[0]
	radius := input[1]
	if (mode != 0 && mode != 1) || radius < 0 || radius > 1_000_000 do return -1.0e300
	r := f64(radius)
	r2 := r * r
	if mode == 0 do return (((r2 * r) * 3.14159265358979323846) * 4.0) / 3.0
	return (r2 * 3.14159265358979323846) * 4.0
}
