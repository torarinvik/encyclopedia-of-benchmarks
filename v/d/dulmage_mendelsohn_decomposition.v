module dulmage_mendelsohn_decomposition

const side = 6
const vertices = 12
const max_edges = 36
const max_parseable_length = 76

fn dm_augment(left int, right_count int, adjacency []u16, mut seen []bool,
	mut match_right []int) bool {
	for right in 0 .. right_count {
		bit := u16(1) << u16(right)
		if adjacency[left] & bit == 0 || seen[right] { continue }
		seen[right] = true
		mate := match_right[right]
		if mate < 0 || dm_augment(mate, right_count, adjacency, mut seen, mut match_right) {
			match_right[right] = left
			return true
		}
	}
	return false
}

fn dm_matching(left_count int, right_count int, adjacency []u16,
	mut match_left []int, mut match_right []int) int {
	for right in 0 .. side { match_right[right] = -1 }
	mut size := 0
	for left in 0 .. left_count {
		mut seen := []bool{len: side}
		if dm_augment(left, right_count, adjacency, mut seen, mut match_right) { size++ }
	}
	for left in 0 .. side { match_left[left] = -1 }
	for right in 0 .. right_count {
		if match_right[right] >= 0 { match_left[match_right[right]] = right }
	}
	return size
}

@[export: 'dulmage_mendelsohn_decomposition']
pub fn dulmage_mendelsohn_decomposition(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_parseable_length { return -1 }
		left_value, right_value, edge_value := input[0], input[1], input[2]
		if left_value < 0 || left_value > side || right_value < 0 || right_value > side ||
			left_value + right_value < 1 || edge_value < 0 || edge_value > max_edges ||
			edge_value > left_value*right_value { return -1 }
		left_count, right_count, edge_count := int(left_value), int(right_value), int(edge_value)
		total := left_count + right_count
		if length != usize(3 + 2*edge_count) { return -1 }
		mut adjacency := []u16{len: side}
		mut global := []u16{len: vertices}
		for edge in 0 .. edge_count {
			u64, v64 := input[3+2*edge], input[4+2*edge]
			if u64 < 0 || u64 >= left_value || v64 < 0 || v64 >= right_value { return -1 }
			u, v := int(u64), int(v64)
			right_vertex := left_count + v
			bit := u16(1) << u16(v)
			if adjacency[u] & bit != 0 { return -1 }
			adjacency[u] |= bit
			global[u] |= u16(1) << u16(right_vertex)
			global[right_vertex] |= u16(1) << u16(u)
		}
		mut match_left := []int{len: side, init: -1}
		mut match_right := []int{len: side, init: -1}
		matching_size := dm_matching(left_count, right_count, adjacency, mut match_left, mut match_right)
		mut seen := []bool{len: 2*vertices}
		mut queue := []int{cap: 2*vertices}
		for left in 0 .. left_count {
			if match_left[left] < 0 { state := 2*left; seen[state] = true; queue << state }
		}
		for right in 0 .. right_count {
			if match_right[right] < 0 { state := 2*(left_count+right); seen[state] = true; queue << state }
		}
		mut head := 0
		for head < queue.len {
			state := queue[head]
			head++
			vertex, parity := state/2, state%2
			for neighbor in 0 .. total {
				if global[vertex] & (u16(1) << u16(neighbor)) == 0 { continue }
				matched := if vertex < left_count { match_left[vertex] == neighbor-left_count } else { match_right[vertex-left_count] == neighbor }
				if (parity == 0 && matched) || (parity == 1 && !matched) { continue }
				next_state := 2*neighbor + 1 - parity
				if !seen[next_state] { seen[next_state] = true; queue << next_state }
			}
		}
		mut packed := u64(matching_size) << 32
		for vertex in 0 .. total {
			mut code := 2
			if seen[2*vertex] { code = 0 } else if seen[2*vertex+1] { code = 1 }
			packed |= u64(code) << u64(2*vertex)
		}
		return i64(packed)
	}
}
