package durbin

import "core:c"
import "core:math"

MAX_N :: 40

@(export)
durbin :: proc "c" (input: [^]f64, length: c.size_t,
    output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length != 1 do return -1
	n_value := input[0]
	if n_value != n_value || math.trunc(n_value) != n_value || n_value < 1.0 || n_value > f64(MAX_N) do return -1
	n := int(n_value)
	if output == nil || capacity < c.size_t(n) do return -2

	var r, y, z: [MAX_N]f64
	for i := 0; i < n; i += 1 { r[i] = f64(n + 1 - i) }
	y[0] = -r[0]
	beta := 1.0
	alpha := -r[0]
	for k := 1; k < n; k += 1 {
		beta = (1.0 - alpha * alpha) * beta
		sum := 0.0
		for i := 0; i < k; i += 1 { sum += r[k-i-1] * y[i] }
		alpha = -(r[k] + sum) / beta
		for i := 0; i < k; i += 1 { z[i] = y[i] + alpha * y[k-i-1] }
		for i := 0; i < k; i += 1 { y[i] = z[i] }
		y[k] = alpha
	}
	for i := 0; i < n; i += 1 { output[i] = y[i] }
	return i64(n)
}
