module dag_minimum_path_cover

const max_vertices = 10
const max_edges = 45
const max_parseable_length = 93

fn dmpc_augment(left int, n int, used u16, adjacency []u16, mut seen []bool,
	mut match_right []int) bool {
	for right in 0 .. n {
		bit := u16(1) << u16(right)
		if adjacency[left] & bit == 0 || used & bit != 0 || seen[right] { continue }
		seen[right] = true
		mate := match_right[right]
		if mate < 0 || dmpc_augment(mate, n, used, adjacency, mut seen, mut match_right) {
			match_right[right] = left
			return true
		}
	}
	return false
}

fn dmpc_maximum(n int, first int, used u16, adjacency []u16) int {
	mut match_right := []int{len: max_vertices, init: -1}
	mut size := 0
	for left in first .. n {
		mut seen := []bool{len: max_vertices}
		if dmpc_augment(left, n, used, adjacency, mut seen, mut match_right) { size++ }
	}
	return size
}

@[export: 'dag_minimum_path_cover']
pub fn dag_minimum_path_cover(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_parseable_length { return -1 }
		n_value := input[0]
		m_value := input[1]
		if n_value < 1 || n_value > max_vertices || m_value < 0 || m_value > max_edges { return -1 }
		n := int(n_value)
		m := int(m_value)
		if length != usize(2 + 2*m) { return -1 }

		mut adjacency := []u16{len: max_vertices}
		mut indegree := []int{len: max_vertices}
		for edge in 0 .. m {
			u64 := input[2 + 2*edge]
			v64 := input[3 + 2*edge]
			if u64 < 0 || u64 >= n_value || v64 < 0 || v64 >= n_value || u64 == v64 { return -1 }
			u := int(u64)
			v := int(v64)
			bit := u16(1) << u16(v)
			if adjacency[u] & bit != 0 { return -1 }
			adjacency[u] |= bit
			indegree[v]++
		}

		mut queue := []int{cap: max_vertices}
		for vertex in 0 .. n { if indegree[vertex] == 0 { queue << vertex } }
		mut head := 0
		mut removed := 0
		for head < queue.len {
			u := queue[head]
			head++
			removed++
			for v in 0 .. n {
				if adjacency[u] & (u16(1) << u16(v)) != 0 {
					indegree[v]--
					if indegree[v] == 0 { queue << v }
				}
			}
		}
		if removed != n { return -1 }

		maximum := dmpc_maximum(n, 0, 0, adjacency)
		mut successor := []int{len: max_vertices, init: n}
		mut used := u16(0)
		mut fixed := 0
		for left in 0 .. n {
			mut chosen := false
			for right in 0 .. n + 1 {
				matched := right < n
				if matched {
					bit := u16(1) << u16(right)
					if adjacency[left] & bit == 0 || used & bit != 0 { continue }
				}
				next_used := if matched { used | (u16(1) << u16(right)) } else { used }
				if fixed + int(matched) + dmpc_maximum(n, left + 1, next_used, adjacency) == maximum {
					successor[left] = right
					used = next_used
					if matched { fixed++ }
					chosen = true
					break
				}
			}
			if !chosen { return -1 }
		}
		mut packed := u64(n - maximum) << 40
		for vertex in 0 .. n { packed |= u64(successor[vertex]) << u64(4*vertex) }
		return i64(packed)
	}
}
