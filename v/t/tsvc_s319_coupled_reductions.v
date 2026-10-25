module tsvc_s319_coupled_reductions

const max_n = 64
const max_input_length = 1 + 3 * max_n
const max_value = i64(2)

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'tsvc_s319_coupled_reductions']
pub fn tsvc_s319_coupled_reductions(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 4 || length > max_input_length { return -1 }
	n_raw := unsafe { input[0] }
	if n_raw < 1 || n_raw > max_n { return -1 }
	n := int(n_raw)
	if int(length) != 1 + 3 * n { return -1 }

	c_start := 1
	d_start := c_start + n
	e_start := d_start + n
	for i in 0 .. n {
		if unsafe { input[c_start + i] } < -max_value || unsafe { input[c_start + i] } > max_value ||
			unsafe { input[d_start + i] } < -max_value || unsafe { input[d_start + i] } > max_value ||
			unsafe { input[e_start + i] } < -max_value || unsafe { input[e_start + i] } > max_value { return -1 }
	}
	value_count := 2 * n + 1
	if unsafe { output == nil } || output_capacity < usize(8 * value_count) { return -2 }

	mut total := i64(0)
	for i in 0 .. n {
		a_value := unsafe { input[c_start + i] + input[d_start + i] }
		b_value := unsafe { input[c_start + i] + input[e_start + i] }
		store_i64_le(mut output, 8 * i, a_value)
		store_i64_le(mut output, 8 * (n + i), b_value)
		total += a_value
		total += b_value
	}
	store_i64_le(mut output, 8 * (2 * n), total)
	return i64(value_count)
}
