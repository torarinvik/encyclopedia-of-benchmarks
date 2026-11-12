module bitwise_and_convolution

const max_n = 8
const max_size = 1 << max_n
const max_input_length = 1 + 2 * max_size
const modulus = i64(998244353)

fn store_i64_le(mut output &u8, offset usize, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'bitwise_and_convolution']
pub fn bitwise_and_convolution(input &i64, length usize, mut output &u8,
	capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_length { return -1 }
	n_value := unsafe { input[0] }
	if n_value < 0 || n_value > max_n { return -1 }
	n := int(n_value)
	size := 1 << n
	if length != usize(1 + 2 * size) { return -1 }
	for index in 0 .. 2 * size {
		value := unsafe { input[1 + index] }
		if value < 0 || value >= modulus { return -1 }
	}
	output_bytes := 8 * size
	if unsafe { output == nil } || capacity < usize(output_bytes) { return -2 }

	mut a := []i64{len: max_size}
	mut b := []i64{len: max_size}
	for index in 0 .. size {
		a[index] = unsafe { input[1 + index] }
		b[index] = unsafe { input[1 + size + index] }
	}
	for bit in 0 .. n {
		bit_mask := 1 << bit
		for mask in 0 .. size {
			if (mask & bit_mask) == 0 {
				a[mask] = (a[mask] + a[mask | bit_mask]) % modulus
				b[mask] = (b[mask] + b[mask | bit_mask]) % modulus
			}
		}
	}
	for mask in 0 .. size { a[mask] = (a[mask] * b[mask]) % modulus }
	for bit in 0 .. n {
		bit_mask := 1 << bit
		for mask in 0 .. size {
			if (mask & bit_mask) == 0 {
				a[mask] -= a[mask | bit_mask]
				if a[mask] < 0 { a[mask] += modulus }
			}
		}
	}
	for mask in 0 .. size { store_i64_le(mut output, usize(8 * mask), a[mask]) }
	return i64(output_bytes)
}
