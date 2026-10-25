module tsvc_s161_mutually_exclusive_updates

const max_n = 64
const max_input_length = 1 + 5 * max_n
const max_value = i64(2)

fn bounded_value(value i64) bool {
	return value >= -max_value && value <= max_value
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'tsvc_s161_mutually_exclusive_updates']
pub fn tsvc_s161_mutually_exclusive_updates(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 11 || length > max_input_length { return -1 }
	n_raw := unsafe { input[0] }
	if n_raw < 2 || n_raw > max_n { return -1 }
	n := int(n_raw)
	if int(length) != 1 + 5 * n { return -1 }

	a_start := 1
	b_start := a_start + n
	c_start := b_start + n
	d_start := c_start + n
	e_start := d_start + n
	mut a := [max_n]i64{}
	mut c := [max_n]i64{}
	for i in 0 .. n {
		a[i] = unsafe { input[a_start + i] }
		c[i] = unsafe { input[c_start + i] }
		if !bounded_value(a[i]) || !bounded_value(unsafe { input[b_start + i] }) ||
			!bounded_value(c[i]) || !bounded_value(unsafe { input[d_start + i] }) ||
			!bounded_value(unsafe { input[e_start + i] }) { return -1 }
	}
	if unsafe { output == nil } || output_capacity < usize(16 * n) { return -2 }

	for i in 0 .. n - 1 {
		if unsafe { input[b_start + i] } < 0 {
			d := unsafe { input[d_start + i] }
			c[i + 1] = a[i] + d * d
		} else {
			a[i] = c[i] + unsafe { input[d_start + i] * input[e_start + i] }
		}
	}
	for i in 0 .. n {
		store_i64_le(mut output, 8 * i, a[i])
		store_i64_le(mut output, 8 * (n + i), c[i])
	}
	return i64(2 * n)
}
