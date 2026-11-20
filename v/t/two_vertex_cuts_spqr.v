module two_vertex_cuts_spqr

const max_n = 8
const max_m = 28
const max_input = 67
const max_pieces = 56
const max_splits = 28
const modulus = i64(998244353)
const kind_s = 1
const kind_p = 2

struct EdgeRef {
	u int
	v int
	pair_id int
	real bool
}

struct Piece {
	edge_count int
	edges [max_m]EdgeRef
}

fn connected_without(adjacency []bool, n int, removed int) bool {
	mut start := 0
	for start == removed { start++ }
	mut seen := [max_n]bool{}
	mut queue := [max_n]int{}
	seen[start] = true
	queue[0] = start
	mut head := 0
	mut tail := 1
	for head < tail {
		u := queue[head]
		head++
		for v in 0 .. n {
			if v != removed && adjacency[u * max_n + v] && !seen[v] {
				seen[v] = true
				queue[tail] = v
				tail++
			}
		}
	}
	mut reached := 0
	for v in 0 .. n { if v != removed && seen[v] { reached++ } }
	expected := n
	if removed >= 0 { expected-- }
	return reached == expected
}

fn components_after_pair(piece &Piece, n int, a int, b int, mut component [max_n]int, mut count int) {
	for v in 0 .. n { component[v] = -1 }
	count = 0
	mut queue := [max_n]int{}
	for start in 0 .. n {
		if start == a || start == b || component[start] >= 0 { continue }
		mut head := 0
		mut tail := 1
		component[start] = count
		queue[0] = start
		for head < tail {
			u := queue[head]
			head++
			for edge_id in 0 .. piece.edge_count {
				edge := piece.edges[edge_id]
				if edge.u == a || edge.u == b || edge.v == a || edge.v == b { continue }
				mut other := -1
				if edge.u == u { other = edge.v } else if edge.v == u { other = edge.u }
				if other >= 0 && component[other] < 0 {
					component[other] = count
					queue[tail] = other
					tail++
				}
			}
		}
		count++
	}
}

fn find_split(piece &Piece, n int, mut chosen_u int, mut chosen_v int, mut left_edge [max_m]bool) bool {
	for u in 0 .. n { for v in (u + 1) .. n {
		mut component := [max_n]int{}
		mut component_count := 0
		components_after_pair(piece, n, u, v, mut component, mut component_count)
		mut edge_class := [max_m]int{}
		mut sizes := [max_m]int{}
		mut direct_count := 0
		for e in 0 .. piece.edge_count {
			edge := piece.edges[e]
			if (edge.u == u && edge.v == v) || (edge.u == v && edge.v == u) {
				edge_class[e] = component_count + direct_count
				direct_count++
			} else {
				endpoint := if edge.u != u && edge.u != v { edge.u } else { edge.v }
				if component[endpoint] < 0 { return false }
				edge_class[e] = component[endpoint]
			}
			if edge_class[e] < 0 || edge_class[e] >= max_m { return false }
			sizes[edge_class[e]]++
		}
		class_count := component_count + direct_count
		mut selected := -1
		for c in 0 .. class_count { if sizes[c] >= 2 && sizes[c] <= piece.edge_count - 2 { selected = c; break } }
		mut use_first_two := selected < 0 && class_count >= 4 && class_count == piece.edge_count
		if use_first_two { for c in 0 .. class_count { if sizes[c] != 1 { use_first_two = false } } }
		if selected < 0 && !use_first_two { continue }
		for e in 0 .. piece.edge_count { left_edge[e] = if selected >= 0 { edge_class[e] == selected } else { edge_class[e] < 2 } }
		chosen_u = u
		chosen_v = v
		return true
	} }
	return false
}

fn piece_kind(piece &Piece) int {
	mut present := [max_n]bool{}
	mut vertex_count := 0
	for e in 0 .. piece.edge_count {
		for endpoint in [piece.edges[e].u, piece.edges[e].v] {
			if !present[endpoint] { present[endpoint] = true; vertex_count++ }
		}
	}
	if vertex_count == 2 && piece.edge_count >= 3 { return kind_p }
	if vertex_count == 3 && piece.edge_count == 3 {
		mut pair := [max_n * max_n]bool{}
		for e in 0 .. 3 { u, v := piece.edges[e].u, piece.edges[e].v; pair[u * max_n + v] = true; pair[v * max_n + u] = true }
		mut count := 0
		for u in 0 .. max_n { for v in (u + 1) .. max_n { if pair[u * max_n + v] { count++ } } }
		if count == 3 { return kind_s }
	}
	return 3
}

fn find_root(mut parent [max_pieces]int, item int) int {
	mut current := item
	for parent[current] != current { parent[current] = parent[parent[current]]; current = parent[current] }
	return current
}

fn unite(mut parent [max_pieces]int, left int, right int) {
	a := find_root(mut parent, left)
	b := find_root(mut parent, right)
	if a != b { parent[b] = a }
}

fn pair_components(adjacency []bool, n int, a int, b int) int {
	mut seen := [max_n]bool{}
	mut queue := [max_n]int{}
	mut count := 0
	for start in 0 .. n {
		if start == a || start == b || seen[start] { continue }
		count++
		mut head := 0
		mut tail := 1
		seen[start] = true
		queue[0] = start
		for head < tail {
			u := queue[head]
			head++
			for v in 0 .. n {
				if v != a && v != b && adjacency[u * max_n + v] && !seen[v] {
					seen[v] = true
					queue[tail] = v
					tail++
				}
			}
		}
	}
	return count
}

@[export: 'two_vertex_cuts_spqr']
pub fn two_vertex_cuts_spqr(input &i64, length usize) i64 {
	if length < 2 || length > max_input { return -1 }
	unsafe {
		if input == nil { return -1 }
		n_value := input[0]
		m_value := input[1]
		if n_value < 3 || n_value > max_n || m_value < 3 || m_value > max_m { return -1 }
		n, m := int(n_value), int(m_value)
		if length != usize(2 + n + 2 * m) { return -1 }
		mut weights := [max_n]i64{}
		for v in 0 .. n { weights[v] = input[2 + v]; if weights[v] < 0 || weights[v] > 1000000 { return -1 } }
		mut adjacency := [max_n * max_n]bool{}
		mut pieces := [max_pieces]Piece{}
		pieces[0].edge_count = m
		offset := 2 + n
		for e in 0 .. m {
			left, right := input[offset + 2 * e], input[offset + 2 * e + 1]
			if left < 0 || left >= n_value || right < 0 || right >= n_value || left == right { return -1 }
			u, v := int(left), int(right)
			if adjacency[u * max_n + v] { return -1 }
			adjacency[u * max_n + v] = true
			adjacency[v * max_n + u] = true
			pieces[0].edges[e] = EdgeRef{u: u, v: v, pair_id: -1, real: true}
		}
		if !connected_without(adjacency[..], n, -1) { return -1 }
		for removed in 0 .. n { if !connected_without(adjacency[..], n, removed) { return -1 } }

		mut piece_count := 1
		mut split_count := 0
		mut pair_u := [max_splits]int{}
		mut pair_v := [max_splits]int{}
		mut is_leaf := [max_pieces]bool{}
		mut index := 0
		for index < piece_count {
			mut left_edge := [max_m]bool{}
			mut u, v := 0, 0
			if !find_split(&pieces[index], n, mut u, mut v, mut left_edge) {
				is_leaf[index] = true
				index++
				continue
			}
			if split_count >= max_splits || piece_count + 2 > max_pieces { return -1 }
			left_index, right_index := piece_count, piece_count + 1
			piece_count += 2
			for e in 0 .. pieces[index].edge_count {
				if left_edge[e] { pieces[left_index].edges[pieces[left_index].edge_count] = pieces[index].edges[e]; pieces[left_index].edge_count++ }
				else { pieces[right_index].edges[pieces[right_index].edge_count] = pieces[index].edges[e]; pieces[right_index].edge_count++ }
			}
			pair_id := split_count
			pair_u[pair_id], pair_v[pair_id] = u, v
			split_count++
			pieces[left_index].edges[pieces[left_index].edge_count] = EdgeRef{u: u, v: v, pair_id: pair_id, real: false}
			pieces[left_index].edge_count++
			pieces[right_index].edges[pieces[right_index].edge_count] = EdgeRef{u: u, v: v, pair_id: pair_id, real: false}
			pieces[right_index].edge_count++
			if pieces[left_index].edge_count < 3 || pieces[right_index].edge_count < 3 { return -1 }
			index++
		}

		mut kind := [max_pieces]int{}
		mut first_leaf := [max_splits]int{init: -1}
		mut second_leaf := [max_splits]int{init: -1}
		mut occurrences := [max_splits]int{}
		mut parent := [max_pieces]int{}
		for p in 0 .. piece_count { parent[p] = p; if is_leaf[p] { kind[p] = piece_kind(&pieces[p]) } }
		for p in 0 .. piece_count {
			if !is_leaf[p] { continue }
			for e in 0 .. pieces[p].edge_count {
				edge := pieces[p].edges[e]
				if edge.real { continue }
				if edge.pair_id < 0 || edge.pair_id >= split_count { return -1 }
				id := edge.pair_id
				occurrences[id]++
				if occurrences[id] == 1 { first_leaf[id] = p } else if occurrences[id] == 2 { second_leaf[id] = p } else { return -1 }
			}
		}
		for id in 0 .. split_count {
			if occurrences[id] != 2 || first_leaf[id] == second_leaf[id] { return -1 }
			a, b := first_leaf[id], second_leaf[id]
			if kind[a] == kind[b] && (kind[a] == kind_s || kind[a] == kind_p) { unite(mut parent, a, b) }
		}
		mut candidate := [max_n * max_n]bool{}
		for id in 0 .. split_count { candidate[pair_u[id] * max_n + pair_v[id]] = true }
		for leaf in 0 .. piece_count {
			if !is_leaf[leaf] || find_root(mut parent, leaf) != leaf { continue }
			if kind[leaf] == kind_s {
				mut in_group := [max_n]bool{}
				mut skeleton := [max_n * max_n]bool{}
				for member in 0 .. piece_count {
					if !is_leaf[member] || find_root(mut parent, member) != leaf { continue }
					for e in 0 .. pieces[member].edge_count {
						edge := pieces[member].edges[e]
						if !edge.real {
							id := edge.pair_id
						if find_root(mut parent, first_leaf[id]) == leaf && find_root(mut parent, second_leaf[id]) == leaf { continue }
						}
						in_group[edge.u], in_group[edge.v] = true, true
						skeleton[edge.u * max_n + edge.v] = true
						skeleton[edge.v * max_n + edge.u] = true
					}
				}
				for u in 0 .. n { for v in (u + 1) .. n { if in_group[u] && in_group[v] && !skeleton[u * max_n + v] { candidate[u * max_n + v] = true } } }
			} else if kind[leaf] == kind_p {
				mut first, second := -1, -1
				for member in 0 .. piece_count {
					if !is_leaf[member] || find_root(mut parent, member) != leaf { continue }
					for e in 0 .. pieces[member].edge_count { for endpoint in [pieces[member].edges[e].u, pieces[member].edges[e].v] {
						if first < 0 { first = endpoint } else if endpoint != first && second < 0 { second = endpoint } else if endpoint != first && endpoint != second { return -1 }
					} }
				}
				if first < 0 || second < 0 { return -1 }
				u, v := first, second
				if u > v { u, v = v, u }
				candidate[u * max_n + v] = true
			}
		}
		mut total := i64(0)
		for u in 0 .. n { for v in (u + 1) .. n { if candidate[u * max_n + v] {
			components := pair_components(adjacency[..], n, u, v)
			if components > 1 { total = (total + (weights[u] % modulus) * (weights[v] % modulus) % modulus * i64(components - 1)) % modulus }
		} } }
		return total
	}
}
