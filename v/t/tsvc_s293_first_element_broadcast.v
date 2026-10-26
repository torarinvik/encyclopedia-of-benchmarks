// Clean-room implementation of TSVC s293; see package rights note.
const max_n = 32
const max_input_length = 33

fn store_i64_le(output &u8, offset int, value i64) {
	mut bits := u64(value)
	for b in 0 .. 8 {
		unsafe { output[offset + b] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'tsvc_s293_first_element_broadcast']
pub fn tsvc_s293_first_element_broadcast(input &i64, input_length usize,
	output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || input_length < 2 || input_length > max_input_length { return -1 }
	value_n := unsafe { input[0] }
	if value_n < 1 || value_n > max_n || input_length != usize(1 + value_n) { return -1 }
	n := int(value_n)
	for i in 1 .. n + 1 {
		value := unsafe { input[i] }
		if value < -8 || value > 8 { return -1 }
	}
	bytes := 8*n
	if unsafe { output == nil } || output_capacity < usize(bytes) { return -2 }
	mut staged := [max_n]i64{}
	first := unsafe { input[1] }
	for i in 0 .. n { staged[i] = first }
	for i in 0 .. n { store_i64_le(output, 8*i, staged[i]) }
	return i64(bytes)
}
