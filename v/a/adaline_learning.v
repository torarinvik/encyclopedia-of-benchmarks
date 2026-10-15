module adaline_learning

const max_samples = 32
const max_features = 8

fn store_i32_le(output &u8, offset int, value i64) {
	bits := u32(i32(value))
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'adaline_learning']
pub fn adaline_learning(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 5 { return -1 }
	n_value := unsafe { input[0] }
	f_value := unsafe { input[1] }
	eta_value := unsafe { input[2] }
	shift_value := unsafe { input[3] }
	iterations_value := unsafe { input[4] }
	if n_value < 1 || n_value > max_samples || f_value < 1 || f_value > max_features ||
		eta_value < 1 || shift_value < 1 || shift_value > 12 || iterations_value < 1 || iterations_value > 500 {
		return -1
	}
	sample_count := int(n_value)
	feature_count := int(f_value)
	eta_numerator := eta_value
	eta_shift := int(shift_value)
	max_iterations := int(iterations_value)
	mut scale := i64(1)
	for _ in 0 .. eta_shift { scale *= 2 }
	if eta_numerator >= scale || length != usize(5 + sample_count * (feature_count + 1)) { return -1 }

	for sample in 0 .. sample_count {
		row := 5 + sample * (feature_count + 1)
		for feature in 0 .. feature_count {
			value := unsafe { input[row + feature] }
			if value < -16 || value > 16 { return -1 }
		}
		label := unsafe { input[row + feature_count] }
		if label != -1 && label != 1 { return -1 }
	}

	byte_count := 4 * (1 + feature_count + 1 + sample_count)
	if output_capacity < usize(byte_count) { return -2 }

	mut weights := [max_features]i64{init: 0}
	for feature in 0 .. feature_count { weights[feature] = scale }
	mut bias := scale
	mut iterations := 0
	for iterations < max_iterations {
		mut mistakes := 0
		for sample in 0 .. sample_count {
			row := 5 + sample * (feature_count + 1)
			mut score := bias
			for feature in 0 .. feature_count { score += unsafe { input[row + feature] } * weights[feature] }
			prediction := if score > 0 { i64(1) } else { i64(-1) }
			error := unsafe { input[row + feature_count] } - prediction
			if error != 0 {
				mistakes++
				correction := eta_numerator * error
				for feature in 0 .. feature_count {
					weights[feature] += correction * unsafe { input[row + feature] }
				}
				bias += correction
			}
		}
		iterations++
		if mistakes == 0 { break }
	}

	mut position := 0
	store_i32_le(output, position, i64(iterations)); position += 4
	for feature in 0 .. feature_count {
		store_i32_le(output, position, weights[feature]); position += 4
	}
	store_i32_le(output, position, bias); position += 4
	for sample in 0 .. sample_count {
		row := 5 + sample * (feature_count + 1)
		mut score := bias
		for feature in 0 .. feature_count { score += unsafe { input[row + feature] } * weights[feature] }
		store_i32_le(output, position, if score > 0 { i64(1) } else { i64(-1) })
		position += 4
	}
	return i64(byte_count)
}
