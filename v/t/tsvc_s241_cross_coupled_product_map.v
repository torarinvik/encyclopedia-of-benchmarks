module tsvc_s241_cross_coupled_product_map

const max_n = 64
const max_input_length = 1 + 4 * max_n
const max_value = i64(2)

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'tsvc_s241_cross_coupled_product_map']
pub fn tsvc_s241_cross_coupled_product_map(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 9 || length > max_input_length { return -1 }
	n_raw := unsafe { input[0] }
	if n_raw < 2 || n_raw > max_n { return -1 }
	n := int(n_raw)
	if int(length) != 1 + 4 * n { return -1 }

	a_start := 1
	b_start := a_start + n
	c_start := b_start + n
	d_start := c_start + n
	mut a := [max_n]i64{}
	mut b := [max_n]i64{}
	for i in 0 .. n {
		a[i] = unsafe { input[a_start + i] }
		b[i] = unsafe { input[b_start + i] }
		c_value := unsafe { input[c_start + i] }
		d_value := unsafe { input[d_start + i] }
		if a[i] < -max_value || a[i] > max_value || b[i] < -max_value || b[i] > max_value ||
			c_value < -max_value || c_value > max_value || d_value < -max_value || d_value > max_value { return -1 }
	}
	if unsafe { output == nil } || output_capacity < usize(16 * n) { return -2 }

	for i in 0 .. n - 1 {
		next_a := a[i + 1]
		c_value := unsafe { input[c_start + i] }
		d_value := unsafe { input[d_start + i] }
		a[i] = b[i] * c_value * d_value
		b[i] = a[i] * next_a * d_value
	}
	for i in 0 .. n {
		store_i64_le(mut output, 8 * i, a[i])
		store_i64_le(mut output, 8 * (n + i), b[i])
	}
	return i64(2 * n)
}
