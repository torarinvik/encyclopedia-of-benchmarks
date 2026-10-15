module reverse_string

@[export: 'reverse_string']
pub fn reverse_string(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 1 || unsafe { input == nil } { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > 256 { return -1 }
		n := int(input[0])
		if length != usize(n + 1) { return -1 }
		for i in 0 .. n {
			if input[i + 1] < 33 || input[i + 1] > 126 { return -1 }
		}
		if output == nil || output_capacity < usize(n + 1) { return -2 }
		for i in 0 .. n {
			output[i] = u8(input[n - i])
		}
		output[n] = 0
		return i64(n)
	}
}
