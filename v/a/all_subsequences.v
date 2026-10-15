module all_subsequences

const max_length = 8
const bytes_per_value = 4

struct SubsequenceState {
	mut:
	values [max_length]i32
	current [max_length]i32
	output &u8
	output_cursor int
	result_count int
}

fn store_u32_le(output &u8, position int, value u32) {
	for byte in 0 .. 4 {
		unsafe { output[position + byte] = u8((value >> (byte * 8)) & 255) }
	}
}

fn store_i32_le(output &u8, position int, value i32) {
	store_u32_le(output, position, u32(value))
}

fn generate(mut state SubsequenceState, n int, index int, current_length int) {
	if index == n {
		store_u32_le(state.output, state.output_cursor, u32(current_length))
		state.output_cursor += bytes_per_value
		for item in 0 .. current_length {
			store_i32_le(state.output, state.output_cursor, state.current[item])
			state.output_cursor += bytes_per_value
		}
		state.result_count++
		return
	}
	generate(mut state, n, index + 1, current_length)
	state.current[current_length] = state.values[index]
	generate(mut state, n, index + 1, current_length + 1)
}

@[export: 'all_subsequences']
pub fn all_subsequences(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 1 || length > max_length + 1 { return -1 }
	n_value := unsafe { input[0] }
	if n_value < 0 || n_value > max_length || length != usize(n_value + 1) { return -1 }
	n := int(n_value)
	mut state := SubsequenceState{output: output}
	for index in 0 .. n {
		value := unsafe { input[index + 1] }
		if value < -2147483648 || value > 2147483647 { return -1 }
		state.values[index] = i32(value)
	}
	mut result_count := 1
	for _ in 0 .. n { result_count *= 2 }
	value_count := if n == 0 { 0 } else { n * (result_count / 2) }
	required := usize((result_count + value_count) * bytes_per_value)
	if output_capacity < required { return -2 }
	generate(mut state, n, 0, 0)
	return i64(state.result_count)
}
