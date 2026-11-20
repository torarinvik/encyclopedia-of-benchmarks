package minimum_cycle_basis_horton

import "core:c"

MIN_N :: 3
MAX_N :: 8
MAX_M :: 12
MAX_LEN :: 39
MAX_CANDIDATES :: 96

Edge :: struct { u, v: int, weight: i64 }

cycle_weight :: proc "contextless" (mask: u64, edges: []Edge, m: int) -> i64 {
	total: i64 = 0
	for e in 0..<m { if (mask >> e) & 1 != 0 do total += edges[e].weight }
	return total
}

horton_weight :: proc "contextless" (n, m: int, edges: []Edge) -> i64 {
	candidates := [MAX_CANDIDATES]u64{}
	costs := [MAX_CANDIDATES]i64{}
	candidate_count := 0
	for root in 0..<n {
		distance := [MAX_N]i64{}
		parent := [MAX_N]int{}
		parent_edge := [MAX_N]int{}
		settled := [MAX_N]bool{}
		tree_edge := [MAX_M]bool{}
		path_mask := [MAX_N]u64{}
		for v in 0..<n { distance[v] = 0x3fffffffffffffff; parent[v] = -1; parent_edge[v] = -1 }
		distance[root] = 0
		tie_scale := i64(m+1) * (i64(1) << m)
		for _ in 0..<n {
			vertex := -1
			for v in 0..<n {
				if !settled[v] && distance[v] != 0x3fffffffffffffff && (vertex < 0 || distance[v] < distance[vertex] || (distance[v] == distance[vertex] && v < vertex)) do vertex = v
			}
			if vertex < 0 do break
			settled[vertex] = true
			for e in 0..<m {
				edge := edges[e]
				neighbor := -1
				if edge.u == vertex do neighbor = edge.v else if edge.v == vertex do neighbor = edge.u
				if neighbor < 0 || settled[neighbor] do continue
				candidate := distance[vertex] + edge.weight*tie_scale + (i64(1) << e)
				if candidate < distance[neighbor] { distance[neighbor] = candidate; parent[neighbor] = vertex; parent_edge[neighbor] = e }
			}
		}
		for v in 0..<n {
			if v == root do continue
			cursor, steps := v, 0
			for cursor != root && steps < n {
				pe := parent_edge[cursor]
				if pe < 0 do return -1
				tree_edge[pe] = true
				path_mask[v] |= u64(1) << pe
				cursor = parent[cursor]
				steps += 1
			}
			if cursor != root do return -1
		}
		for e in 0..<m {
			if tree_edge[e] do continue
			edge := edges[e]
			cycle := path_mask[edge.u] ^ path_mask[edge.v] ^ (u64(1) << e)
			if cycle == 0 do continue
			duplicate := false
			for i in 0..<candidate_count { if candidates[i] == cycle { duplicate = true; break } }
			if !duplicate && candidate_count < MAX_CANDIDATES {
				candidates[candidate_count] = cycle
				costs[candidate_count] = cycle_weight(cycle, edges, m)
				candidate_count += 1
			}
		}
	}
	for i in 0..<candidate_count { for j in i+1..<candidate_count {
		if costs[j] < costs[i] || (costs[j] == costs[i] && candidates[j] < candidates[i]) {
			costs[i], costs[j] = costs[j], costs[i]
			candidates[i], candidates[j] = candidates[j], candidates[i]
		}
	} }
	dimension := m-n+1
	basis := [MAX_M]u64{}
	rank := 0
	total: i64 = 0
	for i in 0..<candidate_count {
		if rank == dimension do break
		residual := candidates[i]
		for bit := m-1; bit >= 0; bit -= 1 {
			if (residual >> bit) & 1 == 0 do continue
			if basis[bit] != 0 { residual ^= basis[bit] } else { basis[bit] = residual; rank += 1; total += costs[i]; break }
		}
	}
	if rank == dimension do return total
	return -1
}

@(export)
minimum_cycle_basis_horton :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_LEN) do return -1
	if input[0] < MIN_N || input[0] > MAX_N do return -1
	n := int(input[0])
	if input[1] < i64(n-1) || input[1] > MAX_M || input[1] > i64(n*(n-1)/2) do return -1
	m := int(input[1])
	if length != c.size_t(2+3*m) do return -1
	edges := [MAX_M]Edge{}
	adjacent := [MAX_N][MAX_N]bool{}
	previous_u, previous_v := -1, -1
	for e in 0..<m {
		ru, rv, weight := input[2+3*e], input[3+3*e], input[4+3*e]
		if ru < 0 || rv < 0 || ru >= i64(n) || rv >= i64(n) || ru >= rv || weight < 1 || weight > 9 do return -1
		u, v := int(ru), int(rv)
		if e > 0 && (u < previous_u || (u == previous_u && v <= previous_v)) do return -1
		previous_u, previous_v = u, v
		edges[e] = Edge{u, v, weight}
		adjacent[u][v] = true; adjacent[v][u] = true
	}
	seen := [MAX_N]bool{}
	queue := [MAX_N]int{}
	head, tail := 0, 1
	seen[0] = true
	for head < tail {
		u := queue[head]; head += 1
		for v in 0..<n { if adjacent[u][v] && !seen[v] { seen[v] = true; queue[tail] = v; tail += 1 } }
	}
	for v in 0..<n { if !seen[v] do return -1 }
	return horton_weight(n, m, edges[:])
}
