const max_count = 64
const max_parseable_input_length = 3
const max_output_bytes = 8 * max_count

fn generate_nth_term(index i64) i64 {
	if index == 0 || index == 1 { return index }
	if index % 2 == 0 { return 4 * generate_nth_term(index / 2) }
	return 4 * generate_nth_term(index / 2) + 1
}

fn put_i64_le(value i64, output &u8, offset int) {
	unsafe {
		mut bits := u64(value)
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'sequence']
pub fn sequence(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if unsafe { values == nil } || length < 1 || length > max_parseable_input_length { return -1 }
	unsafe {
		if length != 1 || values[0] < -max_count || values[0] > max_count { return -1 }
		if values[0] <= 0 { return 0 }

		count := int(values[0])
		required := count * 8
		if output == nil || output_capacity < usize(required) || required > max_output_bytes { return -2 }
		for index in 0 .. count {
			put_i64_le(generate_nth_term(i64(index)), output, index * 8)
		}
		return i64(required)
	}
}
