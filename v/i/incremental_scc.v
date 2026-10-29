module incremental_scc

@[export: 'incremental_scc']
pub fn incremental_scc(input &i64, length usize) i64 {
	if length < 2 || length > 66 || unsafe { input == nil } { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > 8 || input[1] < 0 || input[1] > 32 { return -1 }
		vertex_count := int(input[0])
		edge_count := int(input[1])
		if length != usize(2 + 2 * edge_count) { return -1 }
		mut sources := [32]int{}
		mut destinations := [32]int{}
		for edge in 0 .. edge_count {
			source := input[2 + 2 * edge]
			destination := input[3 + 2 * edge]
			if source < 0 || destination < 0 || source >= i64(vertex_count) || destination >= i64(vertex_count) { return -1 }
			sources[edge] = int(source)
			destinations[edge] = int(destination)
		}

		mut reachable := [64]bool{}
		for vertex in 0 .. vertex_count { reachable[vertex * 8 + vertex] = true }
		mut checksum := i64(0)
		for edge in 0 .. edge_count {
			source := sources[edge]
			destination := destinations[edge]
			mut predecessors := [8]bool{}
			mut successors := [8]bool{}
			for vertex in 0 .. vertex_count {
				predecessors[vertex] = reachable[vertex * 8 + source]
				successors[vertex] = reachable[destination * 8 + vertex]
			}
			for first in 0 .. vertex_count {
				for second in 0 .. vertex_count {
					if predecessors[first] && successors[second] { reachable[first * 8 + second] = true }
				}
			}

			mut assigned := [8]bool{}
			mut component_count := 0
			for first in 0 .. vertex_count {
				if assigned[first] { continue }
				component_count++
				for vertex in first .. vertex_count {
					if reachable[first * 8 + vertex] && reachable[vertex * 8 + first] { assigned[vertex] = true }
				}
			}
			checksum += i64(edge + 1) * i64(component_count)
		}
		return checksum
	}
}
