module network_erosion_strength_of_connection

const max_vertices = 8
const max_parseable_input = 117
const output_bytes = 16

fn soc_shortest_path(adjacency [8]i64, n int, source int, target int) [9]int {
	mut result := [9]int{}
	mut distance := [8]int{}
	mut predecessor := [8]int{}
	mut queue := [8]int{}
	for vertex in 0 .. n {
		distance[vertex] = -1
		predecessor[vertex] = -1
	}
	mut head := 0
	mut tail := 1
	queue[0] = source
	distance[source] = 0
	for head < tail {
		vertex := queue[head]
		head++
		for successor in 0 .. n {
			bit := i64(1) << successor
			if adjacency[vertex] & bit != 0 && distance[successor] == -1 {
				distance[successor] = distance[vertex] + 1
				predecessor[successor] = vertex
				queue[tail] = successor
				tail++
			}
		}
	}
	if distance[target] == -1 { return result }
	mut reversed := [8]int{}
	mut count := 0
	mut vertex := target
	for {
		reversed[count] = vertex
		count++
		if vertex == source { break }
		vertex = predecessor[vertex]
		if vertex < 0 { return result }
	}
	result[0] = count
	for index in 0 .. count { result[index + 1] = reversed[count - index - 1] }
	return result
}

fn soc_gcd(left_value i64, right_value i64) i64 {
	mut left := left_value
	mut right := right_value
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

fn soc_write_i64(output &u8, word int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[word * 8 + byte] = u8(bits >> (byte * 8)) }
	}
}

@[export: 'network_erosion_strength_of_connection']
pub fn network_erosion_strength_of_connection(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_parseable_input { return -1 }
		vertex_raw, edge_raw := input[0], input[1]
		source_raw, target_raw := input[2], input[3]
		if vertex_raw < 2 || vertex_raw > max_vertices || edge_raw < 0 || edge_raw > vertex_raw * (vertex_raw - 1) ||
			source_raw < 0 || source_raw >= vertex_raw || target_raw < 0 || target_raw >= vertex_raw || source_raw == target_raw {
			return -1
		}
		n, edge_count := int(vertex_raw), int(edge_raw)
		source, target := int(source_raw), int(target_raw)
		if length != usize(4 + 2 * edge_count) { return -1 }
		mut adjacency := [8]i64{}
		mut cursor := 4
		for _ in 0 .. edge_count {
			from_raw, to_raw := input[cursor], input[cursor + 1]
			cursor += 2
			if from_raw < 0 || from_raw >= vertex_raw || to_raw < 0 || to_raw >= vertex_raw || from_raw == to_raw {
				return -1
			}
			from, to := int(from_raw), int(to_raw)
			bit := i64(1) << to
			if adjacency[from] & bit != 0 { return -1 }
			adjacency[from] |= bit
		}

		mut distances := [8]int{}
		for vertex in 0 .. n { distances[vertex] = -1 }
		mut first := soc_shortest_path(adjacency, n, source, target)
		if first[0] != 0 {
			initial_length := first[0] - 1
			distances[source], distances[target] = initial_length, initial_length
			for {
				current := soc_shortest_path(adjacency, n, source, target)
				path_count := current[0]
				if path_count == 0 { break }
				path_length := path_count - 1
				if path_length == 1 {
					adjacency[source] &= ~(i64(1) << target)
					continue
				}
				for index in 0 .. path_count {
					vertex := current[index + 1]
					if distances[vertex] == -1 { distances[vertex] = path_length }
				}
				for index in 1 .. path_count - 1 {
					vertex := current[index + 1]
					bit := i64(1) << vertex
					adjacency[vertex] = 0
					for other in 0 .. n { adjacency[other] &= ~bit }
				}
			}
		}
		mut reciprocal_sum_scaled := i64(0)
		for vertex in 0 .. n {
			if distances[vertex] >= 1 { reciprocal_sum_scaled += 420 / distances[vertex] }
		}
		mut numerator := 2 * reciprocal_sum_scaled
		mut denominator := i64(420 * (n + 2))
		if numerator == 0 { denominator = 1 } else {
			divisor := soc_gcd(numerator, denominator)
			numerator /= divisor
			denominator /= divisor
		}
		if output == nil || capacity < output_bytes { return -2 }
		soc_write_i64(output, 0, numerator)
		soc_write_i64(output, 1, denominator)
		return output_bytes
	}
}
