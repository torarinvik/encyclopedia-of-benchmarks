module long_chain_dominant_depth_index

struct LongChainState {
	parent [64]int
	first_child [64]int
	next_sibling [64]int
	height [64]int
	heavy [64]int
	base [64]int
	count [64]int
	dominant_depth [64]int
}

fn solve(mut state LongChainState, n int) {
	for vertex in 0 .. n {
		state.first_child[vertex] = -1
		state.heavy[vertex] = -1
		state.height[vertex] = 1
	}
	state.parent[0] = -1
	for vertex in 1 .. n {
		parent := state.parent[vertex]
		state.next_sibling[vertex] = state.first_child[parent]
		state.first_child[parent] = vertex
	}

	for reverse in 0 .. n {
		vertex := n - 1 - reverse
		mut child := state.first_child[vertex]
		mut maximum_height := 0
		for child >= 0 {
			child_height := state.height[child]
			if child_height > maximum_height || (child_height == maximum_height && child < state.heavy[vertex]) {
				maximum_height = child_height
				state.heavy[vertex] = child
			}
			child = state.next_sibling[child]
		}
		state.height[vertex] = maximum_height + 1
	}

	mut pool_size := 0
	for vertex in 0 .. n {
		if vertex == 0 || state.heavy[state.parent[vertex]] != vertex {
			mut current := vertex
			for current >= 0 {
				state.base[current] = pool_size
				pool_size++
				current = state.heavy[current]
			}
		}
	}

	for reverse in 0 .. n {
		vertex := n - 1 - reverse
		base := state.base[vertex]
		state.count[base] = 1
		mut best_depth := 0
		mut best_count := 1
		heavy := state.heavy[vertex]
		if heavy >= 0 {
			best_depth = state.dominant_depth[heavy] + 1
			best_count = state.count[base + best_depth]
		}
		mut child := state.first_child[vertex]
		for child >= 0 {
			if child != heavy {
				for child_depth in 0 .. state.height[child] {
					depth := child_depth + 1
					slot := base + depth
					amount := state.count[slot] + state.count[state.base[child] + child_depth]
					state.count[slot] = amount
					if amount > best_count || (amount == best_count && depth < best_depth) {
						best_count = amount
						best_depth = depth
					}
				}
			}
			child = state.next_sibling[child]
		}
		state.dominant_depth[vertex] = best_depth
	}
}

@[export: 'long_chain_dominant_depth_index']
pub fn long_chain_dominant_depth_index(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length == 0 || length > 65 { return -1 }
		n_value := input[0]
		if n_value < 1 || n_value > 64 || length != usize(n_value) { return -1 }
		n := int(n_value)
		for vertex in 1 .. n {
			if input[vertex] < 0 || input[vertex] >= i64(vertex) { return -1 }
		}
		required := 8 * n
		if output == nil || capacity < usize(required) { return -2 }
		mut state := LongChainState{}
		for vertex in 1 .. n { state.parent[vertex] = int(input[vertex]) }
		solve(mut state, n)
		for vertex in 0 .. n {
			bits := u64(state.dominant_depth[vertex])
			for byte in 0 .. 8 { output[8*vertex+byte] = u8(bits >> (8*byte)) }
		}
		return i64(required)
	}
}
