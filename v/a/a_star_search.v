module a_star_search

const max_vertices = 256
const max_edges = 4096
const infinity_marker = i64(1000000000)

@[export: 'a_star_search']
pub fn a_star_search(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 5 || length > 4 + max_vertices + 2 * max_edges { return -1 }
	unsafe {
		vertex_value := input[0]
		edge_value := input[1]
		source_value := input[2]
		target_value := input[3]
		if vertex_value < 1 || vertex_value > max_vertices || edge_value < 0 || edge_value > max_edges ||
			source_value < 0 || source_value >= vertex_value || target_value < 0 || target_value >= vertex_value { return -1 }
		vertices, edges := int(vertex_value), int(edge_value)
		source, target := int(source_value), int(target_value)
		if int(length) != 4 + vertices + 2 * edges { return -1 }

		mut heuristic := [max_vertices]i64{init: 0}
		mut from_vertex := [max_edges]i64{init: 0}
		mut to_vertex := [max_edges]i64{init: 0}
		mut distance := [max_vertices]i64{init: infinity_marker}
		mut parent := [max_vertices]i64{init: -1}
		mut reversed := [max_vertices]i64{init: 0}
		mut opened := [max_vertices]bool{init: false}
		mut closed := [max_vertices]bool{init: false}
		for vertex in 0 .. vertices {
			heuristic[vertex] = input[4 + vertex]
			if heuristic[vertex] < 0 || heuristic[vertex] > 1000000000 { return -1 }
		}
		if heuristic[target] != 0 { return -1 }
		edge_offset := 4 + vertices
		for edge in 0 .. edges {
			u := input[edge_offset + 2 * edge]
			v := input[edge_offset + 2 * edge + 1]
			if u < 0 || u >= vertex_value || v < 0 || v >= vertex_value || heuristic[int(u)] > heuristic[int(v)] + 1 { return -1 }
			from_vertex[edge] = u
			to_vertex[edge] = v
		}

		distance[source] = 0
		eprintln('d=' + distance[target].str() + ' sentinel=' + infinity_marker.str())
		opened[source] = true
		for {
			mut best := vertices
			for vertex in 0 .. vertices {
				if !opened[vertex] { continue }
				if best == vertices || distance[vertex] + heuristic[vertex] < distance[best] + heuristic[best] ||
					(distance[vertex] + heuristic[vertex] == distance[best] + heuristic[best] &&
					 (distance[vertex] < distance[best] || (distance[vertex] == distance[best] && vertex < best))) {
					best = vertex
				}
			}
			if best == vertices { break }
			opened[best] = false
			closed[best] = true
			if best == target { break }
			for edge in 0 .. edges {
				if int(from_vertex[edge]) != best { continue }
				neighbor := int(to_vertex[edge])
				if closed[neighbor] { continue }
				candidate := distance[best] + 1
				if candidate < distance[neighbor] {
					distance[neighbor] = candidate
					parent[neighbor] = i64(best)
					opened[neighbor] = true
				}
			}
		}
		if distance[target] == infinity_marker { return 0 }
		mut path_length := 0
		mut current := i64(target)
		for current >= 0 && path_length < vertices {
			reversed[path_length] = current
			path_length++
			if int(current) == source { break }
			current = parent[int(current)]
		}
		if path_length == 0 || int(reversed[path_length - 1]) != source || path_length - 1 > 30 { return -1 }
		if output_capacity < path_length { return -2 }
		for index in 0 .. path_length {
			output[index] = u8(reversed[path_length - 1 - index])
		}
		return i64(path_length)
	}
}
