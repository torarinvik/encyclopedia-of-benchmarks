module binary_to_gray

// Convert an ASCII binary string to equal-width ASCII Gray code.
@[export: 'binary_to_gray']
pub fn binary_to_gray(bits &i64, length usize, output &u8, output_capacity usize) i64 {
	if length == 0 || length > 66 { return -1 }
	unsafe {
		for index := usize(0); index < length; index++ {
			if bits[index] != 48 && bits[index] != 49 { return -1 }
		}
		if output_capacity < length { return -2 }
		for index := usize(0); index < length; index++ {
			current := bits[index] - 48
			previous := i64(0)
			if index > 0 { previous = bits[index - 1] - 48 }
			output[index] = u8(48 + (current ^ previous))
		}
	}
	return i64(length)
}
