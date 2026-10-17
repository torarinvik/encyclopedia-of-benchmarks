module tbc_padding

const max_bytes = 256

fn write_i64_le(mut output &u8, position int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[position + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'tbc_padding']
pub fn tbc_padding(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_bytes + 3 { return -1 }
	unsafe {
		operation := input[0]
		offset_value := input[1]
		count_value := input[2]
		if operation < 0 || operation > 2 || count_value < 0 || count_value > max_bytes || length != usize(count_value + 3) { return -1 }
		count := int(count_value)
		if (operation == 0 && (count == 0 || offset_value < 0 || offset_value > count_value)) ||
			(operation != 0 && offset_value != 0) || (operation == 2 && count == 0) { return -1 }
		for index in 0 .. count {
			if input[3 + index] < 0 || input[3 + index] > 255 { return -1 }
		}
		if operation == 0 {
			offset := int(offset_value)
			previous := input[count + 2]
			if offset > 0 { previous = input[offset + 2] }
		code := if (previous & 1) == 0 { u8(255) } else { u8(0) }
			needed := 8 + count
			if unsafe { output == nil } || capacity < usize(needed) { return -2 }
			write_i64_le(mut output, 0, i64(count - offset))
			for index in 0 .. count {
				unsafe { output[8 + index] = if index >= offset { code } else { u8(input[3 + index]) } }
			}
			return i64(needed)
		}
		if operation == 1 {
			mut survivors := count
			if count > 0 {
			code := if (input[2 + count] & 1) == 0 { i64(0) } else { i64(255) }
				for survivors > 0 && input[2 + survivors] == code { survivors-- }
			}
			if unsafe { output == nil } || capacity < usize(survivors) { return -2 }
			for index in 0 .. survivors { unsafe { output[index] = u8(input[3 + index]) } }
			return i64(survivors)
		}
		terminal := input[2 + count]
		if terminal != 0 && terminal != 255 { return -1 }
		mut padding_count := 0
		for padding_count < count && input[2 + count - padding_count] == terminal { padding_count++ }
		if unsafe { output == nil } || capacity < 8 { return -2 }
		write_i64_le(mut output, 0, i64(padding_count))
		return 8
	}
}
