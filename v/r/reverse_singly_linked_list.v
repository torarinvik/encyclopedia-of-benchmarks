module reverse_singly_linked_list

const max_length = 256

fn write_i32_le(mut output &u8, index int, value i32) {
	unsafe {
		mut bits := u32(value)
		offset := index * 4
		for byte in 0 .. 4 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'reverse_singly_linked_list']
pub fn reverse_singly_linked_list(values &i32, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if values == nil || length > usize(max_length) { return -1 }
		output_bytes := int(length) * 4
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for index in 0 .. int(length) {
			write_i32_le(mut output, index, values[int(length) - 1 - index])
		}
		return i64(output_bytes)
	}
}
