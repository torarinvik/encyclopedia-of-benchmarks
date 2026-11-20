module minimum_cycle_basis_horton

const min_n = 3
const max_n = 8
const max_m = 12
const max_length = 39
const max_candidates = 96

struct Edge { u int; v int; weight i64 }

fn cycle_weight(mask u64, edges [max_m]Edge, m int) i64 {
	mut total := i64(0)
	for e in 0 .. m { if ((mask >> e) & 1) != 0 { total += edges[e].weight } }
	return total
}

fn horton_weight(n int, m int, edges [max_m]Edge) i64 {
	mut candidates := [max_candidates]u64{}
	mut costs := [max_candidates]i64{}
	mut candidate_count := 0
	for root in 0 .. n {
		mut distance := [max_n]i64{}
		mut parent := [max_n]int{}
		mut parent_edge := [max_n]int{}
		mut settled := [max_n]bool{}
		mut tree_edge := [max_m]bool{}
		mut path_mask := [max_n]u64{}
		for v in 0 .. n { distance[v] = i64(0x3fffffffffffffff); parent[v] = -1; parent_edge[v] = -1 }
		distance[root] = 0
		tie_scale := i64(m + 1) * (i64(1) << m)
		for _ in 0 .. n {
			mut vertex := -1
			for v in 0 .. n {
				if !settled[v] && distance[v] != i64(0x3fffffffffffffff) && (vertex < 0 || distance[v] < distance[vertex] || (distance[v] == distance[vertex] && v < vertex)) { vertex = v }
			}
			if vertex < 0 { break }
			settled[vertex] = true
			for e in 0 .. m {
				edge := edges[e]
				mut neighbor := -1
				if edge.u == vertex { neighbor = edge.v } else if edge.v == vertex { neighbor = edge.u }
				if neighbor < 0 || settled[neighbor] { continue }
				candidate := distance[vertex] + edge.weight * tie_scale + (i64(1) << e)
				if candidate < distance[neighbor] { distance[neighbor] = candidate; parent[neighbor] = vertex; parent_edge[neighbor] = e }
			}
		}
		for v in 0 .. n {
			if v == root { continue }
			mut cursor := v
			mut steps := 0
			for cursor != root && steps < n {
				pe := parent_edge[cursor]
				if pe < 0 { return -1 }
				tree_edge[pe] = true
				path_mask[v] |= u64(1) << pe
				cursor = parent[cursor]
				steps++
			}
			if cursor != root { return -1 }
		}
		for e in 0 .. m {
			if tree_edge[e] { continue }
			edge := edges[e]
			cycle := path_mask[edge.u] ^ path_mask[edge.v] ^ (u64(1) << e)
			if cycle == 0 { continue }
			mut duplicate := false
			for i in 0 .. candidate_count { if candidates[i] == cycle { duplicate = true; break } }
			if !duplicate && candidate_count < max_candidates {
				candidates[candidate_count] = cycle
				costs[candidate_count] = cycle_weight(cycle, edges, m)
				candidate_count++
			}
		}
	}
	for i in 0 .. candidate_count { for j in i + 1 .. candidate_count {
		if costs[j] < costs[i] || (costs[j] == costs[i] && candidates[j] < candidates[i]) {
			costs[i], costs[j] = costs[j], costs[i]
			candidates[i], candidates[j] = candidates[j], candidates[i]
		}
	} }
	dimension := m - n + 1
	mut basis := [max_m]u64{}
	mut rank := 0
	mut total := i64(0)
	for i in 0 .. candidate_count {
		if rank == dimension { break }
		mut residual := candidates[i]
		mut bit := m - 1
		for bit >= 0 {
			if ((residual >> bit) & 1) == 0 { bit--; continue }
			if basis[bit] != 0 { residual ^= basis[bit] } else { basis[bit] = residual; rank++; total += costs[i]; break }
			bit--
		}
	}
	if rank == dimension { return total }
	return -1
}

@[export: 'minimum_cycle_basis_horton']
pub fn minimum_cycle_basis_horton(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_length { return -1 }
		if input[0] < min_n || input[0] > max_n { return -1 }
		n := int(input[0])
		if input[1] < i64(n - 1) || input[1] > max_m || input[1] > i64(n * (n - 1) / 2) { return -1 }
		m := int(input[1])
		if length != usize(2 + 3 * m) { return -1 }
		mut edges := [max_m]Edge{}
		mut adjacent := [max_n][max_n]bool{}
		mut previous_u := -1
		mut previous_v := -1
		for e in 0 .. m {
			ru, rv, weight := input[2 + 3 * e], input[3 + 3 * e], input[4 + 3 * e]
			if ru < 0 || rv < 0 || ru >= i64(n) || rv >= i64(n) || ru >= rv || weight < 1 || weight > 9 { return -1 }
			u, v := int(ru), int(rv)
			if e > 0 && (u < previous_u || (u == previous_u && v <= previous_v)) { return -1 }
			previous_u, previous_v = u, v
			edges[e] = Edge{u: u, v: v, weight: weight}
			adjacent[u][v] = true; adjacent[v][u] = true
		}
		mut seen := [max_n]bool{}
		mut queue := [max_n]int{}
		mut head := 0
		mut tail := 1
		seen[0] = true
		for head < tail {
			u := queue[head]
			head++
			for v in 0 .. n { if adjacent[u][v] && !seen[v] { seen[v] = true; queue[tail] = v; tail++ } }
		}
		for v in 0 .. n { if !seen[v] { return -1 } }
		return horton_weight(n, m, edges)
	}
}
