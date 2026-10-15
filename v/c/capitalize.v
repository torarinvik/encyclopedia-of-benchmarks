module capitalize

@[export: 'capitalize']
pub fn capitalize(input &i64, length usize, output &u8, capacity usize) i64 {
	if length > 256 || (length > 0 && unsafe { input == nil }) { return -1 }
	for i in 0 .. length {
		value := unsafe { input[i] }
		if value < 0 || value > 127 { return -1 }
	}
	if capacity < length || (length > 0 && unsafe { output == nil }) { return -2 }
	for i in 0 .. length { unsafe { output[i] = u8(input[i]) } }
	if length > 0 && unsafe { output[0] >= u8('a') && output[0] <= u8('z') } {
		unsafe { output[0] -= 32 }
	}
	return i64(length)
}
