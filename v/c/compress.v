module compress

const max_length = 64
const bytes_per_value = 4

@[export: 'compress']
pub fn compress(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_length + 1 { return -1 }
	count_value := unsafe { input[0] }
	if count_value < 0 || count_value > max_length || length != 1 + usize(count_value) { return -1 }
	count := int(count_value)
	for index in 0 .. count {
		value := unsafe { input[1 + index] }
		if value < -2147483648 || value > 2147483647 { return -1 }
	}

	maximum_bytes := usize(count * bytes_per_value)
	if output_capacity < maximum_bytes || (maximum_bytes > 0 && unsafe { output == nil }) { return -2 }
	mut result_count := 0
	mut previous := i64(0)
	for index in 0 .. count {
		value := unsafe { input[1 + index] }
		if index == 0 || value != previous {
			bits := u32(value)
			for byte in 0 .. bytes_per_value {
				unsafe { output[result_count * bytes_per_value + byte] = u8((bits >> u32(byte * 8)) & 255) }
			}
			result_count++
		}
		previous = value
	}
	return i64(result_count)
}
