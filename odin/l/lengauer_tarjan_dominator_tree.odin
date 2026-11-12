package lengauer_tarjan_dominator_tree

import "core:c"

MAX_V :: 63
MAX_E :: 2047
MAX_INPUT :: 4097

lt_eval :: proc "contextless" (vertex: int, ancestor, label, semi, path: ^[MAX_V + 1]int) -> int {
	if ancestor[vertex] == 0 do return vertex
	used, current := 0, vertex
	for ancestor[ancestor[current]] != 0 { path[used] = current; used += 1; current = ancestor[current] }
	for used > 0 {
		used -= 1
		current = path[used]
		p := ancestor[current]
		if semi[label[p]] < semi[label[current]] do label[current] = label[p]
		ancestor[current] = ancestor[p]
	}
	return label[vertex]
}

@(export)
lengauer_tarjan_dominator_tree :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	nv, root_value, me := input[0], input[1], input[2]
	if nv < 1 || nv > MAX_V || root_value < 0 || root_value >= nv || me < 0 || me > MAX_E do return -1
	n, root, m := int(nv), int(root_value), int(me)
	if int(length) != 3 + 2 * m do return -1

	var outmask: [MAX_V]u64
	var out_head: [MAX_V]int
	var edge_source, edge_target, out_next, pred_next: [MAX_E]int
	var pred_head, vertex_at, parent, semi, ancestor, label, immediate, bucket_head, bucket_next: [MAX_V + 1]int
	var dfs_number, node_stack, edge_stack: [MAX_V]int
	var eval_path: [MAX_V + 1]int
	var staged: [MAX_V]u8
	for vertex := 0; vertex < n; vertex += 1 { out_head[vertex] = -1 }
	for vertex := 0; vertex <= MAX_V; vertex += 1 { pred_head[vertex] = -1; bucket_head[vertex] = -1 }

	edge_count := 0
	for i := 0; i < m; i += 1 {
		sv, tv := input[3 + 2 * i], input[4 + 2 * i]
		if sv < 0 || sv >= nv || tv < 0 || tv >= nv do return -1
		s, t := int(sv), int(tv)
		bit := u64(1) << u64(t)
		if (outmask[s] & bit) == 0 {
			outmask[s] |= bit
			edge_source[edge_count] = s
			edge_target[edge_count] = t
			out_next[edge_count] = out_head[s]
			out_head[s] = edge_count
			edge_count += 1
		}
	}

	dfs_count, top := 1, 1
	dfs_number[root] = 1
	vertex_at[1] = root
	node_stack[0] = root
	edge_stack[0] = out_head[root]
	for top > 0 {
		frame := top - 1
		current, edge := node_stack[frame], edge_stack[frame]
		if edge == -1 { top -= 1; continue }
		edge_stack[frame] = out_next[edge]
		target := edge_target[edge]
		if dfs_number[target] == 0 {
			dfs_count += 1
			dfs_number[target] = dfs_count
			vertex_at[dfs_count] = target
			parent[dfs_count] = dfs_number[current]
			node_stack[top] = target
			edge_stack[top] = out_head[target]
			top += 1
		}
	}
	for edge := 0; edge < edge_count; edge += 1 {
		source_number, target_number := dfs_number[edge_source[edge]], dfs_number[edge_target[edge]]
		if source_number != 0 && target_number != 0 { pred_next[edge] = pred_head[target_number]; pred_head[target_number] = edge }
	}
	for vertex := 1; vertex <= dfs_count; vertex += 1 { semi[vertex] = vertex; label[vertex] = vertex }
	for w := dfs_count; w >= 2; w -= 1 {
		for edge := pred_head[w]; edge != -1; edge = pred_next[edge] {
			predecessor := dfs_number[edge_source[edge]]
			representative := lt_eval(predecessor, &ancestor, &label, &semi, &eval_path)
			if semi[representative] < semi[w] { semi[w] = semi[representative] }
		}
		bucket_next[w] = bucket_head[semi[w]]
		bucket_head[semi[w]] = w
		ancestor[w] = parent[w]
		owner := parent[w]
		member := bucket_head[owner]
		bucket_head[owner] = -1
		for member != -1 {
			next := bucket_next[member]
			representative := lt_eval(member, &ancestor, &label, &semi, &eval_path)
			if semi[representative] < semi[member] { immediate[member] = representative } else { immediate[member] = owner }
			member = next
		}
	}
	for w := 2; w <= dfs_count; w += 1 { if immediate[w] != semi[w] { immediate[w] = immediate[immediate[w]] } }
	immediate[1] = 1
	for vertex := 0; vertex < n; vertex += 1 {
		number := dfs_number[vertex]
		if number == 0 { staged[vertex] = 255 } else { staged[vertex] = u8(vertex_at[immediate[number]]) }
	}
	if output == nil || int(capacity) < n do return -2
	for vertex := 0; vertex < n; vertex += 1 { output[vertex] = staged[vertex] }
	return i64(n)
}
