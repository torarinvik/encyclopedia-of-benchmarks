module alternative_list_arrange

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & u64(255)) }
	}
}

@[export: 'alternative_list_arrange']
pub fn alternative_list_arrange(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 2 || unsafe { input == nil } { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > 64 { return -1 }
		a := int(input[0])
		if usize(1 + a) >= length || input[1 + a] < 0 || input[1 + a] > 64 { return -1 }
		b := int(input[1 + a])
		if length != usize(2 + a + b) { return -1 }
		count := a + b
		if count == 0 { return 0 }
		if output_capacity < usize(count * 8) || output == nil { return -2 }
		mut written := 0
		limit := if a > b { a } else { b }
		for i in 0 .. limit {
			if i < a { store_i64_le(mut output, written * 8, input[1 + i]); written++ }
			if i < b { store_i64_le(mut output, written * 8, input[2 + a + i]); written++ }
		}
		return i64(count)
	}
}
