package louvain_multilevel_community_detection

import "core:c"

MAX_VERTICES :: 8
MAX_EDGES :: 28
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(87)

least_vertex :: proc "contextless" (mask: int) -> int {
	for vertex := 0; vertex < MAX_VERTICES; vertex += 1 {
		if (mask & (1 << vertex)) != 0 do return vertex
	}
	return MAX_VERTICES
}

modularity_score :: proc "contextless" (adjacency: ^[MAX_VERTICES * MAX_VERTICES]i64,
		node_count: int, labels: ^[MAX_VERTICES]int) -> i64 {
	var degrees: [MAX_VERTICES]i64
	var community_degrees: [MAX_VERTICES]i64
	total_degree: i64 = 0
	internal_directed_weight: i64 = 0
	for vertex := 0; vertex < node_count; vertex += 1 {
		for other := 0; other < node_count; other += 1 {
			weight := adjacency[vertex * MAX_VERTICES + other]
			degrees[vertex] += weight
			if labels[vertex] == labels[other] do internal_directed_weight += weight
		}
		total_degree += degrees[vertex]
		community_degrees[labels[vertex]] += degrees[vertex]
	}
	squared_degrees: i64 = 0
	for community := 0; community < MAX_VERTICES; community += 1 {
		squared_degrees += community_degrees[community] * community_degrees[community]
	}
	return total_degree * internal_directed_weight - squared_degrees
}

community_key :: proc "contextless" (target, node_count: int,
		labels: ^[MAX_VERTICES]int, masks: ^[MAX_VERTICES]int) -> int {
	key := MAX_VERTICES
	for node := 0; node < node_count; node += 1 {
		if labels[node] == target do key = min(key, least_vertex(masks[node]))
	}
	return key
}

@(export)
louvain_multilevel_community_detection :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	vertex_count_value, edge_count_value := input[0], input[1]
	if vertex_count_value < 2 || vertex_count_value > MAX_VERTICES ||
		edge_count_value < 1 || edge_count_value > MAX_EDGES do return -1
	vertex_count, edge_count := int(vertex_count_value), int(edge_count_value)
	if edge_count > vertex_count * (vertex_count - 1) / 2 ||
		length != c.size_t(2 + 3 * edge_count) do return -1

	var adjacency: [MAX_VERTICES * MAX_VERTICES]i64
	previous_u, previous_v: i64 = -1, -1
	for edge := 0; edge < edge_count; edge += 1 {
		offset := 2 + 3 * edge
		u_value, v_value, weight := input[offset], input[offset+1], input[offset+2]
		if u_value < 0 || u_value >= vertex_count_value || v_value < 0 ||
			v_value >= vertex_count_value || u_value >= v_value || weight < 1 || weight > 7 do return -1
		if edge > 0 && (u_value < previous_u || (u_value == previous_u && v_value <= previous_v)) do return -1
		previous_u, previous_v = u_value, v_value
		u, v := int(u_value), int(v_value)
		adjacency[u * MAX_VERTICES + v] = weight
		adjacency[v * MAX_VERTICES + u] = weight
	}

	var masks: [MAX_VERTICES]int
	node_count := vertex_count
	for node := 0; node < node_count; node += 1 do masks[node] = 1 << node

	var final_masks: [MAX_VERTICES]int
	final_community_count := 0
	for {
		var labels: [MAX_VERTICES]int
		for node := 0; node < node_count; node += 1 do labels[node] = node

		any_moves := false
		for {
			sweep_moved := false
			for node := 0; node < node_count; node += 1 {
				current_score := modularity_score(&adjacency, node_count, &labels)
				best_score := current_score
				best_target := -1
				best_target_key := MAX_VERTICES
				var seen_targets: [MAX_VERTICES]bool
				for other := 0; other < node_count; other += 1 {
					if other == node || adjacency[node * MAX_VERTICES + other] <= 0 do continue
					target := labels[other]
					if target == labels[node] || seen_targets[target] do continue
					seen_targets[target] = true
					candidate_labels := labels
					candidate_labels[node] = target
					candidate_score := modularity_score(&adjacency, node_count, &candidate_labels)
					if candidate_score <= current_score do continue
					target_key := community_key(target, node_count, &labels, &masks)
					if best_target < 0 || candidate_score > best_score ||
						(candidate_score == best_score && target_key < best_target_key) {
						best_score, best_target, best_target_key = candidate_score, target, target_key
					}
				}
				if best_target >= 0 {
					labels[node] = best_target
					sweep_moved = true
					any_moves = true
				}
			}
			if !sweep_moved do break
		}

		if !any_moves {
			for node := 0; node < node_count; node += 1 do final_masks[node] = masks[node]
			final_community_count = node_count
			break
		}

		var group_labels: [MAX_VERTICES]int
		var group_keys: [MAX_VERTICES]int
		group_count := 0
		for node := 0; node < node_count; node += 1 {
			label := labels[node]
			found := false
			for group := 0; group < group_count; group += 1 {
				if group_labels[group] == label { found = true; break }
			}
			if !found {
				group_labels[group_count] = label
				group_keys[group_count] = community_key(label, node_count, &labels, &masks)
				group_count += 1
			}
		}

		for position := 1; position < group_count; position += 1 {
			label, key := group_labels[position], group_keys[position]
			insertion := position
			for insertion > 0 && key < group_keys[insertion-1] {
				group_labels[insertion] = group_labels[insertion-1]
				group_keys[insertion] = group_keys[insertion-1]
				insertion -= 1
			}
			group_labels[insertion], group_keys[insertion] = label, key
		}

		var label_to_group: [MAX_VERTICES]int
		for label := 0; label < MAX_VERTICES; label += 1 do label_to_group[label] = -1
		for group := 0; group < group_count; group += 1 do label_to_group[group_labels[group]] = group

		var next_masks: [MAX_VERTICES]int
		var next_adjacency: [MAX_VERTICES * MAX_VERTICES]i64
		for node := 0; node < node_count; node += 1 {
			group := label_to_group[labels[node]]
			next_masks[group] |= masks[node]
		}
		for left := 0; left < node_count; left += 1 {
			left_group := label_to_group[labels[left]]
			for right := 0; right < node_count; right += 1 {
				right_group := label_to_group[labels[right]]
				next_adjacency[left_group * MAX_VERTICES + right_group] +=
					adjacency[left * MAX_VERTICES + right]
			}
		}
		masks, adjacency = next_masks, next_adjacency
		node_count = group_count
	}

	var original_labels: [MAX_VERTICES]int
	for community := 0; community < final_community_count; community += 1 {
		label := least_vertex(final_masks[community])
		for vertex := 0; vertex < vertex_count; vertex += 1 {
			if (final_masks[community] & (1 << vertex)) != 0 do original_labels[vertex] = label
		}
	}

	packed: i64 = i64(final_community_count) << 24
	for vertex := 0; vertex < vertex_count; vertex += 1 do packed |= i64(original_labels[vertex]) << (3 * vertex)
	return packed
}
