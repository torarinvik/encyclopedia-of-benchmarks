module permutation_array

const max_length = 6
const max_parseable_length = 8

struct PermutationState {
	mut:
		values [max_length]i32
		output &u8
		result_count int
}

fn store_i32_le(output &u8, position int, value i32) {
	bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[position + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

fn generate(mut state PermutationState, n int, index int) {
	if index == n {
		row_start := state.result_count * n * 4
		for column in 0 .. n {
			store_i32_le(state.output, row_start + column * 4, state.values[column])
		}
		state.result_count++
		return
	}
	for position in index .. n {
		saved := state.values[index]
		state.values[index] = state.values[position]
		state.values[position] = saved
		generate(mut state, n, index + 1)
		restore := state.values[index]
		state.values[index] = state.values[position]
		state.values[position] = restore
	}
}

@[export: 'permutation_array']
pub fn permutation_array(input &i64, length usize, output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_length { return -1 }
		n_value := input[0]
		if n_value < 0 || n_value > max_length || length != usize(n_value + 1) { return -1 }
		n := int(n_value)
		mut state := PermutationState{output: output}
		for index in 0 .. n {
			value := input[index + 1]
			if value < -2147483648 || value > 2147483647 { return -1 }
			state.values[index] = i32(value)
		}
		mut permutation_count := 1
		for factor in 2 .. n + 1 { permutation_count *= factor }
		required := usize(permutation_count * n * 4)
		if output_capacity < required || (required > 0 && output == nil) { return -2 }
		generate(mut state, n, 0)
		return i64(state.result_count)
	}
}
