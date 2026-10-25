module tsvc_s212_next_element_dependency

const max_n = 64
const max_input_length = 2 + 4 * max_n
const max_value = i64(2)
const max_passes = 16

fn bounded_value(value i64) bool {
	return value >= -max_value && value <= max_value
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'tsvc_s212_next_element_dependency']
pub fn tsvc_s212_next_element_dependency(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 10 || length > max_input_length { return -1 }
	n_raw := unsafe { input[0] }
	passes_raw := unsafe { input[1] }
	if n_raw < 2 || n_raw > max_n || passes_raw < 1 || passes_raw > max_passes { return -1 }
	n := int(n_raw)
	if int(length) != 2 + 4 * n { return -1 }

	a_start := 2
	b_start := a_start + n
	c_start := b_start + n
	d_start := c_start + n
	mut a := [max_n]i64{}
	mut b := [max_n]i64{}
	for i in 0 .. n {
		a[i] = unsafe { input[a_start + i] }
		b[i] = unsafe { input[b_start + i] }
		if !bounded_value(a[i]) || !bounded_value(b[i]) ||
			!bounded_value(unsafe { input[c_start + i] }) || !bounded_value(unsafe { input[d_start + i] }) { return -1 }
	}
	if unsafe { output == nil } || output_capacity < usize(16 * n) { return -2 }

	for _pass in 0 .. int(passes_raw) {
		for i in 0 .. n - 1 {
			a[i] *= unsafe { input[c_start + i] }
			b[i] += a[i + 1] * unsafe { input[d_start + i] }
		}
	}
	for i in 0 .. n {
		store_i64_le(mut output, 8 * i, a[i])
		store_i64_le(mut output, 8 * (n + i), b[i])
	}
	return i64(2 * n)
}
