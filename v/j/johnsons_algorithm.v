module johnsons_algorithm

const max_vertices = 16
const max_input_length = 1 + max_vertices * max_vertices
const max_weight = i64(32)
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

@[export: 'johnsons_algorithm']
pub fn johnsons_algorithm(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_length { return -1 }
	unsafe {
		vertex_value := input[0]
		if vertex_value < 1 || vertex_value > i64(max_vertices) { return -1 }
		vertices := int(vertex_value)
		if length != usize(1 + vertices * vertices) { return -1 }

		mut weight := [max_vertices * max_vertices]i64{}
		mut edge := [max_vertices * max_vertices]bool{}
		mut reachable := [max_vertices * max_vertices]bool{}
		for from in 0 .. vertices {
			reachable[from * max_vertices + from] = true
			for to in 0 .. vertices {
				value := input[1 + from * vertices + to]
				if value < -max_weight || value > max_weight { return -1 }
				if from != to && value != 0 {
					index := from * max_vertices + to
					edge[index] = true
					weight[index] = value
					reachable[index] = true
				}
			}
		}
		for intermediate in 0 .. vertices {
			for from in 0 .. vertices {
				for to in 0 .. vertices {
					index := from * max_vertices + to
					reachable[index] = reachable[index] ||
						(reachable[from * max_vertices + intermediate] && reachable[intermediate * max_vertices + to])
				}
			}
		}
		for from in 0 .. vertices {
			for to in 0 .. vertices {
				if !reachable[from * max_vertices + to] { return -1 }
			}
		}

		mut potential := [max_vertices]i64{}
		for _ in 1 .. vertices {
			mut updated := false
			for from in 0 .. vertices {
				for to in 0 .. vertices {
					index := from * max_vertices + to
					if !edge[index] { continue }
					candidate := potential[from] + weight[index]
					if candidate < potential[to] {
						potential[to] = candidate
						updated = true
					}
				}
			}
			if !updated { break }
		}
		for from in 0 .. vertices {
			for to in 0 .. vertices {
				index := from * max_vertices + to
				if !edge[index] { continue }
				if potential[from] + weight[index] < potential[to] ||
					weight[index] + potential[from] - potential[to] <= 0 { return -1 }
			}
		}

		mut reweighted := [max_vertices * max_vertices]i64{}
		for from in 0 .. vertices {
			for to in 0 .. vertices {
				index := from * max_vertices + to
				if edge[index] { reweighted[index] = weight[index] + potential[from] - potential[to] }
			}
		}

		mut result := fnv_offset_basis
		for source in 0 .. vertices {
			mut distance := [max_vertices]i64{}
			mut visited := [max_vertices]bool{}
			for vertex in 0 .. vertices { distance[vertex] = unreachable }
			distance[source] = 0
			for _ in 0 .. vertices {
				mut current := vertices
				for vertex in 0 .. vertices {
					if !visited[vertex] && (current == vertices || distance[vertex] <= distance[current]) { current = vertex }
				}
				if current == vertices || distance[current] == unreachable { break }
				visited[current] = true
				for next in 0 .. vertices {
					index := current * max_vertices + next
					if !edge[index] || visited[next] { continue }
					candidate := distance[current] + reweighted[index]
					if candidate < distance[next] { distance[next] = candidate }
				}
			}
			for destination in 0 .. vertices {
				mut output := unreachable_sentinel
				if distance[destination] != unreachable {
					output = distance[destination] - potential[source] + potential[destination]
				}
				result = fnv_word(result, output)
			}
		}
		return i64(result & u64(0x7fffffffffffffff))
	}
}
