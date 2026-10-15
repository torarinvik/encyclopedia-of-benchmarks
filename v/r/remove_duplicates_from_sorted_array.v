module remove_duplicates_from_sorted_array

const max_length = 4096

// Compact each value in an ascending array to its first occurrence.
@[export: 'remove_duplicates_from_sorted_array']
pub fn remove_duplicates_from_sorted_array(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length > max_length { return -1 }
	mut unique_count := usize(0)
	for index in 0 .. length {
		value := unsafe { input[index] }
		if value < -2147483648 || value > 2147483647 ||
			(index > 0 && unsafe { input[index - 1] } > value) { return -1 }
		if index == 0 || unsafe { input[index - 1] } != value { unique_count++ }
	}
	output_bytes := unique_count * 4
	if output_capacity < output_bytes || (output_bytes != 0 && unsafe { output == nil }) { return -2 }
	mut written := usize(0)
	for index in 0 .. length {
		value := unsafe { input[index] }
		if index == 0 || unsafe { input[index - 1] } != value {
			bits := u32(i32(value))
			for byte in 0 .. 4 {
				unsafe { output[written * 4 + byte] = u8((bits >> (byte * 8)) & 0xff) }
			}
			written++
		}
	}
	if written != unique_count { return -1 }
	return i64(written)
}
