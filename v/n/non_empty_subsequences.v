module non_empty_subsequences

const max_runes = 8
const max_input_length = max_runes + 2
const bytes_per_value = 4

struct SubsequenceState {
	mut:
		values [max_runes]i32
		current [max_runes]i32
		output &u8
		output_cursor usize
		row_count usize
}

fn is_unicode_scalar(value i64) bool {
	return value >= 0 && value <= 0x10ffff && !(value >= 0xd800 && value <= 0xdfff)
}

fn store_u32_le(output &u8, position usize, value u32) {
	for byte in 0 .. bytes_per_value {
		unsafe { output[position + byte] = u8((value >> (byte * 8)) & 255) }
	}
}

fn emit_row(mut state SubsequenceState, length usize) {
	store_u32_le(state.output, state.output_cursor, u32(length))
	state.output_cursor += bytes_per_value
	for item in 0 .. length {
		store_u32_le(state.output, state.output_cursor, u32(state.current[item]))
		state.output_cursor += bytes_per_value
	}
	state.row_count++
}

fn generate(mut state SubsequenceState, n usize, start usize, current_length usize) {
	for index in start .. n {
		state.current[current_length] = state.values[index]
		emit_row(mut state, current_length + 1)
		generate(mut state, n, index + 1, current_length + 1)
	}
}

@[export: 'non_empty_subsequences']
pub fn non_empty_subsequences(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_length { return -1 }
	count_value := unsafe { input[0] }
	if count_value < 1 || count_value > max_runes || length != usize(count_value + 1) { return -1 }
	n := usize(count_value)
	mut state := SubsequenceState{output: output}
	unsafe {
		for index in 0 .. n {
			value := input[index + 1]
			if !is_unicode_scalar(value) { return -1 }
			state.values[index] = i32(value)
		}
	}
	rows := (usize(1) << n) - 1
	required := (rows + n * (usize(1) << (n - 1))) * bytes_per_value
	if output_capacity < required || unsafe { output == nil } { return -2 }
	generate(mut state, n, 0, 0)
	return i64(state.row_count)
}
