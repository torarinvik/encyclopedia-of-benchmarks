module unique_permutation

const max_length = 6

struct PermutationState {
	mut:
	values [max_length]i32
	current [max_length]i32
	used [max_length]bool
	output &u8
	result_count int
}

fn generate(mut state PermutationState, n int, depth int) {
	if depth == n {
		row := state.result_count * n
		for i in 0 .. n { unsafe { state.output[row + i] = u8(state.current[i]) } }
		state.result_count++
		return
	}
	for i in 0 .. n {
		if state.used[i] { continue }
		if i > 0 && state.values[i] == state.values[i - 1] && !state.used[i - 1] { continue }
		state.current[depth] = state.values[i]
		state.used[i] = true
		generate(mut state, n, depth + 1)
		state.used[i] = false
	}
}

@[export: 'unique_permutation']
pub fn unique_permutation(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 1 || length > max_length + 1 { return -1 }
	n_value := unsafe { input[0] }
	if n_value < 0 || n_value > max_length || length != usize(n_value + 1) { return -1 }
	n := int(n_value)
	mut state := PermutationState{output: output}
	for i in 0 .. n {
		value := unsafe { input[i + 1] }
		if value < 0 || value > 127 { return -1 }
		state.values[i] = i32(value)
	}
	for i := 1; i < n; i++ {
		value := state.values[i]
		mut position := i
		for position > 0 && state.values[position - 1] > value { state.values[position] = state.values[position - 1]; position-- }
		state.values[position] = value
	}
	mut max_count := 1
	mut factor := 2
	for factor <= n { max_count *= factor; factor++ }
	required := usize(max_count * n)
	if output_capacity < required { return -2 }
	generate(mut state, n, 0)
	return i64(state.result_count)
}
