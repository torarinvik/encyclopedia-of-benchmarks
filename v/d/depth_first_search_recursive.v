module depth_first_search_recursive

const max_vertices = 64
const max_edges = 256
const max_input_length = 518

fn reachable(adjacency &int, degree &int, current int, target i64, mut visited &bool) bool {
	unsafe {
		if i64(current) == target { return true }
		visited[current] = true
		for position in 0 .. degree[current] {
			neighbor := adjacency[current * max_vertices + position]
			if !visited[neighbor] && reachable(adjacency, degree, neighbor, target, mut visited) { return true }
		}
		return false
	}
}

@[export: 'depth_first_search_recursive']
pub fn depth_first_search_recursive(input &i64, length usize) i64 {
	unsafe {
		if isnil(input) || length < 4 || length > max_input_length { return -1 }
		vertex_count := input[0]
		edge_count_value := input[1]
		source := input[2]
		target := input[3]
		if vertex_count < 1 || vertex_count > max_vertices || edge_count_value < 0
			|| edge_count_value > max_edges || source < 0 || source >= vertex_count { return -1 }
		edge_count := int(edge_count_value)
		if length != usize(4 + 2 * edge_count) { return -1 }
		for edge in 0 .. edge_count {
			left := input[4 + 2 * edge]
			right := input[5 + 2 * edge]
			if left < 0 || left >= vertex_count || right < 0 || right >= vertex_count { return -1 }
		}
		mut adjacency := [max_vertices * max_vertices]int{}
		mut degree := [max_vertices]int{}
		mut seen := [max_vertices]u64{}
		for edge in 0 .. edge_count {
			left := int(input[4 + 2 * edge])
			right := int(input[5 + 2 * edge])
			right_bit := u64(1) << u64(right)
			if seen[left] & right_bit == 0 {
				seen[left] |= right_bit
				adjacency[left * max_vertices + degree[left]] = right
				degree[left]++
			}
			left_bit := u64(1) << u64(left)
			if seen[right] & left_bit == 0 {
				seen[right] |= left_bit
				adjacency[right * max_vertices + degree[right]] = left
				degree[right]++
			}
		}
		mut visited := [max_vertices]bool{}
		if reachable(mut adjacency[0], mut degree[0], int(source), target, mut visited[0]) { return 1 }
		return 0
	}
}
