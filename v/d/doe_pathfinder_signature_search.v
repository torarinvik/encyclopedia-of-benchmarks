module doe_pathfinder_signature_search

const max_nodes = 10
const max_edges = 100
const max_signature_length = 4
const max_label = 7

fn search_leg(values &i64, edge_count int, labels_start int, signature_start int,
	signature_length int, node int, signature_index int, mut visited u16) bool {
	bit := u16(1) << u16(node)
	if visited & bit != 0 { return false }
	visited |= bit
	target_label := unsafe { values[signature_start + signature_index] }

	for edge in 0 .. edge_count {
		if int(unsafe { values[3 + 2 * edge] }) != node { continue }
		target := int(unsafe { values[4 + 2 * edge] })
		if unsafe { values[labels_start + target] } != target_label { continue }
		if signature_index + 1 == signature_length { return true }
		mut next_visited := u16(0)
		if search_leg(values, edge_count, labels_start, signature_start, signature_length,
			target, signature_index + 1, mut next_visited) { return true }
	}

	for edge in 0 .. edge_count {
		if int(unsafe { values[3 + 2 * edge] }) != node { continue }
		target := int(unsafe { values[4 + 2 * edge] })
		if search_leg(values, edge_count, labels_start, signature_start, signature_length,
			target, signature_index, mut visited) { return true }
	}
	return false
}

@[export: 'doe_pathfinder_signature_search']
pub fn doe_pathfinder_signature_search(values &i64, length usize) i64 {
	if length < 3 { return -2 }
	node_value := unsafe { values[0] }
	edge_value := unsafe { values[1] }
	signature_value := unsafe { values[2] }
	if node_value < 1 || node_value > max_nodes || edge_value < 0 || edge_value > max_edges ||
		signature_value < 2 || signature_value > max_signature_length { return -2 }
	node_count := int(node_value)
	edge_count := int(edge_value)
	signature_length := int(signature_value)
	if edge_count > node_count * node_count || length != usize(3 + 2 * edge_count + node_count + signature_length) {
		return -2
	}
	for edge in 0 .. edge_count {
		from := unsafe { values[3 + 2 * edge] }
		to := unsafe { values[4 + 2 * edge] }
		if from < 0 || from >= i64(node_count) || to < 0 || to >= i64(node_count) { return -2 }
		for previous in 0 .. edge {
			if unsafe { values[3 + 2 * previous] } == from && unsafe { values[4 + 2 * previous] } == to {
				return -2
			}
		}
	}
	labels_start := 3 + 2 * edge_count
	signature_start := labels_start + node_count
	for node in 0 .. node_count {
		label := unsafe { values[labels_start + node] }
		if label < -1 || label > max_label { return -2 }
	}
	for index in 0 .. signature_length {
		label := unsafe { values[signature_start + index] }
		if label < 0 || label > max_label { return -2 }
	}
	first_label := unsafe { values[signature_start] }
	for node in 0 .. node_count {
		if unsafe { values[labels_start + node] } == first_label {
			mut visited := u16(0)
			if search_leg(values, edge_count, labels_start, signature_start, signature_length,
				node, 1, mut visited) { return 1 }
		}
	}
	return 0
}
