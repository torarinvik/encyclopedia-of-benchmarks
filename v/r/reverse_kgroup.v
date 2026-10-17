module reverse_kgroup

const max_input_length = 258
const max_list_length = 256

fn write_i32_le(mut output &u8, index int, value i32) {
	unsafe {
		bits := u32(value)
		offset := index * 4
		for byte in 0 .. 4 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'reverse_kgroup']
pub fn reverse_kgroup(input &i32, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > usize(max_input_length) { return -1 }
		group_size_value := input[0]
		list_length := int(length) - 1
		if group_size_value < 1 || group_size_value > i32(max_list_length) || list_length > max_list_length { return -1 }
		group_size := int(group_size_value)
		output_bytes := list_length * 4
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut start := 0
		for start + group_size <= list_length {
			for offset := 0; offset < group_size; offset++ {
				write_i32_le(mut output, start + offset, input[1 + start + group_size - 1 - offset])
			}
			start += group_size
		}
		for start < list_length {
			write_i32_le(mut output, start, input[1 + start])
			start++
		}
		return i64(output_bytes)
	}
}
