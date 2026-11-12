module division_of_polynomials

const modulus = i64(998_244_353)
const max_n = 64
const max_input = 131
const max_output_bytes = 536

fn power_mod(base_input i64, exponent_input i64) i64 {
	mut base := base_input
	mut exponent := exponent_input
	mut result := i64(1)
	for exponent > 0 {
		if exponent & 1 != 0 { result = result * base % modulus }
		base = base * base % modulus
		exponent >>= 1
	}
	return result
}

fn trim(poly [max_n]i64, length_input int) int {
	mut length := length_input
	for length > 0 && poly[length - 1] == 0 { length-- }
	return length
}

fn store_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'division_of_polynomials']
pub fn division_of_polynomials(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_input { return -1 }
		if input[0] < 1 || input[0] > max_n || input[1] < 1 || input[1] > max_n { return -1 }
		n := int(input[0])
		m := int(input[1])
		if length != usize(2 + n + m) { return -1 }

		mut work := [max_n]i64{}
		mut quotient := [max_n]i64{}
		for i in 0 .. n {
			work[i] = input[2 + i]
			if work[i] < 0 || work[i] >= modulus { return -1 }
		}
		for i in 0 .. m {
			coefficient := input[2 + n + i]
			if coefficient < 0 || coefficient >= modulus { return -1 }
		}
		if work[n - 1] == 0 || input[2 + n + m - 1] == 0 { return -1 }

		mut quotient_bound := 0
		if n >= m {
			quotient_bound = n - m + 1
			inverse_leading := power_mod(input[2 + n + m - 1], modulus - 2)
			mut shift_plus_one := quotient_bound
			for shift_plus_one > 0 {
				shift := shift_plus_one - 1
				factor := work[shift + m - 1] * inverse_leading % modulus
				quotient[shift] = factor
				for j in 0 .. m {
					mut value := (work[shift + j] - factor * input[2 + n + j]) % modulus
					if value < 0 { value += modulus }
					work[shift + j] = value
				}
				shift_plus_one--
			}
		}

		quotient_length := trim(quotient, quotient_bound)
		remainder_bound := if n < m { n } else { m }
		remainder_length := trim(work, remainder_bound)
		bytes := 8 * (2 + quotient_length + remainder_length)
		if bytes > max_output_bytes { return -1 }
		if output == nil || capacity < usize(bytes) { return -2 }

		store_le(mut output, 0, i64(quotient_length))
		store_le(mut output, 8, i64(remainder_length))
		mut offset := 16
		for i in 0 .. quotient_length {
			store_le(mut output, offset, quotient[i])
			offset += 8
		}
		for i in 0 .. remainder_length {
			store_le(mut output, offset, work[i])
			offset += 8
		}
		return i64(bytes)
	}
}
