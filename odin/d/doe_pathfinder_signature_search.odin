package doe_pathfinder_signature_search

import "core:c"

MAX_NODES :: 10
MAX_EDGES :: 100
MAX_SIGNATURE_LENGTH :: 4
MAX_LABEL :: 7

search_leg :: proc(values: [^]i64, edge_count, labels_start, signature_start,
		signature_length, node, signature_index: int, visited: ^u16) -> bool {
	bit := u16(1) << u16(node)
	if (visited^ & bit) != 0 { return false }
	visited^ |= bit
	target_label := values[signature_start + signature_index]

	for edge := 0; edge < edge_count; edge += 1 {
		if int(values[3 + 2 * edge]) != node { continue }
		target := int(values[4 + 2 * edge])
		if values[labels_start + target] != target_label { continue }
		if signature_index + 1 == signature_length { return true }
		next_visited := u16(0)
		if search_leg(values, edge_count, labels_start, signature_start, signature_length,
				target, signature_index + 1, &next_visited) { return true }
	}

	for edge := 0; edge < edge_count; edge += 1 {
		if int(values[3 + 2 * edge]) != node { continue }
		target := int(values[4 + 2 * edge])
		if search_leg(values, edge_count, labels_start, signature_start, signature_length,
				target, signature_index, visited) { return true }
	}
	return false
}

@(export)
doe_pathfinder_signature_search :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 3 || values[0] < 1 || values[0] > MAX_NODES ||
			values[1] < 0 || values[1] > MAX_EDGES || values[2] < 2 ||
			values[2] > MAX_SIGNATURE_LENGTH { return -2 }
	node_count := int(values[0])
	edge_count := int(values[1])
	signature_length := int(values[2])
	if edge_count > node_count * node_count || int(length) != 3 + 2 * edge_count + node_count + signature_length {
		return -2
	}
	for edge := 0; edge < edge_count; edge += 1 {
		from := values[3 + 2 * edge]
		to := values[4 + 2 * edge]
		if from < 0 || from >= i64(node_count) || to < 0 || to >= i64(node_count) { return -2 }
		for previous := 0; previous < edge; previous += 1 {
			if values[3 + 2 * previous] == from && values[4 + 2 * previous] == to { return -2 }
		}
	}
	labels_start := 3 + 2 * edge_count
	signature_start := labels_start + node_count
	for node := 0; node < node_count; node += 1 {
		if values[labels_start + node] < -1 || values[labels_start + node] > MAX_LABEL { return -2 }
	}
	for index := 0; index < signature_length; index += 1 {
		if values[signature_start + index] < 0 || values[signature_start + index] > MAX_LABEL { return -2 }
	}
	first_label := values[signature_start]
	for node := 0; node < node_count; node += 1 {
		if values[labels_start + node] == first_label {
			visited := u16(0)
			if search_leg(values, edge_count, labels_start, signature_start, signature_length,
					node, 1, &visited) { return 1 }
		}
	}
	return 0
}
