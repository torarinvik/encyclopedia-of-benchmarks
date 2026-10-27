module clique_reverse_search_enumeration

const max_n = 8
const max_input = 9
const max_cliques = 256
const max_output_bytes = 264

struct SearchState {
	mut:
		n int
		adjacency [max_n]u16
		masks [max_cliques]u8
		count int
}

fn visit(mut state SearchState, clique u16) {
	state.masks[state.count] = u8(clique)
	state.count++
	mut minimum := state.n
	for vertex in 0 .. state.n {
		if clique & (u16(1) << vertex) != 0 { minimum = vertex; break }
	}
	for vertex in 0 .. minimum {
		bit := u16(1) << vertex
		if clique & bit == 0 && state.adjacency[vertex] & clique == clique {
			visit(mut state, clique | bit)
		}
	}
}

fn store_i64_le(output &u8, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'clique_reverse_search_enumeration']
pub fn clique_reverse_search_enumeration(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if isnil(input) || length < 2 || length > max_input { return -1 }
		n_value := input[0]
		if n_value < 1 || n_value > max_n || length != usize(n_value + 1) { return -1 }
		n := int(n_value)
		mut state := SearchState{n: n}
		for vertex in 0 .. n {
			raw := input[vertex + 1]
			if raw < 0 || raw >= (i64(1) << n) || (raw & (i64(1) << vertex)) != 0 { return -1 }
			state.adjacency[vertex] = u16(raw)
		}
		for left in 0 .. n {
			for right in left + 1 .. n {
				edge_left := state.adjacency[left] & (u16(1) << right) != 0
				edge_right := state.adjacency[right] & (u16(1) << left) != 0
				if edge_left != edge_right { return -1 }
			}
		}
		visit(mut state, 0)
		required := 8 + state.count
		if isnil(output) || capacity < usize(required) { return -2 }
		mut staged := [max_output_bytes]u8{init: 0}
		store_i64_le(&staged[0], i64(state.count))
		for index in 0 .. state.count { staged[8 + index] = state.masks[index] }
		for byte in 0 .. required { output[byte] = staged[byte] }
		return i64(required)
	}
}
