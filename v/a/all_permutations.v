module all_permutations

const max_length = 6
const bytes_per_value = 4

struct PermutationState {
	mut:
	values [max_length]i32
	current [max_length]i32
	used [max_length]bool
	output &u8
	result_count int
}

fn store_i32_le(output &u8, position int, value i32) {
	bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[position + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

fn generate(mut state PermutationState, n int, depth int) {
	if depth == n {
		row_start := state.result_count * n * bytes_per_value
		for index in 0 .. n {
			store_i32_le(state.output, row_start + index * bytes_per_value, state.current[index])
		}
		state.result_count++
		return
	}
	for index in 0 .. n {
		if state.used[index] { continue }
		state.current[depth] = state.values[index]
		state.used[index] = true
		generate(mut state, n, depth + 1)
		state.used[index] = false
	}
}

@[export: 'all_permutations']
pub fn all_permutations(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 1 || length > max_length + 1 { return -1 }
	n_value := unsafe { input[0] }
	if n_value < 0 || n_value > max_length || length != usize(n_value + 1) { return -1 }
	n := int(n_value)
	mut state := PermutationState{output: output}
	for index in 0 .. n {
		value := unsafe { input[index + 1] }
		if value < -2147483648 || value > 2147483647 { return -1 }
		state.values[index] = i32(value)
	}
	mut permutation_count := 1
	for factor in 2 .. n + 1 { permutation_count *= factor }
	required := usize(permutation_count * n * bytes_per_value)
	if output_capacity < required { return -2 }
	generate(mut state, n, 0)
	return i64(state.result_count)
}
