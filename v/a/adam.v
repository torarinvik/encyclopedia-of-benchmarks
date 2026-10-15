module adam

const max_steps = 256
const max_parameters = 16
const input_scale = 1_000_000_000.0
const output_scale = 1_000_000.0

fn adam_sqrt(value f64) f64 {
	if value <= 0.0 { return 0.0 }
	mut root := if value > 1.0 { value } else { 1.0 }
	for _ in 0 .. 80 { root = 0.5 * (root + value / root) }
	return root
}

@[export: 'adam']
pub fn adam(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 9 || length > 7 + max_parameters + max_steps * max_parameters { return -1 }
	unsafe {
		steps_value := input[0]
		parameter_count_value := input[1]
		learning_rate_value := input[2]
		beta1_value := input[3]
		beta2_value := input[4]
		epsilon_value := input[5]
		weight_decay_value := input[6]
		if steps_value < 1 || steps_value > max_steps || parameter_count_value < 1 || parameter_count_value > max_parameters { return -1 }
		steps := int(steps_value)
		parameter_count := int(parameter_count_value)
		if length != usize(7 + parameter_count + steps * parameter_count) ||
			learning_rate_value < 1 || learning_rate_value > 1000000000 ||
			beta1_value < 0 || beta1_value >= 1000000000 || beta2_value < 0 || beta2_value >= 1000000000 ||
			epsilon_value < 1 || epsilon_value > 10000000 || weight_decay_value < 0 || weight_decay_value > 100000000 { return -1 }
		for i in 0 .. parameter_count {
			if input[7 + i] < -1000000000000000 || input[7 + i] > 1000000000000000 { return -1 }
		}
		gradient_start := 7 + parameter_count
		for i in 0 .. steps * parameter_count {
			if input[gradient_start + i] < -1000000000000 || input[gradient_start + i] > 1000000000000 { return -1 }
		}
		output_count := steps * parameter_count
		if output_capacity < 8 * output_count { return -2 }
		learning_rate := f64(learning_rate_value) / input_scale
		beta1 := f64(beta1_value) / input_scale
		beta2 := f64(beta2_value) / input_scale
		epsilon := f64(epsilon_value) / input_scale
		weight_decay := f64(weight_decay_value) / input_scale
		mut parameters := [max_parameters]f64{}
		mut first_moment := [max_parameters]f64{}
		mut second_moment := [max_parameters]f64{}
		for i in 0 .. parameter_count { parameters[i] = f64(input[7 + i]) / input_scale }
		mut beta1_power := 1.0
		mut beta2_power := 1.0
		for step in 0 .. steps {
			beta1_power *= beta1
			beta2_power *= beta2
			for i in 0 .. parameter_count {
				gradient := f64(input[gradient_start + step * parameter_count + i]) / input_scale
				first_moment[i] = beta1 * first_moment[i] + (1.0 - beta1) * gradient
				second_moment[i] = beta2 * second_moment[i] + (1.0 - beta2) * (gradient * gradient)
				corrected_first := first_moment[i] / (1.0 - beta1_power)
				corrected_second := second_moment[i] / (1.0 - beta2_power)
				updated := parameters[i] - learning_rate * corrected_first /
					(adam_sqrt(corrected_second) + epsilon) - learning_rate * weight_decay * parameters[i]
				parameters[i] = updated
				encoded := i64(updated * output_scale)
				for byte in 0 .. 8 { output[8 * (step * parameter_count + i) + byte] = u8((encoded >> (8 * byte)) & 255) }
			}
		}
		return i64(output_count)
	}
}
