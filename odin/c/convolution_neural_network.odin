package convolution_neural_network

import "core:c"
import "core:math"

MAX_IMAGE_SIDE :: 8
MAX_KERNEL_SIDE :: 4
MAX_FILTERS :: 3
MAX_HIDDEN :: 8
MAX_OUTPUTS :: 4
MAX_ENTRY_MICRO :: i64(1_000_000)

sigmoid :: proc "contextless" (value: f64) -> f64 {
	return 1.0 / (1.0 + math.exp_f64(-value))
}

round_three :: proc "contextless" (value: f64) -> f64 {
	scaled := value * 1000.0
	lower := math.floor_f64(scaled)
	integer := i64(lower)
	fraction := scaled - lower
	if fraction > 0.5 || (fraction == 0.5 && integer % 2 != 0) {
		integer += 1
	}
	return f64(integer) / 1000.0
}

write_f64_le :: proc "contextless" (output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> u64(8 * byte))
	}
}

@(export)
convolution_neural_network :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 7 || length > 2048 do return -1
	image_side_value := values[0]
	kernel_side_value := values[1]
	stride_value := values[2]
	filters_value := values[3]
	pool_value := values[4]
	hidden_value := values[5]
	outputs_value := values[6]
	if image_side_value < 2 || image_side_value > MAX_IMAGE_SIDE ||
		kernel_side_value < 1 || kernel_side_value > MAX_KERNEL_SIDE ||
		stride_value < 1 || stride_value > 4 || filters_value < 1 || filters_value > MAX_FILTERS ||
		pool_value < 1 || pool_value > 2 || hidden_value < 1 || hidden_value > MAX_HIDDEN ||
		outputs_value < 1 || outputs_value > MAX_OUTPUTS || kernel_side_value > image_side_value {
		return -1
	}
	image_side := int(image_side_value)
	kernel_side := int(kernel_side_value)
	stride := int(stride_value)
	filters := int(filters_value)
	pool_side := int(pool_value)
	hidden := int(hidden_value)
	outputs := int(outputs_value)
	conv_side := (image_side - kernel_side) / stride + 1
	if conv_side < pool_side || conv_side % pool_side != 0 do return -1
	pooled_side := conv_side / pool_side
	feature_count := filters * pooled_side * pooled_side
	image_count := image_side * image_side
	kernel_count := filters * kernel_side * kernel_side
	hidden_weight_count := hidden * feature_count
	output_weight_count := outputs * hidden
	expected_length := 7 + image_count + kernel_count + filters + hidden_weight_count + output_weight_count + hidden + outputs
	if length != c.size_t(expected_length) do return -1

	image: [64]f64 = {}
	kernels: [48]f64 = {}
	conv_bias: [3]f64 = {}
	hidden_weights: [1536]f64 = {}
	output_weights: [32]f64 = {}
	hidden_bias: [8]f64 = {}
	output_bias: [4]f64 = {}
	feature_maps: [192]f64 = {}
	flattened: [192]f64 = {}
	hidden_output: [8]f64 = {}
	position := 7
	for index := 0; index < image_count; index += 1 {
		raw := values[position]
		if raw < 0 || raw > MAX_ENTRY_MICRO do return -1
		image[index] = f64(raw) / 1_000_000.0
		position += 1
	}
	for index := 0; index < kernel_count; index += 1 {
		raw := values[position]
		if raw < -500_000 || raw > 500_000 do return -1
		kernels[index] = f64(raw) / 1_000_000.0
		position += 1
	}
	for index := 0; index < filters; index += 1 {
		raw := values[position]
		if raw < -MAX_ENTRY_MICRO || raw > MAX_ENTRY_MICRO do return -1
		conv_bias[index] = f64(raw) / 1_000_000.0
		position += 1
	}
	for index := 0; index < hidden_weight_count; index += 1 {
		raw := values[position]
		if raw < -500_000 || raw > 500_000 do return -1
		hidden_weights[index] = f64(raw) / 1_000_000.0
		position += 1
	}
	for index := 0; index < output_weight_count; index += 1 {
		raw := values[position]
		if raw < -500_000 || raw > 500_000 do return -1
		output_weights[index] = f64(raw) / 1_000_000.0
		position += 1
	}
	for index := 0; index < hidden; index += 1 {
		raw := values[position]
		if raw < -MAX_ENTRY_MICRO || raw > MAX_ENTRY_MICRO do return -1
		hidden_bias[index] = f64(raw) / 1_000_000.0
		position += 1
	}
	for index := 0; index < outputs; index += 1 {
		raw := values[position]
		if raw < -MAX_ENTRY_MICRO || raw > MAX_ENTRY_MICRO do return -1
		output_bias[index] = f64(raw) / 1_000_000.0
		position += 1
	}
	output_bytes := outputs * 8
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2

	for filter := 0; filter < filters; filter += 1 {
		for top := 0; top < conv_side; top += 1 {
			for left := 0; left < conv_side; left += 1 {
				total := 0.0
				for row := 0; row < kernel_side; row += 1 {
					for column := 0; column < kernel_side; column += 1 {
						total += image[(top * stride + row) * image_side + left * stride + column] * kernels[filter * kernel_side * kernel_side + row * kernel_side + column]
					}
				}
				feature_maps[(filter * conv_side + top) * conv_side + left] = sigmoid(total - conv_bias[filter])
			}
		}
	}
	feature_index := 0
	pool_area := pool_side * pool_side
	for filter := 0; filter < filters; filter += 1 {
		for top := 0; top < conv_side; top += pool_side {
			for left := 0; left < conv_side; left += pool_side {
				total := 0.0
				for row := 0; row < pool_side; row += 1 {
					for column := 0; column < pool_side; column += 1 {
						total += feature_maps[(filter * conv_side + top + row) * conv_side + left + column]
					}
				}
				flattened[feature_index] = total / f64(pool_area)
				feature_index += 1
			}
		}
	}
	for unit := 0; unit < hidden; unit += 1 {
		total := 0.0
		for index := 0; index < feature_count; index += 1 {
			total += flattened[index] * hidden_weights[unit * feature_count + index]
		}
		hidden_output[unit] = sigmoid(total - hidden_bias[unit])
	}
	for unit := 0; unit < outputs; unit += 1 {
		total := 0.0
		for index := 0; index < hidden; index += 1 {
			total += hidden_output[index] * output_weights[unit * hidden + index]
		}
		write_f64_le(output, unit * 8, round_three(sigmoid(total - output_bias[unit])))
	}
	return i64(output_bytes)
}
