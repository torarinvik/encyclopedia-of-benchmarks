module phylogenetic_tree_from_distance_matrix

const max_n = 6
const max_nodes = 10
const max_edges = 9
const max_output_bytes = 152

fn store_i64_le(mut output []u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

fn tree_distance(node_count int, edge_count int, edge_u [max_edges]int, edge_v [max_edges]int,
	edge_w [max_edges]i64, start int, target int, mut distances [max_nodes]i64) bool {
	mut parent := [max_nodes]int{init: -1}
	mut queue := [max_nodes]int{init: 0}
	mut head := 0
	mut tail := 0
	parent[start] = start
	distances[start] = 0
	queue[tail] = start
	tail++
	for head < tail {
		node := queue[head]
		head++
		if node == target { return true }
		for e in 0 .. edge_count {
			mut neighbor := -1
			if edge_u[e] == node { neighbor = edge_v[e] } else if edge_v[e] == node { neighbor = edge_u[e] }
			if neighbor < 0 || parent[neighbor] != -1 { continue }
			parent[neighbor] = node
			distances[neighbor] = distances[node] + edge_w[e]
			queue[tail] = neighbor
			tail++
		}
	}
	false
}

@[export: 'phylogenetic_tree_from_distance_matrix']
pub fn phylogenetic_tree_from_distance_matrix(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_n * max_n + 2 { return -1 }
		raw_n := input[0]
		if raw_n < 2 || raw_n > max_n || length != usize(1 + raw_n * raw_n) { return -1 }
		n := int(raw_n)
		mut d := [max_n * max_n]i64{init: 0}
		for i in 0 .. n {
			for j in 0 .. n {
				value := input[1 + i * n + j]
				if (i == j && value != 0) || (i != j && (value < 1 || value > 32)) { return -1 }
				d[i * max_n + j] = value
			}
		}
		for i in 0 .. n { for j in (i + 1) .. n { if d[i * max_n + j] != d[j * max_n + i] { return -1 } } }

		mut edge_u := [max_edges]int{init: 0}
		mut edge_v := [max_edges]int{init: 0}
		mut edge_w := [max_edges]i64{init: 0}
		mut edge_count := 1
		edge_u[0] = 0; edge_v[0] = 1; edge_w[0] = 2 * d[1]
		mut label_node := [max_n]int{init: 0}
		label_node[1] = 1
		mut label_mask := [max_nodes]u32{init: 0}
		label_mask[0] = 1; label_mask[1] = 2
		mut node_count := 2
		mut additive := true
		for leaf in 2 .. n {
			if !additive { break }
			mut limb2 := i64(9223372036854775807)
			for i in 0 .. leaf { for j in (i + 1) .. leaf {
				candidate := d[i * max_n + leaf] + d[j * max_n + leaf] - d[i * max_n + j]
				if candidate < limb2 { limb2 = candidate }
			} }
			if limb2 < 0 { additive = false; break }
			mut witness_i := -1
			mut witness_j := -1
			mut attach_distance := i64(0)
			for i in 0 .. leaf {
				if witness_i >= 0 { break }
				for j in (i + 1) .. leaf {
					from_i := 2 * d[i * max_n + leaf] - limb2
					from_j := 2 * d[j * max_n + leaf] - limb2
					if from_i >= 0 && from_j >= 0 && 2 * d[i * max_n + j] == from_i + from_j {
						witness_i = i; witness_j = j; attach_distance = from_i; break
					}
				}
			}
			if witness_i < 0 { additive = false; break }
			start := label_node[witness_i]
			target := label_node[witness_j]
			mut parent_node := [max_nodes]int{init: -1}
			mut parent_edge := [max_nodes]int{init: -1}
			mut queue := [max_nodes]int{init: 0}
			mut head := 0; mut tail := 0
			parent_node[start] = start; queue[tail] = start; tail++
			for head < tail && parent_node[target] < 0 {
				node := queue[head]; head++
				for e in 0 .. edge_count {
					mut neighbor := -1
					if edge_u[e] == node { neighbor = edge_v[e] } else if edge_v[e] == node { neighbor = edge_u[e] }
					if neighbor < 0 || parent_node[neighbor] >= 0 { continue }
					parent_node[neighbor] = node; parent_edge[neighbor] = e
					queue[tail] = neighbor; tail++
				}
			}
			if parent_node[target] < 0 { additive = false; break }
			mut reverse_nodes := [max_nodes]int{init: 0}
			mut reverse_edges := [max_nodes]int{init: 0}
			mut path_node_count := 1; mut path_edge_count := 0; mut current := target
			reverse_nodes[0] = target
			for current != start {
				reverse_edges[path_edge_count] = parent_edge[current]; path_edge_count++
				current = parent_node[current]; reverse_nodes[path_node_count] = current; path_node_count++
			}
			mut path_nodes := [max_nodes]int{init: 0}
			mut path_edges := [max_nodes]int{init: 0}
			for i in 0 .. path_node_count { path_nodes[i] = reverse_nodes[path_node_count - 1 - i] }
			for i in 0 .. path_edge_count { path_edges[i] = reverse_edges[path_edge_count - 1 - i] }
			mut elapsed := i64(0)
			mut attach_node := -1; mut split_edge := -1; mut split_left := -1; mut split_right := -1
			mut split_from_left := i64(0)
			for step in 0 .. path_node_count {
				if attach_distance == elapsed { attach_node = path_nodes[step]; break }
				if step == path_edge_count { break }
				e := path_edges[step]
				weight := edge_w[e]
				if elapsed < attach_distance && attach_distance < elapsed + weight {
					split_edge = e; split_left = path_nodes[step]; split_right = path_nodes[step + 1]
					split_from_left = attach_distance - elapsed; break
				}
				elapsed += weight
			}
			if attach_node < 0 && split_edge < 0 { additive = false; break }
			if split_edge >= 0 {
				if node_count >= max_nodes || edge_count >= max_edges { additive = false; break }
				internal := node_count; node_count++
				whole := edge_w[split_edge]
				edge_u[split_edge] = split_left; edge_v[split_edge] = internal; edge_w[split_edge] = split_from_left
				edge_u[edge_count] = internal; edge_v[edge_count] = split_right; edge_w[edge_count] = whole - split_from_left
				edge_count++; attach_node = internal
			}
			if limb2 == 0 {
				if label_mask[attach_node] != 0 { additive = false; break }
				label_node[leaf] = attach_node; label_mask[attach_node] |= u32(1 << leaf)
			} else {
				if node_count >= max_nodes || edge_count >= max_edges { additive = false; break }
				new_leaf := node_count; node_count++
				label_node[leaf] = new_leaf; label_mask[new_leaf] = u32(1 << leaf)
				edge_u[edge_count] = attach_node; edge_v[edge_count] = new_leaf; edge_w[edge_count] = limb2
				edge_count++
			}
		}
		if !additive { return 0 }
		mut distances := [max_nodes]i64{init: 0}
		for i in 0 .. n { for j in (i + 1) .. n {
			if !tree_distance(node_count, edge_count, edge_u, edge_v, edge_w, label_node[i], label_node[j], mut distances) || distances[label_node[j]] != 2 * d[i * max_n + j] { return 0 }
		} }
		full_mask := (u32(1) << n) - 1
		mut record_mask := [max_edges]i64{init: 0}
		mut record_weight := [max_edges]i64{init: 0}
		for e in 0 .. edge_count {
			mut seen := u32(1) << edge_u[e]
			mut cut_queue := [max_nodes]int{init: 0}
			mut head := 0; mut tail := 0; cut_queue[tail] = edge_u[e]; tail++
			mut mask := u32(0)
			for head < tail {
				node := cut_queue[head]; head++; mask |= label_mask[node]
				for other in 0 .. edge_count {
					if other == e { continue }
					mut neighbor := -1
					if edge_u[other] == node { neighbor = edge_v[other] } else if edge_v[other] == node { neighbor = edge_u[other] }
					if neighbor < 0 || (seen & (u32(1) << neighbor)) != 0 { continue }
					seen |= u32(1) << neighbor; cut_queue[tail] = neighbor; tail++
				}
			}
			if (mask & 1) == 0 { mask = full_mask ^ mask }
			record_mask[e] = i64(mask); record_weight[e] = edge_w[e]
		}
		for i in 1 .. edge_count {
			mask := record_mask[i]; weight := record_weight[i]; mut j := i
			for j > 0 && (record_mask[j - 1] > mask || (record_mask[j - 1] == mask && record_weight[j - 1] > weight)) {
				record_mask[j] = record_mask[j - 1]; record_weight[j] = record_weight[j - 1]; j--
			}
			record_mask[j] = mask; record_weight[j] = weight
		}
		output_bytes := 8 * (1 + 2 * edge_count)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut staged := [max_output_bytes]u8{init: 0}
		store_i64_le(mut staged[..], 0, i64(edge_count))
		for i in 0 .. edge_count {
			store_i64_le(mut staged[..], 8 * (1 + 2 * i), record_mask[i])
			store_i64_le(mut staged[..], 8 * (2 + 2 * i), record_weight[i])
		}
		for byte in 0 .. output_bytes { output[byte] = staged[byte] }
		return i64(output_bytes)
	}
}
