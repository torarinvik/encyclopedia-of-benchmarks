module rmsprop

import math

const max_vector_length = 32
const max_parseable_input_length = 102

@[export: 'rmsprop']
pub fn rmsprop(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 5 || input_length > usize(max_parseable_input_length) { return -1 }
		count_value := input[0]
		if count_value != count_value || count_value < 0.0 || count_value > f64(max_vector_length) { return -1 }
		count := int(count_value)
		if count_value != f64(count) { return -1 }
		mode_value := input[1]
		if mode_value != 0.0 && mode_value != 1.0 { return -1 }
		mode := int(mode_value)
		expected_length := 5 + 2*count
		if mode == 1 { expected_length += count }
		if input_length != usize(expected_length) { return -1 }

		learning_rate, rho, epsilon := input[2], input[3], input[4]
		if learning_rate != learning_rate || learning_rate < 1e-6 || learning_rate > 1.0 { return -1 }
		if rho != rho || rho < 0.0 || rho > 0.99 { return -1 }
		if epsilon != epsilon || epsilon < 1e-8 || epsilon > 1.0 { return -1 }

		mut params := [max_vector_length]f64{}
		mut gradients := [max_vector_length]f64{}
		mut moving_avg := [max_vector_length]f64{}
		for index in 0 .. count {
			param, gradient := input[5+index], input[5+count+index]
			if param != param || param < -100.0 || param > 100.0 { return -1 }
			if gradient != gradient || gradient < -100.0 || gradient > 100.0 { return -1 }
			params[index] = param
			gradients[index] = gradient
		}
		if mode == 1 {
			for index in 0 .. count {
				value := input[5+2*count+index]
				if value != value || value < 0.0 || value > 10000.0 { return -1 }
				moving_avg[index] = value
			}
		}
		if output == nil || output_capacity < usize(2*count) { return -2 }

		for index in 0 .. count {
			gradient := gradients[index]
			updated_avg := rho*moving_avg[index] + (1.0-rho)*(gradient*gradient)
			moving_avg[index] = updated_avg
			params[index] = params[index] - (learning_rate / math.sqrt(updated_avg+epsilon))*gradient
		}
		for index in 0 .. count {
			output[index] = params[index]
			output[count+index] = moving_avg[index]
		}
		return i64(2*count)
	}
}
