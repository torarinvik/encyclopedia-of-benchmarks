package adagrad

import "core:c"

MAX_STEPS :: 256
MAX_GROUPS :: 16
INPUT_SCALE :: 1_000_000_000.0
OUTPUT_SCALE :: 1_000_000.0

adagrad_sqrt :: proc "contextless" (value: f64) -> f64 {
	if value <= 0.0 do return 0.0
	root := value
	if root < 1.0 do root = 1.0
	for iteration := 0; iteration < 80; iteration += 1 {
		root = 0.5 * (root + value / root)
	}
	return root
}

@(export)
adagrad :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 6 || length > c.size_t(3 + 3 * MAX_STEPS) do return -1
	steps_value, learning_rate_value, epsilon_value := input[0], input[1], input[2]
	if steps_value < 1 || steps_value > MAX_STEPS || length != c.size_t(3 + 3 * int(steps_value)) ||
		learning_rate_value < 1 || learning_rate_value > 1_000_000_000 || epsilon_value < 1 || epsilon_value > 10_000_000 do return -1
	steps := int(steps_value)
	for step := 0; step < steps; step += 1 {
		id, parameter, gradient := input[3 + 3 * step], input[4 + 3 * step], input[5 + 3 * step]
		if id < 0 || id >= MAX_GROUPS || parameter < -1_000_000_000_000_000 || parameter > 1_000_000_000_000_000 ||
			gradient < -1_000_000_000_000 || gradient > 1_000_000_000_000 do return -1
	}
	if output == nil || output_capacity < c.size_t(8 * steps) do return -2

	learning_rate, epsilon := f64(learning_rate_value) / INPUT_SCALE, f64(epsilon_value) / INPUT_SCALE
	var accumulated: [MAX_GROUPS]f64
	for step := 0; step < steps; step += 1 {
		id := int(input[3 + 3 * step])
		parameter := f64(input[4 + 3 * step]) / INPUT_SCALE
		gradient := f64(input[5 + 3 * step]) / INPUT_SCALE
		accumulated[id] += gradient * gradient
		updated := parameter - learning_rate / (adagrad_sqrt(accumulated[id]) + epsilon) * gradient
		encoded := i64(updated * OUTPUT_SCALE)
		for byte := 0; byte < 8; byte += 1 {
			output[8 * step + byte] = u8((encoded >> (8 * byte)) & 255)
		}
	}
	return i64(steps)
}
