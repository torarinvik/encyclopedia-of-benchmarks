module bellman_ford_pair

const max_vertices = 64
const max_input_edges = 256
const max_normalized_edges = 128
const max_weight = i64(1000)

fn store_i64(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

fn write_record(mut output &u8, capacity usize, status i64, target_reachable i64, distance i64) i64 {
	if isnil(output) || capacity < 24 { return -2 }
	unsafe {
		store_i64(mut output, 0, status)
		store_i64(mut output, 8, target_reachable)
		store_i64(mut output, 16, distance)
	}
	return 24
}

@[export: 'bellman_ford_pair']
pub fn bellman_ford_pair(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if isnil(input) || length < 4 { return -1 }
		nv := input[0]
		mv := input[1]
		source_value := input[2]
		target_value := input[3]
		if nv < 1 || nv > max_vertices || mv < 0 || mv > max_input_edges { return -1 }
		n := int(nv)
		input_edges := int(mv)
		if source_value < 0 || source_value >= nv || target_value < 0 || target_value >= nv ||
			length != usize(4 + 3 * input_edges) { return -1 }

		mut matrix_weights := []i64{len: max_vertices * max_vertices}
		mut matrix_present := []bool{len: max_vertices * max_vertices}
		mut normalized_count := 0
		for edge in 0 .. input_edges {
			from_value := input[4 + 3 * edge]
			to_value := input[5 + 3 * edge]
			weight_value := input[6 + 3 * edge]
			if from_value < 0 || from_value >= nv || to_value < 0 || to_value >= nv ||
				weight_value < -max_weight || weight_value > max_weight { return -1 }
			key := int(from_value) * n + int(to_value)
			if !matrix_present[key] {
				matrix_present[key] = true
				normalized_count++
				if normalized_count > max_normalized_edges { return -1 }
			}
			matrix_weights[key] = weight_value
		}

		mut from := []int{len: max_normalized_edges}
		mut to := []int{len: max_normalized_edges}
		mut weight := []i64{len: max_normalized_edges}
		mut edge_count := 0
		for origin in 0 .. n {
			for destination in 0 .. n {
				key := origin * n + destination
				if !matrix_present[key] { continue }
				from[edge_count] = origin
				to[edge_count] = destination
				weight[edge_count] = matrix_weights[key]
				edge_count++
			}
		}

		source := int(source_value)
		target := int(target_value)
		mut distance := []i64{len: max_vertices}
		mut reachable := []bool{len: max_vertices}
		reachable[source] = true
		for _ in 0 .. n {
			mut changed := false
			for edge in 0 .. edge_count {
				if !reachable[from[edge]] { continue }
				candidate := distance[from[edge]] + weight[edge]
				if !reachable[to[edge]] || candidate < distance[to[edge]] {
					distance[to[edge]] = candidate
					reachable[to[edge]] = true
					changed = true
				}
			}
			if !changed { break }
		}
		for edge in 0 .. edge_count {
			if reachable[from[edge]] && distance[to[edge]] > distance[from[edge]] + weight[edge] {
				return write_record(mut output, capacity, -1, 0, 0)
			}
		}
		target_reachable := if reachable[target] { i64(1) } else { i64(0) }
		target_distance := if reachable[target] { distance[target] } else { i64(0) }
		return write_record(mut output, capacity, 0, target_reachable, target_distance)
	}
}
