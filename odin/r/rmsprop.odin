package rmsprop

import "core:c"
import "core:math"

MAX_VECTOR_LENGTH :: 32
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(102)

rmsprop :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 5 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	count_value := input[0]
	if count_value != count_value || count_value < 0.0 || count_value > f64(MAX_VECTOR_LENGTH) do return -1
	count := int(count_value)
	if count_value != f64(count) do return -1
	mode_value := input[1]
	if mode_value != 0.0 && mode_value != 1.0 do return -1
	mode := int(mode_value)
	expected_length := 5 + 2*count
	if mode == 1 do expected_length += count
	if input_length != c.size_t(expected_length) do return -1

	learning_rate, rho, epsilon := input[2], input[3], input[4]
	if learning_rate != learning_rate || learning_rate < 1e-6 || learning_rate > 1.0 do return -1
	if rho != rho || rho < 0.0 || rho > 0.99 do return -1
	if epsilon != epsilon || epsilon < 1e-8 || epsilon > 1.0 do return -1

	params: [MAX_VECTOR_LENGTH]f64
	gradients: [MAX_VECTOR_LENGTH]f64
	moving_avg: [MAX_VECTOR_LENGTH]f64
	for index := 0; index < count; index += 1 {
		param, gradient := input[5+index], input[5+count+index]
		if param != param || param < -100.0 || param > 100.0 do return -1
		if gradient != gradient || gradient < -100.0 || gradient > 100.0 do return -1
		params[index] = param
		gradients[index] = gradient
		moving_avg[index] = 0.0
	}
	if mode == 1 {
		for index := 0; index < count; index += 1 {
			value := input[5+2*count+index]
			if value != value || value < 0.0 || value > 10000.0 do return -1
			moving_avg[index] = value
		}
	}
	if output == nil || output_capacity < c.size_t(2*count) do return -2

	for index := 0; index < count; index += 1 {
		gradient := gradients[index]
		updated_avg := rho*moving_avg[index] + (1.0-rho)*(gradient*gradient)
		moving_avg[index] = updated_avg
		params[index] = params[index] - (learning_rate / math.sqrt_f64(updated_avg+epsilon))*gradient
	}
	for index := 0; index < count; index += 1 {
		output[index] = params[index]
		output[count+index] = moving_avg[index]
	}
	return i64(2*count)
}
