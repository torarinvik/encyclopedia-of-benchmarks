package phylogenetic_tree_from_distance_matrix

import "core:c"

MAX_N :: 6
MAX_NODES :: 10
MAX_EDGES :: 9
MAX_OUTPUT_BYTES :: 152

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

tree_distance :: proc(node_count, edge_count: int, edge_u, edge_v: [^]int, edge_w: [^]i64,
	start, target: int, distances: [^]i64) -> bool {
	parent: [MAX_NODES]int = {}
	queue: [MAX_NODES]int = {}
	for i := 0; i < node_count; i += 1 { parent[i] = -1 }
	head, tail := 0, 0
	parent[start] = start; distances[start] = 0; queue[tail] = start; tail += 1
	for head < tail {
		node := queue[head]; head += 1
		if node == target do return true
		for e := 0; e < edge_count; e += 1 {
			neighbor := -1
			if edge_u[e] == node do neighbor = edge_v[e] else if edge_v[e] == node do neighbor = edge_u[e]
			if neighbor < 0 || parent[neighbor] != -1 do continue
			parent[neighbor] = node; distances[neighbor] = distances[node] + edge_w[e]
			queue[tail] = neighbor; tail += 1
		}
	}
	return false
}

@(export)
phylogenetic_tree_from_distance_matrix :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_N*MAX_N+2 do return -1
	raw_n := input[0]
	if raw_n < 2 || raw_n > MAX_N || length != c.size_t(1+raw_n*raw_n) do return -1
	n := int(raw_n)
	d: [MAX_N*MAX_N]i64 = {}
	for i := 0; i < n; i += 1 { for j := 0; j < n; j += 1 {
		value := input[1+i*n+j]
		if (i == j && value != 0) || (i != j && (value < 1 || value > 32)) do return -1
		d[i*MAX_N+j] = value
	}}
	for i := 0; i < n; i += 1 { for j := i+1; j < n; j += 1 { if d[i*MAX_N+j] != d[j*MAX_N+i] do return -1 } }

	edge_u: [MAX_EDGES]int = {}
	edge_v: [MAX_EDGES]int = {}
	edge_w: [MAX_EDGES]i64 = {}
	edge_count := 1
	edge_u[0] = 0; edge_v[0] = 1; edge_w[0] = 2*d[1]
	label_node: [MAX_N]int = {}
	label_node[1] = 1
	label_mask: [MAX_NODES]u32 = {}
	label_mask[0] = 1; label_mask[1] = 2
	node_count := 2
	additive := true
	for leaf := 2; leaf < n; leaf += 1 {
		if !additive do break
		limb2 := i64(9223372036854775807)
		for i := 0; i < leaf; i += 1 { for j := i+1; j < leaf; j += 1 {
			candidate := d[i*MAX_N+leaf]+d[j*MAX_N+leaf]-d[i*MAX_N+j]
			if candidate < limb2 do limb2 = candidate
		}}
		if limb2 < 0 { additive = false; break }
		witness_i, witness_j := -1, -1
		attach_distance := i64(0)
		for i := 0; i < leaf && witness_i < 0; i += 1 { for j := i+1; j < leaf; j += 1 {
			from_i := 2*d[i*MAX_N+leaf]-limb2
			from_j := 2*d[j*MAX_N+leaf]-limb2
			if from_i >= 0 && from_j >= 0 && 2*d[i*MAX_N+j] == from_i+from_j {
				witness_i, witness_j = i, j; attach_distance = from_i; break
			}
		}}
		if witness_i < 0 { additive = false; break }
		start, target := label_node[witness_i], label_node[witness_j]
		parent_node: [MAX_NODES]int = {}
		parent_edge: [MAX_NODES]int = {}
		queue: [MAX_NODES]int = {}
		for i := 0; i < node_count; i += 1 { parent_node[i] = -1; parent_edge[i] = -1 }
		head, tail := 0, 0
		parent_node[start] = start; queue[tail] = start; tail += 1
		for head < tail && parent_node[target] < 0 {
			node := queue[head]; head += 1
			for e := 0; e < edge_count; e += 1 {
				neighbor := -1
				if edge_u[e] == node do neighbor = edge_v[e] else if edge_v[e] == node do neighbor = edge_u[e]
				if neighbor < 0 || parent_node[neighbor] >= 0 do continue
				parent_node[neighbor] = node; parent_edge[neighbor] = e; queue[tail] = neighbor; tail += 1
			}
		}
		if parent_node[target] < 0 { additive = false; break }
		reverse_nodes: [MAX_NODES]int = {}
		reverse_edges: [MAX_NODES]int = {}
		path_node_count, path_edge_count, current := 1, 0, target
		reverse_nodes[0] = target
		for current != start {
			reverse_edges[path_edge_count] = parent_edge[current]; path_edge_count += 1
			current = parent_node[current]; reverse_nodes[path_node_count] = current; path_node_count += 1
		}
		path_nodes: [MAX_NODES]int = {}
		path_edges: [MAX_NODES]int = {}
		for i := 0; i < path_node_count; i += 1 { path_nodes[i] = reverse_nodes[path_node_count-1-i] }
		for i := 0; i < path_edge_count; i += 1 { path_edges[i] = reverse_edges[path_edge_count-1-i] }
		elapsed := i64(0)
		attach_node, split_edge, split_left, split_right := -1, -1, -1, -1
		split_from_left := i64(0)
		for step := 0; step < path_node_count; step += 1 {
			if attach_distance == elapsed { attach_node = path_nodes[step]; break }
			if step == path_edge_count do break
			e := path_edges[step]; weight := edge_w[e]
			if elapsed < attach_distance && attach_distance < elapsed+weight {
				split_edge, split_left, split_right = e, path_nodes[step], path_nodes[step+1]
				split_from_left = attach_distance-elapsed; break
			}
			elapsed += weight
		}
		if attach_node < 0 && split_edge < 0 { additive = false; break }
		if split_edge >= 0 {
			if node_count >= MAX_NODES || edge_count >= MAX_EDGES { additive = false; break }
			internal := node_count; node_count += 1
			whole := edge_w[split_edge]
			edge_u[split_edge], edge_v[split_edge], edge_w[split_edge] = split_left, internal, split_from_left
			edge_u[edge_count], edge_v[edge_count], edge_w[edge_count] = internal, split_right, whole-split_from_left
			edge_count += 1; attach_node = internal
		}
		if limb2 == 0 {
			if label_mask[attach_node] != 0 { additive = false; break }
			label_node[leaf] = attach_node; label_mask[attach_node] |= 1<<leaf
		} else {
			if node_count >= MAX_NODES || edge_count >= MAX_EDGES { additive = false; break }
			new_leaf := node_count; node_count += 1
			label_node[leaf] = new_leaf; label_mask[new_leaf] = 1<<leaf
			edge_u[edge_count], edge_v[edge_count], edge_w[edge_count] = attach_node, new_leaf, limb2
			edge_count += 1
		}
	}
	if !additive do return 0
	distances: [MAX_NODES]i64 = {}
	for i := 0; i < n; i += 1 { for j := i+1; j < n; j += 1 {
		if !tree_distance(node_count, edge_count, &edge_u[0], &edge_v[0], &edge_w[0], label_node[i], label_node[j], &distances[0]) || distances[label_node[j]] != 2*d[i*MAX_N+j] do return 0
	}}
	full_mask := (1<<n)-1
	record_mask: [MAX_EDGES]i64 = {}
	record_weight: [MAX_EDGES]i64 = {}
	for e := 0; e < edge_count; e += 1 {
		seen := 1<<edge_u[e]
		cut_queue: [MAX_NODES]int = {}
		head, tail := 0, 0; cut_queue[tail] = edge_u[e]; tail += 1
		mask := 0
		for head < tail {
			node := cut_queue[head]; head += 1; mask |= int(label_mask[node])
			for other := 0; other < edge_count; other += 1 {
				if other == e do continue
				neighbor := -1
				if edge_u[other] == node do neighbor = edge_v[other] else if edge_v[other] == node do neighbor = edge_u[other]
				if neighbor < 0 || seen&(1<<neighbor) != 0 do continue
				seen |= 1<<neighbor; cut_queue[tail] = neighbor; tail += 1
			}
		}
		if mask&1 == 0 do mask = full_mask ^ mask
		record_mask[e] = i64(mask); record_weight[e] = edge_w[e]
	}
	for i := 1; i < edge_count; i += 1 {
		mask, weight := record_mask[i], record_weight[i]; j := i
		for j > 0 && (record_mask[j-1] > mask || (record_mask[j-1] == mask && record_weight[j-1] > weight)) {
			record_mask[j], record_weight[j] = record_mask[j-1], record_weight[j-1]; j -= 1
		}
		record_mask[j], record_weight[j] = mask, weight
	}
	output_bytes := 8*(1+2*edge_count)
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	staged: [MAX_OUTPUT_BYTES]u8 = {}
	store_i64_le(&staged[0], 0, i64(edge_count))
	for i := 0; i < edge_count; i += 1 {
		store_i64_le(&staged[0], 8*(1+2*i), record_mask[i])
		store_i64_le(&staged[0], 8*(2+2*i), record_weight[i])
	}
	for byte := 0; byte < output_bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(output_bytes)
}
