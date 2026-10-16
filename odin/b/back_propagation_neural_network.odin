package back_propagation_neural_network

import "core:c"
import "core:math"

SCALE :: 1_000_000.0

quantize :: proc "contextless" (value: f64) -> i64 {
	scaled := value * SCALE
	if scaled >= 0 { return i64(scaled + 0.5) }
	return i64(scaled - 0.5)
}

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
back_propagation_neural_network :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 7 { return -1 }
	x_q, target_q := input[0], input[1]
	hidden_weight_q, hidden_bias_q := input[2], input[3]
	output_weight_q, output_bias_q, rate_q := input[4], input[5], input[6]
	if x_q < -1_000_000 || x_q > 1_000_000 || target_q < -1_000_000 || target_q > 1_000_000 ||
		hidden_weight_q < -2_000_000 || hidden_weight_q > 2_000_000 ||
		hidden_bias_q < -2_000_000 || hidden_bias_q > 2_000_000 ||
		output_weight_q < -2_000_000 || output_weight_q > 2_000_000 ||
		output_bias_q < -2_000_000 || output_bias_q > 2_000_000 || rate_q < 1 || rate_q > 300_000 {
		return -1
	}
	x, target := f64(x_q) / SCALE, f64(target_q) / SCALE
	hidden_weight, hidden_bias := f64(hidden_weight_q) / SCALE, f64(hidden_bias_q) / SCALE
	output_weight, output_bias := f64(output_weight_q) / SCALE, f64(output_bias_q) / SCALE
	learning_rate := f64(rate_q) / SCALE
	hidden_net := hidden_weight * x - hidden_bias
	hidden := 1.0 / (1.0 + math.exp_f64(-hidden_net))
	output_net := output_weight * hidden - output_bias
	prediction := 1.0 / (1.0 + math.exp_f64(-output_net))
	difference := target - prediction
	loss := difference * difference
	loss_gradient := 2.0 * (prediction - target)
	output_delta := loss_gradient * prediction * (1.0 - prediction)
	output_weight_gradient := output_delta * hidden
	output_bias_gradient := -output_delta
	hidden_gradient := output_delta * output_weight
	hidden_delta := hidden_gradient * hidden * (1.0 - hidden)
	hidden_weight_gradient := hidden_delta * x
	hidden_bias_gradient := -hidden_delta
	updated_hidden_weight := hidden_weight - learning_rate * hidden_weight_gradient
	updated_hidden_bias := hidden_bias - learning_rate * hidden_bias_gradient
	updated_output_weight := output_weight - learning_rate * output_weight_gradient
	updated_output_bias := output_bias - learning_rate * output_bias_gradient

	if output == nil || capacity < 56 { return -2 }
	result := [7]i64{quantize(loss), quantize(hidden), quantize(prediction),
		quantize(updated_hidden_weight), quantize(updated_hidden_bias),
		quantize(updated_output_weight), quantize(updated_output_bias)}
	for index := 0; index < 7; index += 1 { put_i64_le(output, index * 8, result[index]) }
	return 56
}
