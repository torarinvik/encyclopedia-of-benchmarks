module xor_linked_list

const max_count = 64
const max_input_length = 66

fn write_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'xor_linked_list']
pub fn xor_linked_list(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_length { return -1 }
	count_value := unsafe { input[0] }
	if count_value < 0 || count_value > max_count || length != usize(count_value + 1) { return -1 }
	count := int(count_value)
	for index in 0 .. count {
		value := unsafe { input[index + 1] }
		if value < -2147483648 || value > 2147483647 { return -1 }
	}
	needed := 8 + 8 * count
	if unsafe { output == nil } || capacity < usize(needed) { return -2 }

	mut node_values := [65]i64{}
	mut both := [65]int{}
	mut tail := 0
	for index in 0 .. count {
		node_id := index + 1
		node_values[node_id] = unsafe { input[index + 1] }
		both[node_id] = tail
		if tail != 0 { both[tail] ^= node_id }
		tail = node_id
	}
	write_i64_le(mut output, 0, count_value)
	mut out := 8
	mut previous := 0
	mut current := if count == 0 { 0 } else { 1 }
	for current != 0 {
		write_i64_le(mut output, out, node_values[current])
		out += 8
		next_id := previous ^ both[current]
		previous = current
		current = next_id
	}
	return i64(needed)
}
