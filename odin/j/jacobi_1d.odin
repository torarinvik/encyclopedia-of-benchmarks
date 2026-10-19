package jacobi_1d

import "core:c"
import "core:math"

MAX_N :: 30
MAX_TSTEPS :: 20

@(export)
jacobi_1d :: proc "c" (input: [^]f64, length: c.size_t,
    output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	n_value := input[0]
	steps_value := input[1]
	if n_value != n_value || steps_value != steps_value || math.trunc(n_value) != n_value || math.trunc(steps_value) != steps_value || n_value < 1.0 || n_value > f64(MAX_N) || steps_value < 0.0 || steps_value > f64(MAX_TSTEPS) do return -1
	n := int(n_value)
	tsteps := int(steps_value)
	if output == nil || capacity < c.size_t(n) do return -2

	var a, b: [MAX_N]f64
	for i := 0; i < n; i += 1 {
		a[i] = (f64(i) + 2.0) / f64(n)
		b[i] = (f64(i) + 3.0) / f64(n)
	}
	for _t := 0; _t < tsteps; _t += 1 {
		if n > 2 {
			for i := 1; i + 1 < n; i += 1 { b[i] = 0.33333 * (a[i-1] + a[i] + a[i+1]) }
			for i := 1; i + 1 < n; i += 1 { a[i] = 0.33333 * (b[i-1] + b[i] + b[i+1]) }
		}
	}
	for i := 0; i < n; i += 1 { output[i] = a[i] }
	return i64(n)
}
