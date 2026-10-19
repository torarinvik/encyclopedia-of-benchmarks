package jacobi_2d

import "core:c"
import "core:math"

MAX_N :: 30
MAX_TSTEPS :: 20

@(export)
jacobi_2d :: proc "c" (input: [^]f64, length: c.size_t,
    output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	n_value := input[0]
	steps_value := input[1]
	if n_value != n_value || steps_value != steps_value || math.trunc(n_value) != n_value || math.trunc(steps_value) != steps_value || n_value < 1.0 || n_value > f64(MAX_N) || steps_value < 0.0 || steps_value > f64(MAX_TSTEPS) do return -1
	n := int(n_value)
	tsteps := int(steps_value)
	count := n * n
	if output == nil || capacity < c.size_t(count) do return -2

	var a, b: [MAX_N][MAX_N]f64
	for i := 0; i < n; i += 1 {
		for j := 0; j < n; j += 1 {
			a[i][j] = (f64(i) * f64(j + 2) + 2.0) / f64(n)
			b[i][j] = (f64(i) * f64(j + 3) + 3.0) / f64(n)
		}
	}
	for _t := 0; _t < tsteps; _t += 1 {
		if n > 2 {
			for i := 1; i + 1 < n; i += 1 {
				for j := 1; j + 1 < n; j += 1 {
					b[i][j] = 0.2 * (a[i][j] + a[i][j-1] + a[i][j+1] + a[i+1][j] + a[i-1][j])
				}
			}
			for i := 1; i + 1 < n; i += 1 {
				for j := 1; j + 1 < n; j += 1 {
					a[i][j] = 0.2 * (b[i][j] + b[i][j-1] + b[i][j+1] + b[i+1][j] + b[i-1][j])
				}
			}
		}
	}
	for i := 0; i < n; i += 1 {
		for j := 0; j < n; j += 1 { output[i*n+j] = a[i][j] }
	}
	return i64(count)
}
