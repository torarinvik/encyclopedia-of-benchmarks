module bst_interleave_bound

const max_nodes = 8
const max_accesses = 16
const max_input = 36
const none = 8

fn store_i64_le(mut output []u8, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[byte] = u8((bits >> (8 * byte)) & 255) }
}

@[export: 'bst_interleave_bound']
pub fn bst_interleave_bound(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		n_raw, root_raw := input[0], input[1]
		if n_raw < 1 || n_raw > max_nodes || root_raw < 0 || root_raw >= n_raw { return -1 }
		n, root := int(n_raw), int(root_raw)
		mut left := [max_nodes]int{init: none}
		mut right := [max_nodes]int{init: none}
		mut parent := [max_nodes]int{init: none}
		mut parent_count := [max_nodes]int{init: 0}
		mut position := 2
		for node in 0 .. n {
			if position + 2 > int(length) { return -1 }
			l, r := input[position], input[position + 1]
			position += 2
			if l < -1 || l >= n_raw || r < -1 || r >= n_raw || l == node || r == node || (l >= 0 && l == r) { return -1 }
			if l >= 0 { li := int(l); left[node] = li; parent_count[li]++; parent[li] = node }
			if r >= 0 { ri := int(r); right[node] = ri; parent_count[ri]++; parent[ri] = node }
		}
		if parent_count[root] != 0 { return -1 }
		for node in 0 .. n { if node != root && parent_count[node] != 1 { return -1 } }
		if position >= int(length) { return -1 }
		m_raw := input[position]
		position++
		if m_raw < 0 || m_raw > max_accesses || int(length) != position + int(m_raw) { return -1 }
		m := int(m_raw)
		mut accesses := [max_accesses]int{init: 0}
		for i in 0 .. m {
			key := input[position]
			position++
			if key < 0 || key >= n_raw { return -1 }
			accesses[i] = int(key)
		}

		mut stack_node := [max_nodes]int{init: 0}
		mut stack_low := [max_nodes]int{init: 0}
		mut stack_high := [max_nodes]int{init: 0}
		mut visited := [max_nodes]bool{init: false}
		mut stack_size, mut visited_count := 1, 0
		stack_node[0], stack_low[0], stack_high[0] = root, -1, n
		for stack_size > 0 {
			stack_size--
			node, low, high := stack_node[stack_size], stack_low[stack_size], stack_high[stack_size]
			if visited[node] || node <= low || node >= high { return -1 }
			visited[node] = true
			visited_count++
			if left[node] != none {
				stack_node[stack_size], stack_low[stack_size], stack_high[stack_size] = left[node], low, node
				stack_size++
			}
			if right[node] != none {
				stack_node[stack_size], stack_low[stack_size], stack_high[stack_size] = right[node], node, high
				stack_size++
			}
		}
		if visited_count != n { return -1 }

		mut bound := i64(0)
		for pivot in 0 .. n {
			mut previous := -1
			for i in 0 .. m {
				key := accesses[i]
				mut ancestor := key
				for ancestor != none && ancestor != pivot { ancestor = parent[ancestor] }
				if ancestor == pivot {
					side := if key <= pivot { 0 } else { 1 }
					if previous >= 0 && side != previous { bound++ }
					previous = side
				}
			}
		}
		if output == nil || capacity < 8 { return -2 }
		mut staged := [8]u8{init: 0}
		store_i64_le(mut staged[..], bound)
		for byte in 0 .. 8 { output[byte] = staged[byte] }
		return 8
	}
}
