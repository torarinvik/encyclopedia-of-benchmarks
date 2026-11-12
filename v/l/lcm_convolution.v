module lcm_convolution

const max_n = 128
const max_input_length = 1 + 2 * max_n + 1
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

fn multiple_zeta(mut values []i64, n int) {
	mut divisor := n
	for divisor >= 1 {
		mut multiple := 2 * divisor
		for multiple <= n {
			values[multiple] += values[divisor]
			if values[multiple] >= modulus { values[multiple] -= modulus }
			multiple += divisor
		}
		divisor--
	}
}

fn multiple_mobius(mut values []i64, n int) {
	for divisor in 1 .. n + 1 {
		mut multiple := 2 * divisor
		for multiple <= n {
			values[multiple] -= values[divisor]
			if values[multiple] < 0 { values[multiple] += modulus }
			multiple += divisor
		}
	}
}

@[export: 'lcm_convolution']
pub fn lcm_convolution(input &i64, length usize, mut output &u8,
	capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_length { return -1 }
	n_value := unsafe { input[0] }
	if n_value < 1 || n_value > max_n { return -1 }
	n := int(n_value)
	if length != usize(1 + 2 * n) { return -1 }
	for index in 0 .. 2 * n {
		value := unsafe { input[1 + index] }
		if value < 0 || value >= modulus { return -1 }
	}
	output_bytes := 8 * n
	if unsafe { output == nil } || capacity < usize(output_bytes) { return -2 }

	mut a := []i64{len: max_n + 1}
	mut b := []i64{len: max_n + 1}
	mut c := []i64{len: max_n + 1}
	for index in 1 .. n + 1 {
		a[index] = unsafe { input[index] }
		b[index] = unsafe { input[n + index] }
	}
	multiple_zeta(mut a, n)
	multiple_zeta(mut b, n)
	for index in 1 .. n + 1 { c[index] = (a[index] * b[index]) % modulus }
	multiple_mobius(mut c, n)
	for index in 1 .. n + 1 {
		store_i64_le(mut output, usize(8 * (index - 1)), c[index])
	}
	return i64(output_bytes)
}
