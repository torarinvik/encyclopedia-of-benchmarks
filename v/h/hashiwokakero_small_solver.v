module hashiwokakero_small_solver

const max_islands = 6
const max_edge_slots = 12
const max_parseable_input_length = 20

struct Solver {
	mut:
		island_count int
		edge_count int
		x [max_islands]i64
		y [max_islands]i64
		residual [max_islands]i64
		remaining [max_islands]int
		edge_u [max_edge_slots]int
		edge_v [max_edge_slots]int
		multiplicity [max_edge_slots]int
		solution [max_edge_slots]int
}

fn edges_cross(s &Solver, first int, second int) bool {
	a, b := s.edge_u[first], s.edge_v[first]
	c, d := s.edge_u[second], s.edge_v[second]
	first_horizontal := s.y[a] == s.y[b]
	second_horizontal := s.y[c] == s.y[d]
	if first_horizontal == second_horizontal { return false }
	h0, h1, v0, v1 := a, b, c, d
	if !first_horizontal { h0, h1, v0, v1 = c, d, a, b }
	hx, hy := s.x[v0], s.y[h0]
	hmin, hmax := min(s.x[h0], s.x[h1]), max(s.x[h0], s.x[h1])
	vmin, vmax := min(s.y[v0], s.y[v1]), max(s.y[v0], s.y[v1])
	return hmin < hx && hx < hmax && vmin < hy && hy < vmax
}

fn possible_graph_connected(s &Solver, assigned_through int) bool {
	mut reached := [max_islands]bool{}
	mut stack := [max_islands]int{}
	mut top := 1
	reached[0] = true
	stack[0] = 0
	for top != 0 {
		top--
		island := stack[top]
		for edge in 0 .. s.edge_count {
			mut usable := edge <= assigned_through && s.multiplicity[edge] != 0
			if edge > assigned_through {
				usable = true
				for fixed in 0 .. assigned_through + 1 {
					if s.multiplicity[fixed] != 0 && edges_cross(s, fixed, edge) {
						usable = false
						break
					}
				}
			}
			if !usable { continue }
			mut neighbor := s.island_count
			if s.edge_u[edge] == island { neighbor = s.edge_v[edge] }
			else if s.edge_v[edge] == island { neighbor = s.edge_u[edge] }
			if neighbor < s.island_count && !reached[neighbor] {
				reached[neighbor] = true
				stack[top] = neighbor
				top++
			}
		}
	}
	for island in 0 .. s.island_count {
		if !reached[island] { return false }
	}
	return true
}

fn residuals_feasible(s &Solver) bool {
	for island in 0 .. s.island_count {
		if s.residual[island] < 0 || s.residual[island] > i64(2 * s.remaining[island]) { return false }
	}
	return true
}

fn search(mut s Solver, depth int) bool {
	if depth == s.edge_count {
		for island in 0 .. s.island_count {
			if s.residual[island] != 0 { return false }
		}
		if !possible_graph_connected(s, s.edge_count - 1) { return false }
		for edge in 0 .. s.edge_count { s.solution[edge] = s.multiplicity[edge] }
		return true
	}
	u, v := s.edge_u[depth], s.edge_v[depth]
	s.remaining[u]--
	s.remaining[v]--
	for amount in 0 .. 3 {
		if i64(amount) > s.residual[u] || i64(amount) > s.residual[v] { continue }
		mut conflict := false
		if amount != 0 {
			for prior in 0 .. depth {
				if s.multiplicity[prior] != 0 && edges_cross(s, prior, depth) {
					conflict = true
					break
				}
			}
		}
		if conflict { continue }
		s.multiplicity[depth] = amount
		s.residual[u] -= i64(amount)
		s.residual[v] -= i64(amount)
		if residuals_feasible(s) && possible_graph_connected(s, depth) && search(mut s, depth + 1) {
			s.residual[u] += i64(amount)
			s.residual[v] += i64(amount)
			s.remaining[u]++
			s.remaining[v]++
			return true
		}
		s.residual[u] += i64(amount)
		s.residual[v] += i64(amount)
		s.multiplicity[depth] = 0
	}
	s.remaining[u]++
	s.remaining[v]++
	return false
}

@[export: 'hashiwokakero_small_solver']
pub fn hashiwokakero_small_solver(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_input_length { return -1 }
		if input[0] < 2 || input[0] > max_islands { return -1 }
		n := int(input[0])
		if length != usize(1 + 3 * n) { return -1 }
		mut s := Solver{
			island_count: n
		}
		for island in 0 .. n {
			x, y, demand := input[1 + 3 * island], input[2 + 3 * island], input[3 + 3 * island]
			if x < 0 || x > 7 || y < 0 || y > 7 || demand < 1 || demand > 8 { return -1 }
			for prior in 0 .. island {
				if s.x[prior] == x && s.y[prior] == y { return -1 }
			}
			s.x[island] = x
			s.y[island] = y
			s.residual[island] = demand
		}
		for first in 0 .. n {
			for second in first + 1 .. n {
				if s.x[first] != s.x[second] && s.y[first] != s.y[second] { continue }
				mut blocked := false
				for middle in 0 .. n {
					if middle == first || middle == second { continue }
					if s.y[first] == s.y[second] && s.y[middle] == s.y[first] &&
						min(s.x[first], s.x[second]) < s.x[middle] && s.x[middle] < max(s.x[first], s.x[second]) { blocked = true }
					if s.x[first] == s.x[second] && s.x[middle] == s.x[first] &&
						min(s.y[first], s.y[second]) < s.y[middle] && s.y[middle] < max(s.y[first], s.y[second]) { blocked = true }
				}
				if !blocked {
					if s.edge_count == max_edge_slots { return -1 }
					edge := s.edge_count
					s.edge_count++
					s.edge_u[edge] = first
					s.edge_v[edge] = second
					s.remaining[first]++
					s.remaining[second]++
				}
			}
		}
		if !search(mut s, 0) { return -2 }
		mut packed := i64(1) << 32
		for edge in 0 .. s.edge_count { packed |= i64(s.solution[edge]) << (2 * edge) }
		return packed
	}
}
