module swap_pairs

const max_length = 1024

// Swap adjacent node values in a bounded array representation of a list.
@[export: 'swap_pairs']
pub fn swap_pairs(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length > max_length { return -1 }
	for index in 0 .. length {
		value := unsafe { input[index] }
		if value < -2147483648 || value > 2147483647 { return -1 }
	}
	output_bytes := length * 4
	if output_capacity < output_bytes || (output_bytes != 0 && unsafe { output == nil }) { return -2 }

	for index in 0 .. length {
		pair_start := (index / 2) * 2
		mut source_index := pair_start
		if index % 2 == 0 && pair_start + 1 < length { source_index = pair_start + 1 }
		bits := u32(i32(unsafe { input[source_index] }))
		for byte in 0 .. 4 {
			unsafe { output[index * 4 + byte] = u8((bits >> (byte * 8)) & 0xff) }
		}
	}
	return i64(length)
}
