module alternative_string_arrange

@[export: 'alternative_string_arrange']
pub fn alternative_string_arrange(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 2 || unsafe { input == nil } { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > 64 { return -1 }
		first_length := int(input[0])
		if usize(1 + first_length) >= length || input[1 + first_length] < 0 || input[1 + first_length] > 64 { return -1 }
		second_length := int(input[1 + first_length])
		if length != usize(2 + first_length + second_length) { return -1 }
		for i in 0 .. first_length { if input[1 + i] < 0 || input[1 + i] > 127 { return -1 } }
		for i in 0 .. second_length { if input[2 + first_length + i] < 0 || input[2 + first_length + i] > 127 { return -1 } }
		count := first_length + second_length
		if output_capacity < usize(count) || (count != 0 && output == nil) { return -2 }
		mut written := 0
		limit := if first_length > second_length { first_length } else { second_length }
		for i in 0 .. limit {
			if i < first_length { output[written] = u8(input[1 + i]); written++ }
			if i < second_length { output[written] = u8(input[2 + first_length + i]); written++ }
		}
		return i64(written)
	}
}
