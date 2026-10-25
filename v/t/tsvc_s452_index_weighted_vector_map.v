module tsvc_s452_index_weighted_vector_map

const max_n = 64
const max_input_length = 1 + 2 * max_n
const max_value = i64(2)

fn bounded_value(value i64) bool {
	return value >= -max_value && value <= max_value
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'tsvc_s452_index_weighted_vector_map']
pub fn tsvc_s452_index_weighted_vector_map(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_input_length { return -1 }
	n_raw := unsafe { input[0] }
	if n_raw < 1 || n_raw > max_n { return -1 }
	n := int(n_raw)
	if int(length) != 1 + 2 * n { return -1 }

	b_start := 1
	c_start := b_start + n
	for i in 0 .. n {
		if !bounded_value(unsafe { input[b_start + i] }) || !bounded_value(unsafe { input[c_start + i] }) { return -1 }
	}
	if unsafe { output == nil } || output_capacity < usize(8 * n) { return -2 }

	for i in 0 .. n {
		index_weight := i64(i + 1)
		value := unsafe { input[b_start + i] + input[c_start + i] * index_weight }
		store_i64_le(mut output, 8 * i, value)
	}
	return i64(n)
}
