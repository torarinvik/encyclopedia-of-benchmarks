package two_vertex_cuts_spqr

import "core:c"

MAX_N :: 8
MAX_M :: 28
MAX_INPUT :: 67
MAX_PIECES :: 56
MAX_SPLITS :: 28
MODULUS :: i64(998244353)
KIND_S :: 1
KIND_P :: 2

Edge_Ref :: struct { u, v: int, pair_id: int, real: bool }
Piece :: struct { edge_count: int, edges: [MAX_M]Edge_Ref }

connected_without :: proc(adjacency: [^]bool, n, removed: int) -> bool {
	start := 0
	for start == removed { start += 1 }
	seen: [MAX_N]bool
	queue: [MAX_N]int
	seen[start] = true
	queue[0] = start
	head, tail := 0, 1
	for head < tail {
		u := queue[head]
		head += 1
		for v in 0..<n {
			if v != removed && adjacency[u*MAX_N+v] && !seen[v] {
				seen[v] = true
				queue[tail] = v
				tail += 1
			}
		}
	}
	reached := 0
	for v in 0..<n { if v != removed && seen[v] { reached += 1 } }
	expected := n
	if removed >= 0 { expected -= 1 }
	return reached == expected
}

components_after_pair :: proc(piece: ^Piece, n, a, b: int, component: ^[MAX_N]int, count: ^int) {
	for v in 0..<n { component[v] = -1 }
	count^ = 0
	queue: [MAX_N]int
	for start in 0..<n {
		if start == a || start == b || component[start] >= 0 { continue }
		head, tail := 0, 1
		component[start] = count^
		queue[0] = start
		for head < tail {
			u := queue[head]
			head += 1
			for e in 0..<piece.edge_count {
				edge := piece.edges[e]
				if edge.u == a || edge.u == b || edge.v == a || edge.v == b { continue }
				other := -1
				if edge.u == u { other = edge.v } else if edge.v == u { other = edge.u }
				if other >= 0 && component[other] < 0 {
					component[other] = count^
					queue[tail] = other
					tail += 1
				}
			}
		}
		count^ += 1
	}
}

find_split :: proc(piece: ^Piece, n: int, chosen_u, chosen_v: ^int, left_edge: ^[MAX_M]bool) -> bool {
	ecount := piece.edge_count
	for u in 0..<n { for v in (u+1)..<n {
		component: [MAX_N]int
		component_count := 0
		components_after_pair(piece, n, u, v, &component, &component_count)
		edge_class: [MAX_M]int
		sizes: [MAX_M]int
		direct_count := 0
		for e in 0..<ecount {
			edge := piece.edges[e]
			if (edge.u == u && edge.v == v) || (edge.u == v && edge.v == u) {
				edge_class[e] = component_count + direct_count
				direct_count += 1
			} else {
				endpoint := edge.v
				if edge.u != u && edge.u != v { endpoint = edge.u }
				if component[endpoint] < 0 { return false }
				edge_class[e] = component[endpoint]
			}
			if edge_class[e] < 0 || edge_class[e] >= MAX_M { return false }
			sizes[edge_class[e]] += 1
		}
		class_count := component_count + direct_count
		selected := -1
		for c in 0..<class_count { if sizes[c] >= 2 && sizes[c] <= ecount-2 { selected = c; break } }
		use_first_two := selected < 0 && class_count >= 4 && class_count == ecount
		if use_first_two { for c in 0..<class_count { if sizes[c] != 1 { use_first_two = false } } }
		if selected < 0 && !use_first_two { continue }
		for e in 0..<ecount { left_edge[e] = if selected >= 0 { edge_class[e] == selected } else { edge_class[e] < 2 } }
		chosen_u^ = u
		chosen_v^ = v
		return true
	} }
	return false
}

piece_kind :: proc(piece: ^Piece) -> int {
	present: [MAX_N]bool
	vertex_count := 0
	for e in 0..<piece.edge_count {
		for endpoint in [2]int{piece.edges[e].u, piece.edges[e].v} {
			if !present[endpoint] { present[endpoint] = true; vertex_count += 1 }
		}
	}
	if vertex_count == 2 && piece.edge_count >= 3 { return KIND_P }
	if vertex_count == 3 && piece.edge_count == 3 {
		pair: [MAX_N*MAX_N]bool
		for e in 0..<3 { u, v := piece.edges[e].u, piece.edges[e].v; pair[u*MAX_N+v] = true; pair[v*MAX_N+u] = true }
		count := 0
		for u in 0..<MAX_N { for v in (u+1)..<MAX_N { if pair[u*MAX_N+v] { count += 1 } } }
		if count == 3 { return KIND_S }
	}
	return 3
}

find_root :: proc(parent: ^[MAX_PIECES]int, item: int) -> int {
	current := item
	for parent[current] != current { parent[current] = parent[parent[current]]; current = parent[current] }
	return current
}
unite :: proc(parent: ^[MAX_PIECES]int, left, right: int) {
	a, b := find_root(parent, left), find_root(parent, right)
	if a != b { parent[b] = a }
}

pair_components :: proc(adjacency: [^]bool, n, a, b: int) -> int {
	seen: [MAX_N]bool
	queue: [MAX_N]int
	count := 0
	for start in 0..<n {
		if start == a || start == b || seen[start] { continue }
		count += 1
		head, tail := 0, 1
		seen[start] = true
		queue[0] = start
		for head < tail {
			u := queue[head]
			head += 1
			for v in 0..<n {
				if v != a && v != b && adjacency[u*MAX_N+v] && !seen[v] {
					seen[v] = true
					queue[tail] = v
					tail += 1
				}
			}
		}
	}
	return count
}

@(export)
two_vertex_cuts_spqr :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT { return -1 }
	if input[0] < 3 || input[0] > MAX_N || input[1] < 3 || input[1] > MAX_M { return -1 }
	n, m := int(input[0]), int(input[1])
	if length != c.size_t(2+n+2*m) { return -1 }
	weights: [MAX_N]i64
	for v in 0..<n { weights[v] = input[2+v]; if weights[v] < 0 || weights[v] > 1_000_000 { return -1 } }
	adjacency: [MAX_N*MAX_N]bool
	pieces: [MAX_PIECES]Piece
	pieces[0].edge_count = m
	offset := 2+n
	for e in 0..<m {
		a, b := input[offset+2*e], input[offset+2*e+1]
		if a < 0 || a >= i64(n) || b < 0 || b >= i64(n) || a == b { return -1 }
		u, v := int(a), int(b)
		if adjacency[u*MAX_N+v] { return -1 }
		adjacency[u*MAX_N+v], adjacency[v*MAX_N+u] = true, true
		pieces[0].edges[e] = Edge_Ref{u, v, -1, true}
	}
	if !connected_without(&adjacency[0], n, -1) { return -1 }
	for removed in 0..<n { if !connected_without(&adjacency[0], n, removed) { return -1 } }

	piece_count, split_count := 1, 0
	pair_u: [MAX_SPLITS]int
	pair_v: [MAX_SPLITS]int
	is_leaf: [MAX_PIECES]bool
	for index := 0; index < piece_count; index += 1 {
		left_edge: [MAX_M]bool
		u, v := 0, 0
		if !find_split(&pieces[index], n, &u, &v, &left_edge) { is_leaf[index] = true; continue }
		if split_count >= MAX_SPLITS || piece_count+2 > MAX_PIECES { return -1 }
		left_index, right_index := piece_count, piece_count+1
		piece_count += 2
		for e in 0..<pieces[index].edge_count {
			if left_edge[e] { target := &pieces[left_index]; target.edges[target.edge_count] = pieces[index].edges[e]; target.edge_count += 1 }
			else { target := &pieces[right_index]; target.edges[target.edge_count] = pieces[index].edges[e]; target.edge_count += 1 }
		}
		pair_id := split_count
		pair_u[pair_id], pair_v[pair_id] = u, v
		split_count += 1
		pieces[left_index].edges[pieces[left_index].edge_count] = Edge_Ref{u, v, pair_id, false}; pieces[left_index].edge_count += 1
		pieces[right_index].edges[pieces[right_index].edge_count] = Edge_Ref{u, v, pair_id, false}; pieces[right_index].edge_count += 1
		if pieces[left_index].edge_count < 3 || pieces[right_index].edge_count < 3 { return -1 }
	}

	kind: [MAX_PIECES]int
	first_leaf: [MAX_SPLITS]int
	second_leaf: [MAX_SPLITS]int
	occurrences: [MAX_SPLITS]int
	parent: [MAX_PIECES]int
	for id in 0..<MAX_SPLITS { first_leaf[id], second_leaf[id] = -1, -1 }
	for p in 0..<piece_count { parent[p] = p; if is_leaf[p] { kind[p] = piece_kind(&pieces[p]) } }
	for p in 0..<piece_count {
		if !is_leaf[p] { continue }
		for e in 0..<pieces[p].edge_count {
			edge := pieces[p].edges[e]
			if edge.real { continue }
			if edge.pair_id < 0 || edge.pair_id >= split_count { return -1 }
			id := edge.pair_id
			occurrences[id] += 1
			if occurrences[id] == 1 { first_leaf[id] = p } else if occurrences[id] == 2 { second_leaf[id] = p } else { return -1 }
		}
	}
	for id in 0..<split_count {
		if occurrences[id] != 2 || first_leaf[id] == second_leaf[id] { return -1 }
		a, b := first_leaf[id], second_leaf[id]
		if kind[a] == kind[b] && (kind[a] == KIND_S || kind[a] == KIND_P) { unite(&parent, a, b) }
	}
	candidate: [MAX_N*MAX_N]bool
	for id in 0..<split_count { candidate[pair_u[id]*MAX_N+pair_v[id]] = true }
	for leaf in 0..<piece_count {
		if !is_leaf[leaf] || find_root(&parent, leaf) != leaf { continue }
		if kind[leaf] == KIND_S {
			in_group: [MAX_N]bool
			skeleton: [MAX_N*MAX_N]bool
			for member in 0..<piece_count {
				if !is_leaf[member] || find_root(&parent, member) != leaf { continue }
				for e in 0..<pieces[member].edge_count {
					edge := pieces[member].edges[e]
					if !edge.real && find_root(&parent, first_leaf[edge.pair_id]) == leaf && find_root(&parent, second_leaf[edge.pair_id]) == leaf { continue }
					in_group[edge.u], in_group[edge.v] = true, true
					skeleton[edge.u*MAX_N+edge.v], skeleton[edge.v*MAX_N+edge.u] = true, true
				}
			}
			for u in 0..<n { for v in (u+1)..<n { if in_group[u] && in_group[v] && !skeleton[u*MAX_N+v] { candidate[u*MAX_N+v] = true } } }
		} else if kind[leaf] == KIND_P {
			first, second := -1, -1
			for member in 0..<piece_count {
				if !is_leaf[member] || find_root(&parent, member) != leaf { continue }
				for e in 0..<pieces[member].edge_count { for _, endpoint in [2]int{pieces[member].edges[e].u, pieces[member].edges[e].v} {
					if first < 0 { first = endpoint } else if endpoint != first && second < 0 { second = endpoint } else if endpoint != first && endpoint != second { return -1 }
				} }
			}
			if first < 0 || second < 0 { return -1 }
			u, v := min(first, second), max(first, second)
			candidate[u*MAX_N+v] = true
		}
	}
	total: i64 = 0
	for u in 0..<n { for v in (u+1)..<n { if candidate[u*MAX_N+v] {
		components := pair_components(&adjacency[0], n, u, v)
		if components > 1 { total = (total + (weights[u]%MODULUS)*(weights[v]%MODULUS)%MODULUS*i64(components-1))%MODULUS }
	} } }
	return total
}
