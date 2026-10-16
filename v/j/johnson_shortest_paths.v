module johnson_shortest_paths

const max_vertices = 32
const max_edges = 256
const max_input_length = 770
const max_queue = max_edges + 1
const unreachable = i64(0x7fffffffffffffff)
const unreachable_sentinel = i64(0x4000000000000000)
const fnv_offset_basis = u64(0xcbf29ce484222325)
const fnv_prime = u64(0x100000001b3)

fn fnv_word(hash u64, value i64) u64 {
	bits := u64(value)
	mut result := hash
	for byte in 0 .. 8 {
		result = (result ^ ((bits >> (8 * byte)) & u64(255))) * fnv_prime
	}
	return result
}

@[export: 'johnson_shortest_paths']
pub fn johnson_shortest_paths(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_length { return -1 }
	unsafe {
		vertex_value, edge_value := input[0], input[1]
		if vertex_value < 1 || vertex_value > i64(max_vertices) || edge_value < 0 || edge_value > i64(max_edges) { return -1 }
		vertices, edges := int(vertex_value), int(edge_value)
		if length != usize(2 + 3 * edges) { return -1 }

		mut edge_from := [max_edges]int{}
		mut edge_to := [max_edges]int{}
		mut edge_weight := [max_edges]i64{}
		for edge in 0 .. edges {
			from, to, weight := input[2 + 3 * edge], input[3 + 3 * edge], input[4 + 3 * edge]
			if from < 1 || from > vertex_value || to < 1 || to > vertex_value || weight < -32 || weight > 32 { return -1 }
			edge_from[edge], edge_to[edge], edge_weight[edge] = int(from - 1), int(to - 1), weight
		}

		mut potential := [max_vertices]i64{}
		for _ in 1 .. vertices {
			mut updated := false
			for edge in 0 .. edges {
				from, to := edge_from[edge], edge_to[edge]
				candidate := potential[from] + edge_weight[edge]
				if candidate < potential[to] { potential[to] = candidate; updated = true }
			}
			if !updated { break }
		}
		for edge in 0 .. edges {
			if potential[edge_from[edge]] + edge_weight[edge] < potential[edge_to[edge]] { return -1 }
		}

		mut result := fnv_offset_basis
		for source in 0 .. vertices {
			mut distance := [max_vertices]i64{}
			mut visited := [max_vertices]bool{}
			for vertex in 0 .. vertices { distance[vertex] = unreachable }
			distance[source] = 0
			mut queue_vertices := [max_queue]int{}
			mut queue_distances := [max_queue]i64{}
			mut queue_length := 1
			queue_vertices[0], queue_distances[0] = source, 0
			for queue_length > 0 {
				mut minimum := 0
				for index in 1 .. queue_length {
					if queue_distances[index] < queue_distances[minimum] { minimum = index }
				}
				current := queue_vertices[minimum]
				for index in (minimum + 1) .. queue_length {
					queue_vertices[index - 1], queue_distances[index - 1] = queue_vertices[index], queue_distances[index]
				}
				queue_length--
				if visited[current] { continue }
				visited[current] = true

				for edge in 0 .. edges {
					if edge_from[edge] != current { continue }
					next := edge_to[edge]
					reweighted := edge_weight[edge] + potential[current] - potential[next]
					candidate := distance[current] + reweighted
					if !visited[next] && candidate < distance[next] {
						distance[next] = candidate
						queue_vertices[queue_length], queue_distances[queue_length] = next, candidate
						queue_length++
					}
				}
			}

			for destination in 0 .. vertices {
				output := unreachable_sentinel
				if distance[destination] != unreachable {
					output = distance[destination] - potential[source] + potential[destination]
				}
				result = fnv_word(result, output)
			}
		}
		return i64(result & 0x7fffffffffffffff)
	}
}
