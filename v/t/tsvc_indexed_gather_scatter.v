module tsvc_indexed_gather_scatter

const max_n = 16
const max_input_length = 2 + 5 * max_n
const max_operand = i64(1000000)

fn bounded_operand(value i64) bool {
	return value >= -max_operand && value <= max_operand
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'tsvc_indexed_gather_scatter']
pub fn tsvc_indexed_gather_scatter(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 6 || length > max_input_length { return -1 }
	mode := unsafe { input[0] }
	n_raw := unsafe { input[1] }
	if (mode != 491 && mode != 4113) || n_raw < 1 || n_raw > max_n { return -1 }
	n := int(n_raw)
	arrays_per_index := 4
	if mode == 491 { arrays_per_index = 5 }
	if int(length) != 2 + arrays_per_index * n { return -1 }

	index_start := 2
	a_start := index_start + n
	b_start := a_start + n
	c_start := b_start + n
	d_start := c_start + n
	mut state := [max_n]i64{}
	for i in 0 .. n {
		index := unsafe { input[index_start + i] }
		if index < 0 || index >= n_raw { return -1 }
		state[i] = unsafe { input[a_start + i] }
		if !bounded_operand(unsafe { input[b_start + i] }) || !bounded_operand(unsafe { input[c_start + i] }) { return -1 }
		if mode == 491 && !bounded_operand(unsafe { input[d_start + i] }) { return -1 }
	}
	if unsafe { output == nil } || output_capacity < usize(8 * n) { return -2 }

	for i in 0 .. n {
		index := int(unsafe { input[index_start + i] })
		if mode == 491 {
			state[index] = unsafe { input[b_start + i] + input[c_start + i] * input[d_start + i] }
		} else {
			state[index] = unsafe { input[b_start + index] + input[c_start + i] }
		}
	}
	for i in 0 .. n { store_i64_le(mut output, 8 * i, state[i]) }
	return i64(n)
}
