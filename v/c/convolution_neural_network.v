module main

import math

const max_image_side = 8
const max_kernel_side = 4
const max_filters = 3
const max_hidden = 8
const max_outputs = 4

fn sigmoid(value f64) f64 {
	return 1.0 / (1.0 + math.exp(-value))
}

fn round_three(value f64) f64 {
	scaled := value * 1000.0
	lower := math.floor(scaled)
	mut integer := i64(lower)
	fraction := scaled - lower
	if fraction > 0.5 || (fraction == 0.5 && integer % 2 != 0) {
		integer++
	}
	return f64(integer) / 1000.0
}

fn write_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.f64_bits(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'convolution_neural_network']
pub fn convolution_neural_network(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 7 || length > 2048 { return -1 }
		image_side_value := input[0]
		kernel_side_value := input[1]
		stride_value := input[2]
		filters_value := input[3]
		pool_value := input[4]
		hidden_value := input[5]
		outputs_value := input[6]
		if image_side_value < 2 || image_side_value > max_image_side ||
			kernel_side_value < 1 || kernel_side_value > max_kernel_side ||
			stride_value < 1 || stride_value > 4 || filters_value < 1 || filters_value > max_filters ||
			pool_value < 1 || pool_value > 2 || hidden_value < 1 || hidden_value > max_hidden ||
			outputs_value < 1 || outputs_value > max_outputs || kernel_side_value > image_side_value { return -1 }
		image_side := int(image_side_value)
		kernel_side := int(kernel_side_value)
		stride := int(stride_value)
		filters := int(filters_value)
		pool_side := int(pool_value)
		hidden := int(hidden_value)
		outputs := int(outputs_value)
		conv_side := (image_side - kernel_side) / stride + 1
		if conv_side < pool_side || conv_side % pool_side != 0 { return -1 }
		pooled_side := conv_side / pool_side
		feature_count := filters * pooled_side * pooled_side
		image_count := image_side * image_side
		kernel_count := filters * kernel_side * kernel_side
		hidden_weight_count := hidden * feature_count
		output_weight_count := outputs * hidden
		expected_length := 7 + image_count + kernel_count + filters + hidden_weight_count + output_weight_count + hidden + outputs
		if int(length) != expected_length { return -1 }
		mut image := [64]f64{}
		mut kernels := [48]f64{}
		mut conv_bias := [3]f64{}
		mut hidden_weights := [1536]f64{}
		mut output_weights := [32]f64{}
		mut hidden_bias := [8]f64{}
		mut output_bias := [4]f64{}
		mut feature_maps := [192]f64{}
		mut flattened := [192]f64{}
		mut hidden_output := [8]f64{}
		mut position := 7
		for index in 0 .. image_count {
			raw := input[position]
			if raw < 0 || raw > 1_000_000 { return -1 }
			image[index] = f64(raw) / 1_000_000.0
			position++
		}
		for index in 0 .. kernel_count {
			raw := input[position]
			if raw < -500_000 || raw > 500_000 { return -1 }
			kernels[index] = f64(raw) / 1_000_000.0
			position++
		}
		for index in 0 .. filters {
			raw := input[position]
			if raw < -1_000_000 || raw > 1_000_000 { return -1 }
			conv_bias[index] = f64(raw) / 1_000_000.0
			position++
		}
		for index in 0 .. hidden_weight_count {
			raw := input[position]
			if raw < -500_000 || raw > 500_000 { return -1 }
			hidden_weights[index] = f64(raw) / 1_000_000.0
			position++
		}
		for index in 0 .. output_weight_count {
			raw := input[position]
			if raw < -500_000 || raw > 500_000 { return -1 }
			output_weights[index] = f64(raw) / 1_000_000.0
			position++
		}
		for index in 0 .. hidden {
			raw := input[position]
			if raw < -1_000_000 || raw > 1_000_000 { return -1 }
			hidden_bias[index] = f64(raw) / 1_000_000.0
			position++
		}
		for index in 0 .. outputs {
			raw := input[position]
			if raw < -1_000_000 || raw > 1_000_000 { return -1 }
			output_bias[index] = f64(raw) / 1_000_000.0
			position++
		}
		output_bytes := outputs * 8
		if output == nil || int(output_capacity) < output_bytes { return -2 }

		for filter in 0 .. filters {
			for top in 0 .. conv_side {
				for left in 0 .. conv_side {
					mut total := 0.0
					for row in 0 .. kernel_side {
						for column in 0 .. kernel_side {
							total += image[(top * stride + row) * image_side + left * stride + column] * kernels[filter * kernel_side * kernel_side + row * kernel_side + column]
						}
					}
					feature_maps[(filter * conv_side + top) * conv_side + left] = sigmoid(total - conv_bias[filter])
				}
			}
		}
		mut feature_index := 0
		pool_area := pool_side * pool_side
		for filter in 0 .. filters {
			mut top := 0
			for top < conv_side {
				mut left := 0
				for left < conv_side {
					mut total := 0.0
					for row in 0 .. pool_side {
						for column in 0 .. pool_side {
							total += feature_maps[(filter * conv_side + top + row) * conv_side + left + column]
						}
					}
					flattened[feature_index] = total / f64(pool_area)
					feature_index++
					left += pool_side
				}
				top += pool_side
			}
		}
		for unit in 0 .. hidden {
			mut total := 0.0
			for index in 0 .. feature_count { total += flattened[index] * hidden_weights[unit * feature_count + index] }
			hidden_output[unit] = sigmoid(total - hidden_bias[unit])
		}
		for unit in 0 .. outputs {
			mut total := 0.0
			for index in 0 .. hidden { total += hidden_output[index] * output_weights[unit * hidden + index] }
			write_f64_le(mut output, unit * 8, round_three(sigmoid(total - output_bias[unit])))
		}
		return i64(output_bytes)
	}
}
