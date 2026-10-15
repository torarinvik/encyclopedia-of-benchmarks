module remove_element

const max_length = 4096

// Remove every occurrence of target while preserving the surviving order.
@[export: 'remove_element']
pub fn remove_element(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length == 0 || length > max_length { return -1 }
	target := unsafe { input[0] }
	if target < -2147483648 || target > 2147483647 { return -1 }
	mut survivor_count := usize(0)
	for index in 1 .. length {
		value := unsafe { input[index] }
		if value < -2147483648 || value > 2147483647 { return -1 }
		if value != target { survivor_count++ }
	}
	output_bytes := survivor_count * 4
	if output_capacity < output_bytes || (output_bytes != 0 && unsafe { output == nil }) { return -2 }
	mut written := usize(0)
	for index in 1 .. length {
		value := unsafe { input[index] }
		if value != target {
			bits := u32(i32(value))
			for byte in 0 .. 4 {
				unsafe { output[written * 4 + byte] = u8((bits >> (byte * 8)) & 0xff) }
			}
			written++
		}
	}
	if written != survivor_count { return -1 }
	return i64(written)
}
