module tsvc_s1244_polynomial_neighbor_sum

const max_n = 32
const max_input_length = 129

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) } }
}

@[export: 'tsvc_s1244_polynomial_neighbor_sum']
pub fn tsvc_s1244_polynomial_neighbor_sum(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 9 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 2 || input[0] > max_n { return -1 }
		n := int(input[0])
		if int(length) != 1 + 4 * n { return -1 }
		mut a := [max_n]i64{}
		mut b := [max_n]i64{}
		mut c := [max_n]i64{}
		mut d := [max_n]i64{}
		for i in 0 .. n {
			a[i] = input[1 + i]
			b[i] = input[1 + n + i]
			c[i] = input[1 + 2 * n + i]
			d[i] = input[1 + 3 * n + i]
			if a[i] < -2 || a[i] > 2 || b[i] < -2 || b[i] > 2 ||
				c[i] < -2 || c[i] > 2 || d[i] < -2 || d[i] > 2 { return -1 }
		}
		if unsafe { output == nil } || capacity < usize(16 * n) { return -2 }
		for i in 0 .. n - 1 {
			old_next_a := a[i + 1]
			a[i] = b[i] + c[i] * c[i] + b[i] * b[i] + c[i]
			d[i] = a[i] + old_next_a
		}
		for i in 0 .. n {
			store_i64_le(mut output, 8 * i, a[i])
			store_i64_le(mut output, 8 * (n + i), d[i])
		}
		return i64(2 * n)
	}
}
