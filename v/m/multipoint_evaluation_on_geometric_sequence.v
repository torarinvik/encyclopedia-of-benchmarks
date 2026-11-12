module multipoint_evaluation_on_geometric_sequence

const modulus = i64(998244353)
const max_n = 8
const max_m = 8
const ntt_size = 32
const max_input = 12

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

fn ntt(mut values []i64, inverse bool) {
	mut j := 0
	for i in 1 .. ntt_size {
		mut bit := ntt_size / 2
		for (j & bit) != 0 { j ^= bit; bit >>= 1 }
		j ^= bit
		if i < j { values[i], values[j] = values[j], values[i] }
	}
	mut block := 2
	for block <= ntt_size {
		mut root := mod_pow(3, (modulus - 1) / i64(block))
		if inverse { root = mod_pow(root, modulus - 2) }
		half := block / 2
		for start := 0; start < ntt_size; start += block {
			mut factor := i64(1)
			for offset in 0 .. half {
				even := values[start + offset]
				odd := values[start + offset + half] * factor % modulus
				values[start + offset] = (even + odd) % modulus
				values[start + offset + half] = (even - odd + modulus) % modulus
				factor = factor * root % modulus
			}
		}
		block *= 2
	}
	if inverse {
		scale := mod_pow(i64(ntt_size), modulus - 2)
		for i in 0 .. ntt_size { values[i] = values[i] * scale % modulus }
	}
}

fn evaluate(coefficients &i64, offset int, count int, x i64) i64 {
	mut value := i64(0)
	unsafe {
		for i := count; i > 0; i-- { value = (value * x + coefficients[offset + i - 1]) % modulus }
	}
	return value
}

fn store_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'multipoint_evaluation_on_geometric_sequence']
pub fn multipoint_evaluation_on_geometric_sequence(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 5 || length > max_input { return -1 }
		if input[0] < 1 || input[0] > max_n || input[1] < 1 || input[1] > max_m { return -1 }
		n := int(input[0])
		m := int(input[1])
		start := input[2]
		ratio := input[3]
		if length != usize(n + 4) || start < 0 || start >= modulus || ratio < 0 || ratio >= modulus { return -1 }
		for i in 0 .. n { if input[4 + i] < 0 || input[4 + i] >= modulus { return -1 } }
		bytes := 8 * m
		if output == nil || capacity < usize(bytes) { return -2 }
		if start == 0 {
			for i in 0 .. m { store_le(mut output, 8 * i, input[4]) }
			return i64(bytes)
		}
		if ratio == 0 {
			store_le(mut output, 0, evaluate(input, 4, n, start))
			for i in 1 .. m { store_le(mut output, 8 * i, input[4]) }
			return i64(bytes)
		}
		inverse_ratio := mod_pow(ratio, modulus - 2)
		mut left := [ntt_size]i64{}
		mut right := [ntt_size]i64{}
		mut start_power := i64(1)
		mut inverse_chirp := i64(1)
		mut inverse_ratio_power := i64(1)
		for degree in 0 .. n {
			left[n - 1 - degree] = input[4 + degree] * start_power % modulus * inverse_chirp % modulus
			start_power = start_power * start % modulus
			inverse_chirp = inverse_chirp * inverse_ratio_power % modulus
			inverse_ratio_power = inverse_ratio_power * inverse_ratio % modulus
		}
		mut chirp := i64(1)
		mut ratio_power := i64(1)
		for index in 0 .. n + m - 1 {
			right[index] = chirp
			chirp = chirp * ratio_power % modulus
			ratio_power = ratio_power * ratio % modulus
		}
		ntt(mut left[..], false)
		ntt(mut right[..], false)
		for i in 0 .. ntt_size { left[i] = left[i] * right[i] % modulus }
		ntt(mut left[..], true)
		inverse_chirp = 1
		inverse_ratio_power = 1
		for i in 0 .. m {
			store_le(mut output, 8 * i, left[n - 1 + i] * inverse_chirp % modulus)
			inverse_chirp = inverse_chirp * inverse_ratio_power % modulus
			inverse_ratio_power = inverse_ratio_power * inverse_ratio % modulus
		}
		return i64(bytes)
	}
}
