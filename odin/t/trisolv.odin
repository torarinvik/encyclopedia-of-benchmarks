package trisolv

import "core:c"
import "core:math"

MAX_N :: 40

@(export)
trisolv :: proc "c" (input: [^]f64, length: c.size_t,
    output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length != 1 do return -1
	n_value := input[0]
	if n_value != n_value || math.trunc(n_value) != n_value || n_value < 1.0 || n_value > f64(MAX_N) do return -1
	n := int(n_value)
	if output == nil || capacity < c.size_t(n) do return -2

	var lower: [MAX_N][MAX_N]f64
	var b, x: [MAX_N]f64
	for i := 0; i < n; i += 1 {
		b[i] = f64(i)
		for j := 0; j <= i; j += 1 {
			lower[i][j] = f64(i + n - j + 1) * 2.0 / f64(n)
		}
	}
	for i := 0; i < n; i += 1 {
		x[i] = b[i]
		for j := 0; j < i; j += 1 { x[i] -= lower[i][j] * x[j] }
		x[i] /= lower[i][i]
	}
	for i := 0; i < n; i += 1 { output[i] = x[i] }
	return i64(n)
}
