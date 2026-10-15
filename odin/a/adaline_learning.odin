package adaline_learning

import "core:c"

MAX_SAMPLES :: 32
MAX_FEATURES :: 8

store_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u32(i32(value))
	for byte := 0; byte < 4; byte += 1 {
		output[offset + byte] = u8((bits >> u32(byte * 8)) & 255)
	}
}

@(export)
adaline_learning :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 5 do return -1
	if input[0] < 1 || input[0] > MAX_SAMPLES || input[1] < 1 || input[1] > MAX_FEATURES || input[2] < 1 || input[3] < 1 || input[3] > 12 || input[4] < 1 || input[4] > 500 do return -1

	sample_count := int(input[0])
	feature_count := int(input[1])
	eta_numerator := input[2]
	eta_shift := int(input[3])
	max_iterations := int(input[4])
	scale := i64(1)
	for bit := 0; bit < eta_shift; bit += 1 { scale *= 2 }
	if eta_numerator >= scale || int(length) != 5 + sample_count * (feature_count + 1) do return -1

	for sample := 0; sample < sample_count; sample += 1 {
		row := 5 + sample * (feature_count + 1)
		for feature := 0; feature < feature_count; feature += 1 {
			value := input[row + feature]
			if value < -16 || value > 16 do return -1
		}
		label := input[row + feature_count]
		if label != -1 && label != 1 do return -1
	}

	byte_count := 4 * (1 + feature_count + 1 + sample_count)
	if output_capacity < c.size_t(byte_count) || output == nil do return -2

	weights: [MAX_FEATURES]i64
	for feature := 0; feature < feature_count; feature += 1 { weights[feature] = scale }
	bias := scale
	iterations := 0
	for iterations < max_iterations {
		mistakes := 0
		for sample := 0; sample < sample_count; sample += 1 {
			row := 5 + sample * (feature_count + 1)
			score := bias
			for feature := 0; feature < feature_count; feature += 1 {
				score += input[row + feature] * weights[feature]
			}
			prediction := i64(-1)
			if score > 0 { prediction = 1 }
			error := input[row + feature_count] - prediction
			if error != 0 {
				mistakes += 1
				correction := eta_numerator * error
				for feature := 0; feature < feature_count; feature += 1 {
					weights[feature] += correction * input[row + feature]
				}
				bias += correction
			}
		}
		iterations += 1
		if mistakes == 0 do break
	}

	position := 0
	store_i32_le(output, position, i64(iterations)); position += 4
	for feature := 0; feature < feature_count; feature += 1 {
		store_i32_le(output, position, weights[feature]); position += 4
	}
	store_i32_le(output, position, bias); position += 4
	for sample := 0; sample < sample_count; sample += 1 {
		row := 5 + sample * (feature_count + 1)
		score := bias
		for feature := 0; feature < feature_count; feature += 1 {
			score += input[row + feature] * weights[feature]
		}
		store_i32_le(output, position, i64(1))
		if score <= 0 { store_i32_le(output, position, i64(-1)) }
		position += 4
	}
	return i64(byte_count)
}
