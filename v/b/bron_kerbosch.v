module bron_kerbosch

fn population_count(value u64) int {
	mut bits := value
	mut count := 0
	for bits != 0 {
		count += int(bits & 1)
		bits >>= 1
	}
	return count
}

fn search(vertex_count int, adjacency [5]u64, clique u64, possible u64, excluded u64) u64 {
	if possible == 0 && excluded == 0 { return u64(1) << clique }

	mut pivot := -1
	mut greatest_degree := -1
	pivot_choices := possible | excluded
	for vertex in 0 .. vertex_count {
		if pivot_choices & (u64(1) << u64(vertex)) == 0 { continue }
		degree := population_count(adjacency[vertex])
		if degree > greatest_degree {
			pivot = vertex
			greatest_degree = degree
		}
	}

	mut candidates := possible
	if pivot >= 0 { candidates &= ~adjacency[pivot] }
	mut result := u64(0)
	mut remaining_possible := possible
	mut remaining_excluded := excluded
	for vertex in 0 .. vertex_count {
		bit := u64(1) << u64(vertex)
		if candidates & bit == 0 { continue }
		result |= search(vertex_count, adjacency, clique | bit,
			remaining_possible & adjacency[vertex], remaining_excluded & adjacency[vertex])
		remaining_possible &= ~bit
		remaining_excluded |= bit
	}
	return result
}

@[export: 'bron_kerbosch']
pub fn bron_kerbosch(input &i64, length usize) i64 {
	unsafe {
		if length < 1 || length > 7 { return -1 }
		if input[0] < 0 || input[0] > 5 { return -1 }
		vertex_count := int(input[0])
		if length != usize(vertex_count + 1) { return -1 }

		vertex_mask := (u64(1) << u64(vertex_count)) - 1
		mut adjacency := [5]u64{}
		for vertex in 0 .. vertex_count {
			row := input[vertex + 1]
			if row < 0 || u64(row) & ~vertex_mask != 0 { return -1 }
			adjacency[vertex] = u64(row) & ~(u64(1) << u64(vertex))
		}
		for left in 0 .. vertex_count {
			for right in left + 1 .. vertex_count {
				if (adjacency[left] >> u64(right)) & 1 != (adjacency[right] >> u64(left)) & 1 { return -1 }
			}
		}
		return i64(search(vertex_count, adjacency, 0, vertex_mask, 0))
	}
}
