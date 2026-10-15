package adam

import "core:c"

MAX_STEPS :: 256
MAX_PARAMETERS :: 16
INPUT_SCALE :: 1_000_000_000.0
OUTPUT_SCALE :: 1_000_000.0

adam_sqrt :: proc "contextless" (value: f64) -> f64 {
	if value <= 0.0 do return 0.0
	root := value
	if root < 1.0 do root = 1.0
	for iteration := 0; iteration < 80; iteration += 1 {
		root = 0.5 * (root + value / root)
	}
	return root
}

@(export)
adam :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	max_input_length := c.size_t(7 + MAX_PARAMETERS + MAX_STEPS * MAX_PARAMETERS)
	if input == nil || length < 9 || length > max_input_length do return -1
	steps_value, parameter_count_value := input[0], input[1]
	learning_rate_value, beta1_value, beta2_value := input[2], input[3], input[4]
	epsilon_value, weight_decay_value := input[5], input[6]
	if steps_value < 1 || steps_value > MAX_STEPS || parameter_count_value < 1 || parameter_count_value > MAX_PARAMETERS do return -1
	steps, parameter_count := int(steps_value), int(parameter_count_value)
	invalid_header := length != c.size_t(7 + parameter_count + steps * parameter_count) ||
		learning_rate_value < 1 || learning_rate_value > 1_000_000_000 ||
		beta1_value < 0 || beta1_value >= 1_000_000_000 || beta2_value < 0 || beta2_value >= 1_000_000_000 ||
		epsilon_value < 1 || epsilon_value > 10_000_000 || weight_decay_value < 0 || weight_decay_value > 100_000_000
	if invalid_header do return -1
	for i := 0; i < parameter_count; i += 1 {
		if input[7 + i] < -1_000_000_000_000_000 || input[7 + i] > 1_000_000_000_000_000 do return -1
	}
	gradient_start := 7 + parameter_count
	for i := 0; i < steps * parameter_count; i += 1 {
		if input[gradient_start + i] < -1_000_000_000_000 || input[gradient_start + i] > 1_000_000_000_000 do return -1
	}
	output_count := steps * parameter_count
	if output == nil || output_capacity < c.size_t(8 * output_count) do return -2

	learning_rate := f64(learning_rate_value) / INPUT_SCALE
	beta1 := f64(beta1_value) / INPUT_SCALE
	beta2 := f64(beta2_value) / INPUT_SCALE
	epsilon := f64(epsilon_value) / INPUT_SCALE
	weight_decay := f64(weight_decay_value) / INPUT_SCALE
	params := [MAX_PARAMETERS]f64{}
	first_moment := [MAX_PARAMETERS]f64{}
	second_moment := [MAX_PARAMETERS]f64{}
	for i := 0; i < parameter_count; i += 1 do params[i] = f64(input[7 + i]) / INPUT_SCALE
	beta1_power, beta2_power := 1.0, 1.0
	for step := 0; step < steps; step += 1 {
		beta1_power *= beta1
		beta2_power *= beta2
		for i := 0; i < parameter_count; i += 1 {
			gradient := f64(input[gradient_start + step * parameter_count + i]) / INPUT_SCALE
			first_moment[i] = beta1 * first_moment[i] + (1.0 - beta1) * gradient
			second_moment[i] = beta2 * second_moment[i] + (1.0 - beta2) * (gradient * gradient)
			corrected_first := first_moment[i] / (1.0 - beta1_power)
			corrected_second := second_moment[i] / (1.0 - beta2_power)
			updated := params[i] - learning_rate * corrected_first /
				(adam_sqrt(corrected_second) + epsilon) - learning_rate * weight_decay * params[i]
			params[i] = updated
			encoded := i64(updated * OUTPUT_SCALE)
			for byte := 0; byte < 8; byte += 1 {
				output[8 * (step * parameter_count + i) + byte] = u8((encoded >> u64(byte * 8)) & 255)
			}
		}
	}
	return i64(output_count)
}
