package kalman_filter

import "core:c"
import "core:math"

MAX_STEPS :: 12
MAX_PARSEABLE_LENGTH :: 64
SCALE :: 1_000_000.0

@(export)
kalman_filter :: proc "c" (input: [^]f64, length: c.size_t,
		output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > MAX_PARSEABLE_LENGTH do return -1
	for index := 0; index < int(length); index += 1 {
		if input[index] != input[index] || math.floor(input[index]) != input[index] do return -1
	}
	raw_steps := input[4]
	if raw_steps < 1.0 || raw_steps > f64(MAX_STEPS) do return -1
	steps := int(raw_steps)
	if length != c.size_t(5 + steps) do return -1
	if input[0] < -1_000_000_000.0 || input[0] > 1_000_000_000.0 ||
		input[1] < 0.0 || input[1] > 1_000_000_000_000.0 ||
		input[2] < 0.0 || input[2] > 1_000_000_000_000.0 ||
		input[3] < 1.0 || input[3] > 1_000_000_000_000.0 do return -1
	for index := 0; index < steps; index += 1 {
		measurement := input[5 + index]
		if measurement < -1_000_000_000.0 || measurement > 1_000_000_000.0 do return -1
	}

	required := 3 * steps
	if output == nil || output_capacity < c.size_t(required) do return -2
	estimate := input[0] / SCALE
	covariance := input[1] / SCALE
	process_noise := input[2] / SCALE
	measurement_noise := input[3] / SCALE
	for step := 0; step < steps; step += 1 {
		measurement := input[5 + step] / SCALE
		estimate += 0.0
		covariance += process_noise
		innovation_variance := covariance + measurement_noise
		gain := covariance / innovation_variance
		estimate += gain * (measurement - estimate)
		covariance = covariance * measurement_noise / innovation_variance
		output[3 * step] = estimate
		output[3 * step + 1] = covariance
		output[3 * step + 2] = gain
	}
	return i64(required)
}
