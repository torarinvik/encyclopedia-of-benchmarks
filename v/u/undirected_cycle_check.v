module undirected_cycle_check

// Detect cycles in a bounded simple undirected graph with iterative DFS.
@[export: 'undirected_cycle_check']
pub fn undirected_cycle_check(input &i64, length usize) i64 {
	if length < 2 || unsafe { input == nil } { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > 32 || input[1] < 0 || input[1] > 256 { return -1 }
		vertices := int(input[0])
		edges := int(input[1])
		if int(length) != 2 + 2 * edges { return -1 }
		mut adjacency := [1024]bool{}
		for edge in 0 .. edges {
			left := input[2 + 2 * edge]
			right := input[3 + 2 * edge]
			if left < 0 || left >= i64(vertices) || right < 0 || right >= i64(vertices) { return -1 }
			forward := int(left) * 32 + int(right)
			reverse := int(right) * 32 + int(left)
			if adjacency[forward] { return -1 }
			adjacency[forward] = true
			adjacency[reverse] = true
		}
		mut visited := [32]bool{}
		mut stack_vertex := [32]int{}
		mut stack_parent := [32]int{}
		for start in 0 .. vertices {
			if visited[start] { continue }
			mut top := 1
			stack_vertex[0] = start
			stack_parent[0] = 32
			visited[start] = true
			for top > 0 {
				top--
				current := stack_vertex[top]
				parent := stack_parent[top]
				for neighbor in 0 .. vertices {
					if !adjacency[current * 32 + neighbor] || neighbor == parent { continue }
					if visited[neighbor] { return 1 }
					visited[neighbor] = true
					stack_vertex[top] = neighbor
					stack_parent[top] = current
					top++
				}
			}
		}
		return 0
	}
}
