module long_chain_kth_ancestor

struct LongChainAncestorState {
	parent [64]int
	depth [64]int
	height [64]int
	heavy [64]int
	chain_head [64]int
	chain_position [64]int
	chain_base [64]int
	chain_nodes [64]int
	head_ancestors [64]int
	up [384]int
}

fn solve(mut state LongChainAncestorState, n int) {
	state.parent[0] = -1
	for vertex in 0 .. n {
		state.heavy[vertex] = -1
		state.chain_head[vertex] = -1
		state.chain_base[vertex] = -1
		state.height[vertex] = 1
		if vertex > 0 { state.depth[vertex] = state.depth[state.parent[vertex]] + 1 }
	}
	for reverse in 1 .. n {
		vertex := n - reverse
		parent := state.parent[vertex]
		old := state.heavy[parent]
		if old < 0 || state.height[vertex] > state.height[old] ||
			(state.height[vertex] == state.height[old] && vertex < old) {
			state.heavy[parent] = vertex
		}
		state.height[parent] = max(state.height[parent], state.height[vertex] + 1)
	}

	mut pool := 0
	for vertex in 0 .. n {
		if vertex == 0 || state.heavy[state.parent[vertex]] != vertex {
			state.chain_base[vertex] = pool
			mut current := vertex
			mut position := 0
			for current >= 0 {
				state.chain_head[current] = vertex
				state.chain_position[current] = position
				state.chain_nodes[pool + position] = current
				current = state.heavy[current]
				position++
			}
			current = state.parent[vertex]
			for step in 0 .. position {
				state.head_ancestors[pool + step] = current
				if current >= 0 { current = state.parent[current] } else { current = -1 }
			}
			pool += position
		}
	}
	for vertex in 0 .. n { state.up[vertex] = state.parent[vertex] }
	for level in 1 .. 6 {
		for vertex in 0 .. n {
			halfway := state.up[(level - 1) * 64 + vertex]
			if halfway >= 0 { state.up[level * 64 + vertex] = state.up[(level - 1) * 64 + halfway] }
			else { state.up[level * 64 + vertex] = -1 }
		}
	}
}

@[export: 'long_chain_kth_ancestor']
pub fn long_chain_kth_ancestor(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 130 { return -1 }
		n_value, q_value := input[0], input[1]
		if n_value < 1 || n_value > 64 || q_value < 1 || q_value > 32 { return -1 }
		n, q := int(n_value), int(q_value)
		if length != usize(n + 1 + 2*q) { return -1 }
		for vertex in 1 .. n {
			if input[1 + vertex] < 0 || input[1 + vertex] >= i64(vertex) { return -1 }
		}
		query_start := n + 1
		for query in 0 .. q {
			vertex, distance := input[query_start + 2*query], input[query_start + 2*query + 1]
			if vertex < 0 || vertex >= n_value || distance < 0 || distance >= 64 { return -1 }
		}
		required := 8*q
		if output == nil || capacity < usize(required) { return -2 }

		mut state := LongChainAncestorState{}
		state.parent[0] = -1
		for vertex in 1 .. n { state.parent[vertex] = int(input[1 + vertex]) }
		solve(mut state, n)
		for query in 0 .. q {
			vertex, distance := int(input[query_start + 2*query]), int(input[query_start + 2*query + 1])
			mut answer := -1
			if distance <= state.depth[vertex] {
				if distance == 0 { answer = vertex }
				else {
					mut level := 0
					mut value := distance
					for value > 1 { level++; value >>= 1 }
					jumped := state.up[level*64 + vertex]
					remaining := distance - (1 << level)
					head := state.chain_head[jumped]
					position := state.chain_position[jumped]
					base := state.chain_base[head]
					if remaining <= position { answer = state.chain_nodes[base + position - remaining] }
					else {
						steps := remaining - position
						if steps <= state.height[head] { answer = state.head_ancestors[base + steps - 1] }
					}
				}
			}
			bits := u64(answer)
			for byte in 0 .. 8 { output[8*query + byte] = u8(bits >> (8*byte)) }
		}
		return i64(required)
	}
}
