module miller_backward_recurrence_normalization

const modulus = i64(998244353)

fn miller_mod_pow(base_value i64, exponent_value i64) i64 {
	mut base := base_value
	mut exponent := exponent_value
	mut result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 { result = result * base % modulus }
		base = base * base % modulus
		exponent >>= 1
	}
	return result
}

fn miller_store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8((bits >> u64(8 * byte)) & 255)
		}
	}
}

@[export: 'miller_backward_recurrence_normalization']
pub fn miller_backward_recurrence_normalization(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 6 || length > 35 { return -1 }
		levels_value := input[0]
		if levels_value < 1 || levels_value > 8 { return -1 }
		levels := int(levels_value)
		if int(length) != 4 * levels + 2 { return -1 }
		for index in 1 .. int(length) {
			if input[index] < 0 || input[index] >= modulus { return -1 }
		}
		for level in 1 .. levels + 1 {
			if input[3 * level] == 0 { return -1 }
		}

		mut trial := [10]i64{}
		trial[levels] = 1
		trial[levels + 1] = 0
		for level in 1 .. levels + 1 {
			idx := levels + 1 - level
			a_value := input[3 * idx - 2]
			b_value := input[3 * idx - 1]
			c_value := input[3 * idx]
			positive := b_value * trial[idx] % modulus
			negative := a_value * trial[idx + 1] % modulus
			numerator := (positive + modulus - negative) % modulus
			trial[idx - 1] = numerator * miller_mod_pow(c_value, modulus - 2) % modulus
		}
		lambda_start := 3 * levels + 1
		mut normalizer := i64(0)
		for index in 0 .. levels + 1 {
			normalizer = (normalizer + input[lambda_start + index] * trial[index]) % modulus
		}
		if normalizer == 0 { return -1 }
		scale := miller_mod_pow(normalizer, modulus - 2)
		required := usize(8 * (levels + 2))
		if output == nil || capacity < required { return -2 }

		miller_store_i64_le(mut output, 0, levels_value)
		for index in 0 .. levels + 1 {
			miller_store_i64_le(mut output, 8 * (index + 1), trial[index] * scale % modulus)
		}
		return i64(required)
	}
}
