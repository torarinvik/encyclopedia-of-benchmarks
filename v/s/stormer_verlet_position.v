module stormer_verlet_position

const max_steps = 32
const max_input_values = max_steps + 1
const max_output_bytes = max_steps * 8

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'stormer_verlet_position']
pub fn stormer_verlet_position(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_input_values { return -1 }
	count_value := unsafe { input[0] }
	if count_value < 2 || count_value > max_steps { return -1 }
	if length != usize(count_value + 1) { return -1 }
	if unsafe { input[1] < -1024 || input[1] > 1024 || input[2] < -1024 || input[2] > 1024 } { return -1 }
	count := int(count_value)
	for step in 0 .. (count - 2) {
		term := unsafe { input[3 + step] }
		if term < -64 || term > 64 { return -1 }
	}

	byte_count := 8 * count
	if unsafe { output == nil } || output_capacity < usize(byte_count) { return -2 }
	mut staged := [max_output_bytes]u8{}
	mut previous := unsafe { input[1] }
	mut current := unsafe { input[2] }
	store_i64_le(mut &staged[0], 0, previous)
	store_i64_le(mut &staged[0], 8, current)
	for index in 2 .. count {
		next := 2 * current - previous + unsafe { input[index + 1] }
		store_i64_le(mut &staged[0], 8 * index, next)
		previous = current
		current = next
	}
	for byte in 0 .. byte_count { unsafe { output[byte] = staged[byte] } }
	return i64(byte_count)
}
