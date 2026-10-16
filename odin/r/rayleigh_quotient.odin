package rayleigh_quotient

import "core:c"
import "core:math"

@(export)
rayleigh_quotient :: proc "c" (values: [^]f64, length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if values == nil || length < c.size_t(1) || length > c.size_t(273) do return -1
	for i := 0; i < int(length); i += 1 {
		if values[i] != values[i] do return -1
	}
	n_value := values[0]
	if n_value < 1.0 || n_value > 16.0 || math.floor_f64(n_value) != n_value do return -1
	n := int(n_value)
	if length != c.size_t(1 + n*n + n) do return -1
	matrix_start := 1
	vector_start := 1 + n*n

	for row := 0; row < n; row += 1 {
		for col := 0; col < n; col += 1 {
			value := values[matrix_start + row*n + col]
			if value < -1000.0 || value > 1000.0 do return -1
			if col > row && value != values[matrix_start + col*n + row] do return -1
		}
	}

	denominator: f64 = 0.0
	for i := 0; i < n; i += 1 {
		value := values[vector_start + i]
		if value < -100.0 || value > 100.0 do return -1
		denominator += value * value
	}
	if denominator <= 0.0 do return -1

	numerator: f64 = 0.0
	for col := 0; col < n; col += 1 {
		v_star_dot: f64 = 0.0
		for row := 0; row < n; row += 1 {
			v_star_dot += values[vector_start + row] * values[matrix_start + row*n + col]
		}
		numerator += v_star_dot * values[vector_start + col]
	}
	quotient := numerator / denominator
	if output == nil || capacity < c.size_t(1) do return -2
	output[0] = quotient
	return 1
}
