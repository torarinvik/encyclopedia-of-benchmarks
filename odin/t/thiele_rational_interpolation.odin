package thiele_rational_interpolation

import "core:c"
import "core:math"

MAX_N :: 6
MAX_INPUT :: 15
GRID_DENOMINATOR :: 18014398509481984.0
MIN_NODE_SEPARATION :: 0.0625
LOW_MAGNITUDE :: 0.03125000023283064365386963
MAGNITUDE_CAP :: 63.99999999976716935634613037

grid_value :: proc(value: f64) -> bool {
	if !math.is_finite(value) || value < -8.0 || value > 8.0 do return false
	scaled := value * GRID_DENOMINATOR
	return math.trunc(scaled) == scaled
}

guarded_magnitude :: proc(value: f64) -> bool {
	return (value > LOW_MAGNITUDE && value < MAGNITUDE_CAP) ||
		(value < -LOW_MAGNITUDE && value > -MAGNITUDE_CAP)
}

below_cap :: proc(value: f64) -> bool {
	return math.is_finite(value) && value > -MAGNITUDE_CAP && value < MAGNITUDE_CAP
}

@(export)
thiele_rational_interpolation :: proc "c" (input: [^]f64, input_length: c.size_t,
		output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 4 || input_length > c.size_t(MAX_INPUT) do return -1
	n_value := input[0]
	if !grid_value(n_value) || math.trunc(n_value) != n_value || n_value < 1.0 || n_value > 6.0 do return -1
	n := int(n_value)
	if input_length != c.size_t(2 + 2 * n) do return -1

	x: [MAX_N]f64
	y: [MAX_N]f64
	difference: [MAX_N * MAX_N]f64
	for i := 0; i < n; i += 1 {
		x[i] = input[1 + 2 * i]
		y[i] = input[2 + 2 * i]
		if !grid_value(x[i]) || !grid_value(y[i]) do return -1
		for j := 0; j < i; j += 1 {
			gap := x[i] - x[j]
			if gap == 0.0 || gap < MIN_NODE_SEPARATION && gap > -MIN_NODE_SEPARATION do return -1
		}
		difference[i] = y[i]
	}
	query := input[input_length - 1]
	if !grid_value(query) do return -1

	for order := 1; order < n; order += 1 {
		for endpoint := order; endpoint < n; endpoint += 1 {
			denominator := difference[(order - 1) * MAX_N + order - 1] - difference[(order - 1) * MAX_N + endpoint]
			if !math.is_finite(denominator) || !guarded_magnitude(denominator) do return -1
			value := (x[order - 1] - x[endpoint]) / denominator
			if !below_cap(value) do return -1
			difference[order * MAX_N + endpoint] = value
		}
		if !guarded_magnitude(difference[order * MAX_N + order]) do return -1
	}

	result := f64(0.0)
	at_node := false
	for i := 0; i < n; i += 1 {
		if query == x[i] { result = y[i]; at_node = true; break }
	}
	if !at_node && n == 1 do result = y[0]
	if !at_node && n > 1 {
		tail := difference[(n - 1) * MAX_N + n - 1]
		order := n - 2
		for order > 0 {
			if !guarded_magnitude(tail) do return -1
			tail = difference[order * MAX_N + order] + (query - x[order]) / tail
			if !below_cap(tail) do return -1
			order -= 1
		}
		if !guarded_magnitude(tail) do return -1
		result = y[0] + (query - x[0]) / tail
	}
	if !below_cap(result) do return -1
	if output == nil || output_capacity < 1 do return -2
	output[0] = result
	return 1
}
