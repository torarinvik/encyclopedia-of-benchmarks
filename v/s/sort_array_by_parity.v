module sort_array_by_parity

const max_array_length = 5000

// Place evens first and fill the odd section from its end.
@[export: 'sort_array_by_parity']
pub fn sort_array_by_parity(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length > max_array_length { return -1 }
	for index in 0 .. int(length) {
		value := unsafe { input[index] }
		if value < 0 || value > 5000 { return -1 }
	}
	output_bytes := int(length) * 4
	if output_capacity < usize(output_bytes) { return -2 }

	mut even_index := 0
	mut odd_index := int(length)
	for index in 0 .. int(length) {
		value := u32(unsafe { input[index] })
		mut destination := 0
		if (value & 1) == 0 {
			destination = even_index
			even_index++
		} else {
			odd_index--
			destination = odd_index
		}
		for byte in 0 .. 4 {
			unsafe { output[destination * 4 + byte] = u8((value >> (byte * 8)) & 255) }
		}
	}
	return i64(length)
}
