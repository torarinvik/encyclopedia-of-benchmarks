import math

const scale = 1_000_000.0

fn quantize(value f64) i64 {
	scaled := value * scale
	if scaled >= 0.0 { return i64(scaled + 0.5) }
	return i64(scaled - 0.5)
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'back_propagation_neural_network']
pub fn back_propagation_neural_network(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if length != 7 || isnil(input) { return -1 }
	x_q := unsafe { input[0] }
	target_q := unsafe { input[1] }
	hidden_weight_q := unsafe { input[2] }
	hidden_bias_q := unsafe { input[3] }
	output_weight_q := unsafe { input[4] }
	output_bias_q := unsafe { input[5] }
	rate_q := unsafe { input[6] }
	if x_q < -1_000_000 || x_q > 1_000_000 || target_q < -1_000_000 || target_q > 1_000_000 ||
		hidden_weight_q < -2_000_000 || hidden_weight_q > 2_000_000 ||
		hidden_bias_q < -2_000_000 || hidden_bias_q > 2_000_000 ||
		output_weight_q < -2_000_000 || output_weight_q > 2_000_000 ||
		output_bias_q < -2_000_000 || output_bias_q > 2_000_000 || rate_q < 1 || rate_q > 300_000 {
		return -1
	}
	x := f64(x_q) / scale
	target := f64(target_q) / scale
	hidden_weight := f64(hidden_weight_q) / scale
	hidden_bias := f64(hidden_bias_q) / scale
	output_weight := f64(output_weight_q) / scale
	output_bias := f64(output_bias_q) / scale
	learning_rate := f64(rate_q) / scale
	hidden_net := hidden_weight * x - hidden_bias
	hidden := 1.0 / (1.0 + math.exp(-hidden_net))
	output_net := output_weight * hidden - output_bias
	prediction := 1.0 / (1.0 + math.exp(-output_net))
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
	if capacity < 56 || isnil(output) { return -2 }
	mut result := [7]i64{}
	result[0] = quantize(loss)
	result[1] = quantize(hidden)
	result[2] = quantize(prediction)
	result[3] = quantize(updated_hidden_weight)
	result[4] = quantize(updated_hidden_bias)
	result[5] = quantize(updated_output_weight)
	result[6] = quantize(updated_output_bias)
	for index in 0 .. 7 { put_i64_le(mut output, index * 8, result[index]) }
	return 56
}
