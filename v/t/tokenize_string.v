module tokenize_string

@[export: 'tokenize_string']
pub fn tokenize_string(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 2 || length > 130 { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > 128 { return -1 }
		text_length := int(input[0])
		if int(length) != text_length + 2 { return -1 }
		separator := input[1]
		if separator != 44 && separator != 46 && separator != 58 { return -1 }
		mut separator_count := 0
		for index := 0; index < text_length; index++ {
			byte := input[index + 2]
			if byte < 32 || byte > 126 { return -1 }
			if byte == separator { separator_count++ }
		}
		if separator_count > 18 { return -1 }
		output_length := text_length + 2
		if output == nil || capacity < usize(output_length) { return -2 }
		output[0] = u8(separator_count + 1)
		for index := 0; index < text_length; index++ {
			byte := input[index + 2]
			output[index + 1] = if byte == separator { u8(0) } else { u8(byte) }
		}
		output[output_length - 1] = 0
		return i64(output_length)
	}
}
