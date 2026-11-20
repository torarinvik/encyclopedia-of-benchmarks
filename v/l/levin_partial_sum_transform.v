module levin_partial_sum_transform

const min_words = 5
const max_words = 16
const output_bytes = 16

fn levin_gcd(a_value i64, b_value i64) i64 {
	mut a := a_value
	mut b := b_value
	for b != 0 {
		remainder := a % b
		a = b
		b = remainder
	}
	return a
}

fn levin_store_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> u32(byte * 8)) & 255) }
	}
}

@[export: 'levin_partial_sum_transform']
pub fn levin_partial_sum_transform(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < min_words || length > max_words { return -1 }
	unsafe {
		n0 := input[0]
		k0 := input[1]
		if n0 < 0 || n0 > 8 || k0 < 1 || k0 > 3 { return -1 }
		n := int(n0)
		k := int(k0)
		if length != usize(n + k + 4) { return -1 }
		term_count := n + k + 2
		for i in 0 .. term_count {
			value := input[i + 2]
			if value == 0 || value < -3 || value > 3 { return -1 }
		}

		mut product := i64(1)
		for j in 0 .. k + 1 { product *= input[n + j + 3] }
		mut numerator := i64(0)
		mut denominator := i64(0)
		for j in 0 .. k + 1 {
			mut choose := i64(1)
			for r in 1 .. j + 1 { choose = choose * i64(k - r + 1) / i64(r) }
			mut power := i64(1)
			for _ in 0 .. k - 1 { power *= i64(n + j + 1) }
			term := input[n + j + 3]
			mut weight := choose * power * (product / term)
			if j % 2 != 0 { weight = -weight }
			mut partial := i64(0)
			for index in 0 .. n + j + 1 { partial += input[index + 2] }
			numerator += weight * partial
			denominator += weight
		}
		if denominator == 0 { return -1 }
		if denominator < 0 {
			numerator = -numerator
			denominator = -denominator
		}
		magnitude := if numerator < 0 { -numerator } else { numerator }
		divisor := levin_gcd(magnitude, denominator)
		numerator /= divisor
		denominator /= divisor
		if output == nil || capacity < output_bytes { return -2 }
		levin_store_i64(mut output, 0, numerator)
		levin_store_i64(mut output, 8, denominator)
		return output_bytes
	}
}
