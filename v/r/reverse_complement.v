module reverse_complement

const max_reverse_complement_length = 1000

@[export: 'reverse_complement']
pub fn reverse_complement(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length > max_reverse_complement_length { return -1 }
	for index in 0 .. length {
		base := unsafe { input[index] }
		if base != 65 && base != 67 && base != 71 && base != 84 { return -1 }
	}
	if output_capacity < length { return -2 }
	for index in 0 .. length {
		base := unsafe { input[length - 1 - index] }
		complement := if base == 65 { 84 } else if base == 84 { 65 } else if base == 67 { 71 } else { 67 }
		unsafe { output[index] = u8(complement) }
	}
	return i64(length)
}
