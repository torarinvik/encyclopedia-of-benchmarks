module string_append

@[export: 'string_append']
pub fn string_append(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 2 || unsafe { input == nil } { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > 64 { return -1 }
		first_length := int(input[0])
		if usize(1 + first_length) >= length || input[1 + first_length] < 0 || input[1 + first_length] > 64 { return -1 }
		second_length := int(input[1 + first_length])
		if length != usize(2 + first_length + second_length) { return -1 }
		for i in 0 .. first_length { if input[2 + i] < 32 || input[2 + i] > 126 { return -1 } }
		for i in 0 .. second_length { if input[2 + first_length + i] < 32 || input[2 + first_length + i] > 126 { return -1 } }
		count := first_length + second_length
		if output_capacity < usize(count) || (count != 0 && output == nil) { return -2 }
		for i in 0 .. first_length { output[i] = u8(input[2 + i]) }
		for i in 0 .. second_length { output[first_length + i] = u8(input[2 + first_length + i]) }
		return i64(count)
	}
}
