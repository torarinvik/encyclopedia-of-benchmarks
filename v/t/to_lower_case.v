module to_lower_case

const max_length = 4096

// Lowercase ASCII bytes without locale-dependent character handling.
@[export: 'to_lower_case']
pub fn to_lower_case(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length > max_length { return -1 }
	for index in 0 .. length {
		value := unsafe { input[index] }
		if value < 1 || value > 127 { return -1 }
	}
	if output_capacity < length { return -2 }
	for index in 0 .. length {
		mut value := unsafe { input[index] }
		if value >= 65 && value <= 90 { value += 32 }
		unsafe { output[index] = u8(value) }
	}
	return i64(length)
}
