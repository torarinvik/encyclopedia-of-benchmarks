package hashiwokakero_small_solver

import "core:c"

MAX_ISLANDS :: 6
MAX_EDGE_SLOTS :: 12
MAX_PARSEABLE_INPUT_LENGTH :: 20

Solver :: struct {
	 island_count: int,
	 edge_count: int,
	 x, y: [MAX_ISLANDS]i64,
	 residual: [MAX_ISLANDS]i64,
	 remaining: [MAX_ISLANDS]int,
	 edge_u, edge_v: [MAX_EDGE_SLOTS]int,
	 multiplicity, solution: [MAX_EDGE_SLOTS]int,
}

edges_cross :: proc "contextless" (s: ^Solver, first, second: int) -> bool {
	a, b := s.edge_u[first], s.edge_v[first]
	c, d := s.edge_u[second], s.edge_v[second]
	first_horizontal := s.y[a] == s.y[b]
	second_horizontal := s.y[c] == s.y[d]
	if first_horizontal == second_horizontal do return false
	h0, h1, v0, v1 := a, b, c, d
	if !first_horizontal { h0, h1, v0, v1 = c, d, a, b }
	hx, hy := s.x[v0], s.y[h0]
	hmin, hmax := min(s.x[h0], s.x[h1]), max(s.x[h0], s.x[h1])
	vmin, vmax := min(s.y[v0], s.y[v1]), max(s.y[v0], s.y[v1])
	return hmin < hx && hx < hmax && vmin < hy && hy < vmax
}

possible_graph_connected :: proc "contextless" (s: ^Solver, assigned_through: int) -> bool {
	reached: [MAX_ISLANDS]bool = {}
	stack: [MAX_ISLANDS]int = {}
	top := 1
	reached[0] = true
	stack[0] = 0
	for top != 0 {
		top -= 1
		island := stack[top]
		for edge := 0; edge < s.edge_count; edge += 1 {
			usable := edge <= assigned_through && s.multiplicity[edge] != 0
			if edge > assigned_through {
				usable = true
				for fixed := 0; fixed <= assigned_through; fixed += 1 {
					if s.multiplicity[fixed] != 0 && edges_cross(s, fixed, edge) {
						usable = false
						break
					}
				}
			}
			if !usable do continue
			neighbor := s.island_count
			if s.edge_u[edge] == island { neighbor = s.edge_v[edge] }
			else if s.edge_v[edge] == island { neighbor = s.edge_u[edge] }
			if neighbor < s.island_count && !reached[neighbor] {
				reached[neighbor] = true
				stack[top] = neighbor
				top += 1
			}
		}
	}
	for island := 0; island < s.island_count; island += 1 {
		if !reached[island] do return false
	}
	return true
}

residuals_feasible :: proc "contextless" (s: ^Solver) -> bool {
	for island := 0; island < s.island_count; island += 1 {
		if s.residual[island] < 0 || s.residual[island] > i64(2 * s.remaining[island]) do return false
	}
	return true
}

search :: proc "contextless" (s: ^Solver, depth: int) -> bool {
	if depth == s.edge_count {
		for island := 0; island < s.island_count; island += 1 {
			if s.residual[island] != 0 do return false
		}
		if !possible_graph_connected(s, s.edge_count - 1) do return false
		for edge := 0; edge < s.edge_count; edge += 1 { s.solution[edge] = s.multiplicity[edge] }
		return true
	}
	u, v := s.edge_u[depth], s.edge_v[depth]
	s.remaining[u] -= 1
	s.remaining[v] -= 1
	for amount := 0; amount <= 2; amount += 1 {
		if i64(amount) > s.residual[u] || i64(amount) > s.residual[v] do continue
		conflict := false
		if amount != 0 {
			for prior := 0; prior < depth; prior += 1 {
				if s.multiplicity[prior] != 0 && edges_cross(s, prior, depth) {
					conflict = true
					break
				}
			}
		}
		if conflict do continue
		s.multiplicity[depth] = amount
		s.residual[u] -= i64(amount)
		s.residual[v] -= i64(amount)
		if residuals_feasible(s) && possible_graph_connected(s, depth) && search(s, depth + 1) {
			s.residual[u] += i64(amount)
			s.residual[v] += i64(amount)
			s.remaining[u] += 1
			s.remaining[v] += 1
			return true
		}
		s.residual[u] += i64(amount)
		s.residual[v] += i64(amount)
		s.multiplicity[depth] = 0
	}
	s.remaining[u] += 1
	s.remaining[v] += 1
	return false
}

@(export)
hashiwokakero_small_solver :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	if input[0] < 2 || input[0] > MAX_ISLANDS do return -1
	n := int(input[0])
	if length != c.size_t(1 + 3 * n) do return -1
	s: Solver
	s.island_count = n
	for island := 0; island < n; island += 1 {
		x, y, demand := input[1 + 3 * island], input[2 + 3 * island], input[3 + 3 * island]
		if x < 0 || x > 7 || y < 0 || y > 7 || demand < 1 || demand > 8 do return -1
		for prior := 0; prior < island; prior += 1 {
			if s.x[prior] == x && s.y[prior] == y do return -1
		}
		s.x[island] = x
		s.y[island] = y
		s.residual[island] = demand
	}
	for first := 0; first < n; first += 1 {
		for second := first + 1; second < n; second += 1 {
			if s.x[first] != s.x[second] && s.y[first] != s.y[second] do continue
			blocked := false
			for middle := 0; middle < n; middle += 1 {
				if middle == first || middle == second do continue
				if s.y[first] == s.y[second] && s.y[middle] == s.y[first] &&
					((s.x[first] < s.x[middle] && s.x[middle] < s.x[second]) ||
					 (s.x[second] < s.x[middle] && s.x[middle] < s.x[first])) { blocked = true }
				if s.x[first] == s.x[second] && s.x[middle] == s.x[first] &&
					((s.y[first] < s.y[middle] && s.y[middle] < s.y[second]) ||
					 (s.y[second] < s.y[middle] && s.y[middle] < s.y[first])) { blocked = true }
			}
			if !blocked {
				if s.edge_count == MAX_EDGE_SLOTS do return -1
				edge := s.edge_count
				s.edge_u[edge] = first
				s.edge_v[edge] = second
				s.edge_count += 1
				s.remaining[first] += 1
				s.remaining[second] += 1
			}
		}
	}
	if !search(&s, 0) do return -2
	result := i64(1) << 32
	for edge := 0; edge < s.edge_count; edge += 1 {
		result |= i64(s.solution[edge]) << u32(2 * edge)
	}
	return result
}
