module minimum_spanning_tree_kruskal

const max_vertices = 64
const max_edges = 4096
const max_input_length = 2 + 3 * max_edges

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'minimum_spanning_tree_kruskal']
pub fn minimum_spanning_tree_kruskal(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(max_input_length) { return -1 }
		raw_vertices := input[0]
		raw_edges := input[1]
		if raw_vertices < 0 || raw_vertices > max_vertices || raw_edges < 0 || raw_edges > max_edges {
			return -1
		}
		vertex_count := int(raw_vertices)
		edge_count := int(raw_edges)
		if length != usize(2 + 3 * edge_count) { return -1 }

		mut order := [max_edges]int{init: 0}
		for index := 0; index < edge_count; index++ {
			offset := 2 + 3 * index
			u := input[offset]
			v := input[offset + 1]
			if u < 0 || u >= raw_vertices || v < 0 || v >= raw_vertices { return -1 }
			order[index] = index
		}

		mut start := edge_count / 2
		for start > 0 {
			start--
			mut root := start
			for root * 2 + 1 < edge_count {
				mut child := root * 2 + 1
				if child + 1 < edge_count {
					left_child := order[child]
					right_child := order[child + 1]
					left_weight := input[2 + 3 * left_child + 2]
					right_weight := input[2 + 3 * right_child + 2]
					if left_weight < right_weight || (left_weight == right_weight && left_child < right_child) {
						child++
					}
				}
				root_index := order[root]
				child_index := order[child]
				root_weight := input[2 + 3 * root_index + 2]
				child_weight := input[2 + 3 * child_index + 2]
				if root_weight < child_weight || (root_weight == child_weight && root_index < child_index) {
					temporary := order[root]
					order[root] = order[child]
					order[child] = temporary
					root = child
				} else {
					break
				}
			}
		}
		mut ending := edge_count
		for ending > 1 {
			ending--
			temporary := order[0]
			order[0] = order[ending]
			order[ending] = temporary
			mut root := 0
			for root * 2 + 1 < ending {
				mut child := root * 2 + 1
				if child + 1 < ending {
					left_child := order[child]
					right_child := order[child + 1]
					left_weight := input[2 + 3 * left_child + 2]
					right_weight := input[2 + 3 * right_child + 2]
					if left_weight < right_weight || (left_weight == right_weight && left_child < right_child) {
						child++
					}
				}
				root_index := order[root]
				child_index := order[child]
				root_weight := input[2 + 3 * root_index + 2]
				child_weight := input[2 + 3 * child_index + 2]
				if root_weight < child_weight || (root_weight == child_weight && root_index < child_index) {
					temporary = order[root]
					order[root] = order[child]
					order[child] = temporary
					root = child
				} else {
					break
				}
			}
		}

		mut parent := [max_vertices]int{init: 0}
		for vertex := 0; vertex < vertex_count; vertex++ { parent[vertex] = vertex }
		mut accepted := [max_vertices]int{init: 0}
		mut accepted_count := 0
		for index := 0; index < edge_count; index++ {
			edge_index := order[index]
			offset := 2 + 3 * edge_index
			mut left_root := int(input[offset])
			for parent[left_root] != left_root {
				parent[left_root] = parent[parent[left_root]]
				left_root = parent[left_root]
			}
			mut right_root := int(input[offset + 1])
			for parent[right_root] != right_root {
				parent[right_root] = parent[parent[right_root]]
				right_root = parent[right_root]
			}
			if left_root != right_root {
				accepted[accepted_count] = edge_index
				accepted_count++
				parent[left_root] = right_root
			}
		}

		byte_count := accepted_count * 24
		if output == nil || capacity < usize(byte_count) { return -2 }
		for index := 0; index < accepted_count; index++ {
			input_offset := 2 + 3 * accepted[index]
			output_offset := index * 24
			put_i64_le(mut output, output_offset, input[input_offset])
			put_i64_le(mut output, output_offset + 8, input[input_offset + 1])
			put_i64_le(mut output, output_offset + 16, input[input_offset + 2])
		}
		return i64(byte_count)
	}
}
