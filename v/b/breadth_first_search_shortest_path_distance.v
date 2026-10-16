module breadth_first_search_shortest_path_distance

const max_vertices = 26
const max_edges = 256

@[export: 'breadth_first_search_shortest_path_distance']
pub fn breadth_first_search_shortest_path_distance(input &i64, length usize) i64 {
	unsafe {
		if isnil(input) || length < 4 { return -1 }
		vertices_value := input[0]
		edges_value := input[1]
		source_value := input[2]
		target_value := input[3]
		if vertices_value < 1 || vertices_value > max_vertices || edges_value < 0 || edges_value > max_edges { return -1 }
		vertices := int(vertices_value)
		edges := int(edges_value)
		if source_value < 0 || source_value >= vertices_value || target_value < 0 || target_value >= vertices_value ||
			length != usize(4 + 2 * edges) { return -1 }

		mut adjacent := [max_vertices * max_vertices]bool{}
		for edge in 0 .. edges {
			from_value := input[4 + 2 * edge]
			to_value := input[5 + 2 * edge]
			if from_value < 0 || from_value >= vertices_value || to_value < 0 || to_value >= vertices_value { return -1 }
			adjacent[int(from_value) * vertices + int(to_value)] = true
		}

		source := int(source_value)
		target := int(target_value)
		mut distance := [max_vertices]i64{init: -1}
		mut queue := [max_vertices]int{}
		mut head := 0
		mut tail := 1
		distance[source] = 0
		queue[0] = source
		for head < tail {
			current := queue[head]
			head++
			for next in 0 .. vertices {
				if adjacent[current * vertices + next] && distance[next] < 0 {
					distance[next] = distance[current] + 1
					queue[tail] = next
					tail++
				}
			}
		}
		return distance[target]
	}
}
