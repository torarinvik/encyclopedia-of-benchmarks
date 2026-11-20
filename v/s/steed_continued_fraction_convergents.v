module steed_continued_fraction_convergents

const modulus = i64(998244353)

fn mod_pow(base_value i64, exponent_value i64) i64 {
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

fn divisors_are_nonzero(input &i64, levels int) bool {
	unsafe {
		if input[2] == 0 { return false }
		mut d_value := mod_pow(input[2], modulus - 2)
		for level in 2 .. levels + 1 {
			denominator := (d_value * input[2 * level + 1] + input[2 * level]) % modulus
			if denominator == 0 { return false }
			d_value = mod_pow(denominator, modulus - 2)
		}
	}
	return true
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8((bits >> u64(8 * byte)) & 255)
		}
	}
}

@[export: 'steed_continued_fraction_convergents']
pub fn steed_continued_fraction_convergents(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > 19 { return -1 }
		levels_value := input[0]
		if levels_value < 1 || levels_value > 8 { return -1 }
		levels := int(levels_value)
		if int(length) != 2 + 2 * levels { return -1 }
		for index in 1 .. int(length) {
			if input[index] < 0 || input[index] >= modulus { return -1 }
		}
		if !divisors_are_nonzero(input, levels) { return -1 }
		required := usize(8 * (levels + 2))
		if output == nil || capacity < required { return -2 }

		store_i64_le(mut output, 0, levels_value + 1)
		mut current := input[1]
		store_i64_le(mut output, 8, current)
		mut d_value := mod_pow(input[2], modulus - 2)
		mut delta := input[3] * d_value % modulus
		current = (current + delta) % modulus
		store_i64_le(mut output, 16, current)
		for level in 2 .. levels + 1 {
			b_value := input[2 * level]
			a_value := input[2 * level + 1]
			denominator := (d_value * a_value + b_value) % modulus
			d_value = mod_pow(denominator, modulus - 2)
			factor := (b_value * d_value + modulus - 1) % modulus
			delta = factor * delta % modulus
			current = (current + delta) % modulus
			store_i64_le(mut output, 8 * (level + 1), current)
		}
		return i64(required)
	}
}
