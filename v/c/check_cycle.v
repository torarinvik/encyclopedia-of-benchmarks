module check_cycle

// Detect directed cycles with iterative three-color depth-first search.
@[export: 'check_cycle']
pub fn check_cycle(input &i64, length usize) i64 {
	if length < 2 || unsafe { input == nil } { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > 32 || input[1] < 0 || input[1] > 256 { return -1 }
		vertices := int(input[0])
		edges := int(input[1])
		if int(length) != 2 + 2 * edges { return -1 }
		mut adjacency := [1024]bool{}
		for edge in 0 .. edges {
			origin := input[2 + 2 * edge]
			destination := input[3 + 2 * edge]
			if origin < 0 || origin >= i64(vertices) || destination < 0 || destination >= i64(vertices) { return -1 }
			adjacency[int(origin) * 32 + int(destination)] = true
		}
		mut color := [32]u8{}
		mut stack := [32]int{}
		mut next_neighbor := [32]int{}
		for start in 0 .. vertices {
			if color[start] != 0 { continue }
			mut top := 1
			stack[0] = start
			next_neighbor[0] = 0
			color[start] = 1
			for top > 0 {
				frame := top - 1
				current := stack[frame]
				for next_neighbor[frame] < vertices && !adjacency[current * 32 + next_neighbor[frame]] { next_neighbor[frame]++ }
				if next_neighbor[frame] == vertices {
					color[current] = 2
					top--
					continue
				}
				neighbor := next_neighbor[frame]
				next_neighbor[frame]++
				if color[neighbor] == 1 { return 1 }
				if color[neighbor] == 0 {
					color[neighbor] = 1
					stack[top] = neighbor
					next_neighbor[top] = 0
					top++
				}
			}
		}
		return 0
	}
}
