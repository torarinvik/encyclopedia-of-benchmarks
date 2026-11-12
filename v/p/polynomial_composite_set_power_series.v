module polynomial_composite_set_power_series

const modulus = i64(998244353)
const max_coefficients = 8
const max_n = 4
const max_size = 16

fn store_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'polynomial_composite_set_power_series']
pub fn polynomial_composite_set_power_series(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 27 { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > max_coefficients ||
			input[1] < 0 || input[1] > max_n { return -1 }
		count := int(input[0])
		n := int(input[1])
		size := 1 << n
		if length != usize(2 + count + size) { return -1 }
		for index in 0 .. count + size {
			if input[2 + index] < 0 || input[2 + index] >= modulus { return -1 }
		}

		bytes := 8 * size
		if unsafe { output == nil } || capacity < usize(bytes) { return -2 }

		mut series := [16]i64{}
		mut result := [16]i64{}
		mut temporary := [16]i64{}
		for mask in 0 .. size {
			series[mask] = input[2 + count + mask]
		}

		for degree := count; degree > 0; degree-- {
			for mask in 0 .. size {
				mut total := i64(0)
				mut subset := mask
				for subset >= 0 {
					total = (total + result[subset] * series[mask ^ subset]) % modulus
					if subset == 0 { break }
					subset = (subset - 1) & mask
				}
				temporary[mask] = total
			}
			temporary[0] = (temporary[0] + input[1 + degree]) % modulus
			for mask in 0 .. size {
				result[mask] = temporary[mask]
			}
		}
		for mask in 0 .. size { store_le(mut output, 8 * mask, result[mask]) }
		return i64(bytes)
	}
}
