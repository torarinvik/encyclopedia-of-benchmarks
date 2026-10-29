module k_shortest_walk

const max_vertices = 6
const max_edges = 12
const max_k = 8
const max_input_length = 41
const max_frontier = 97

fn write_i64(output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 0xff) }
	}
}

@[export: 'k_shortest_walk']
pub fn k_shortest_walk(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if input == nil || length < 5 || length > max_input_length { return -1 }
	n_value := unsafe { input[0] }
	m_value := unsafe { input[1] }
	source_value := unsafe { input[2] }
	target_value := unsafe { input[3] }
	k_value := unsafe { input[4] }
	if n_value < 1 || n_value > max_vertices || m_value < 0 || m_value > max_edges ||
		k_value < 1 || k_value > max_k || source_value < 0 || source_value >= n_value ||
		target_value < 0 || target_value >= n_value { return -1 }
	n := int(n_value)
	m := int(m_value)
	source := int(source_value)
	target := int(target_value)
	k := int(k_value)
	if length != usize(5 + 3*m) { return -1 }

	mut head := [6]i64{}
	for vertex in 0 .. n { head[vertex] = -1 }
	mut edge_to := [12]i64{}
	mut edge_weight := [12]i64{}
	mut edge_next := [12]i64{}
	for edge in 0 .. m {
		u := unsafe { input[5+3*edge] }
		v := unsafe { input[6+3*edge] }
		weight := unsafe { input[7+3*edge] }
		if u < 0 || u >= n_value || v < 0 || v >= n_value || weight < 0 || weight > 1000 { return -1 }
		edge_to[edge] = v
		edge_weight[edge] = weight
		edge_next[edge] = head[int(u)]
		head[int(u)] = i64(edge)
	}
	if output == nil || output_capacity < usize(8*k) { return -2 }

	mut queue_distance := [97]i64{}
	mut queue_vertex := [97]i64{}
	mut queue_order := [97]i64{}
	mut expanded := [6]i64{}
	mut answers := [8]i64{}
	mut queue_count := 1
	mut answer_count := 0
	mut next_order := i64(1)
	queue_distance[0] = 0
	queue_vertex[0] = i64(source)
	queue_order[0] = 0

	for queue_count > 0 && answer_count < k {
		distance := queue_distance[0]
		vertex := int(queue_vertex[0])
		for slot in 1 .. queue_count {
			queue_distance[slot-1] = queue_distance[slot]
			queue_vertex[slot-1] = queue_vertex[slot]
			queue_order[slot-1] = queue_order[slot]
		}
		queue_count--
		if expanded[vertex] >= i64(k) { continue }
		expanded[vertex]++
		if vertex == target {
			answers[answer_count] = distance
			answer_count++
			if answer_count == k { break }
		}
		mut edge := head[vertex]
		for edge >= 0 {
			edge_index := int(edge)
			candidate_distance := distance + edge_weight[edge_index]
			candidate_vertex := edge_to[edge_index]
			candidate_order := next_order
			next_order++
			mut position := queue_count
			for position > 0 && (queue_distance[position-1] > candidate_distance ||
				(queue_distance[position-1] == candidate_distance && queue_order[position-1] > candidate_order)) {
				queue_distance[position] = queue_distance[position-1]
				queue_vertex[position] = queue_vertex[position-1]
				queue_order[position] = queue_order[position-1]
				position--
			}
			queue_distance[position] = candidate_distance
			queue_vertex[position] = candidate_vertex
			queue_order[position] = candidate_order
			queue_count++
			edge = edge_next[edge_index]
		}
	}
	for answer_count < k {
		answers[answer_count] = -1
		answer_count++
	}
	for index in 0 .. k { write_i64(output, 8*index, answers[index]) }
	return i64(8*k)
}
