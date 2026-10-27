module reverse_search_permutation_enumeration

const max_n = 4
const max_input = 2
const max_words = 97

struct SearchState {
	mut:
		n int
		permutation [max_n]i64
		staged [max_words]i64
		cursor int
}

fn visit(mut state SearchState) {
	for index in 0 .. state.n {
		state.staged[state.cursor] = state.permutation[index]
		state.cursor++
	}
	mut reverse_point := state.n
	for index in 0 .. state.n - 1 {
		if state.permutation[index] > state.permutation[index + 1] {
			reverse_point = index + 1
			break
		}
	}
	for child in 1 .. reverse_point {
		state.permutation[child - 1], state.permutation[child] = state.permutation[child], state.permutation[child - 1]
		visit(mut state)
		state.permutation[child - 1], state.permutation[child] = state.permutation[child], state.permutation[child - 1]
	}
	if reverse_point + 2 <= state.n && state.permutation[reverse_point - 1] < state.permutation[reverse_point + 1] {
		left := reverse_point
		state.permutation[left], state.permutation[left + 1] = state.permutation[left + 1], state.permutation[left]
		visit(mut state)
		state.permutation[left], state.permutation[left + 1] = state.permutation[left + 1], state.permutation[left]
	}
}

fn store_i64_le(output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'reverse_search_permutation_enumeration']
pub fn reverse_search_permutation_enumeration(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if isnil(input) || length < 1 || length > max_input { return -1 }
		n_value := input[0]
		if length != 1 || n_value < 1 || n_value > max_n { return -1 }
		n := int(n_value)
		mut count := 1
		for factor in 2 .. n + 1 { count *= factor }
		words := 1 + n * count
		required := usize(words * 8)
		if isnil(output) || capacity < required { return -2 }
		mut state := SearchState{n: n, cursor: 1}
		state.staged[0] = i64(count)
		for index in 0 .. n { state.permutation[index] = i64(index + 1) }
		visit(mut state)
		for word in 0 .. words { store_i64_le(output, word * 8, state.staged[word]) }
		return i64(required)
	}
}
