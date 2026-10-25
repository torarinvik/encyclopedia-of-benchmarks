module tsvc_s132_shifted_row_update

const max_n = 64
const max_input_length = 2 + 3 * max_n
const max_value = i64(1000000)

fn bounded_value(value i64) bool {
	return value >= -max_value && value <= max_value
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'tsvc_s132_shifted_row_update']
pub fn tsvc_s132_shifted_row_update(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 8 || length > max_input_length { return -1 }
	n_raw := unsafe { input[0] }
	if n_raw < 2 || n_raw > max_n { return -1 }
	n := int(n_raw)
	if int(length) != 2 + 3 * n { return -1 }

	row_start := 1
	target_start := row_start + n
	b_start := target_start + n
	c1_index := b_start + n
	mut target := [max_n]i64{}
	for i in 0 .. n {
		target[i] = unsafe { input[target_start + i] }
		if !bounded_value(unsafe { input[row_start + i] }) || !bounded_value(target[i]) ||
			!bounded_value(unsafe { input[b_start + i] }) { return -1 }
	}
	c1 := unsafe { input[c1_index] }
	if !bounded_value(c1) { return -1 }
	if unsafe { output == nil } || output_capacity < usize(8 * n) { return -2 }

	for i in 1 .. n {
		target[i] = unsafe { input[row_start + i - 1] + input[b_start + i] * c1 }
	}
	for i in 0 .. n { store_i64_le(mut output, 8 * i, target[i]) }
	return i64(n)
}
