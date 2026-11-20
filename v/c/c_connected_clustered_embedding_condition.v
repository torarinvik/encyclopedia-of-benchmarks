module c_connected_clustered_embedding_condition

const max_n = 8
const max_m = 18
const max_f = 12
const max_input = 55

struct Graph {
	n int
	c int
	m int
	f int
	outer_u int
	outer_v int
	outer_face int
	degree [max_n]int
	mask [max_n]int
	rotation [max_n][max_n]int
	face_of [max_n][max_n]int
	adjacent [max_n][max_n]bool
	edge_u [max_m]int
	edge_v [max_m]int
}

fn find_root(parent [max_f]int, start int) int {
	mut x := start
	for parent[x] != x { x = parent[x] }
	return x
}

fn connected(g Graph, mask int) bool {
	mut start := -1
	mut expected := 0
	for v in 0 .. g.n {
		if (mask >> v) & 1 != 0 {
			if start < 0 { start = v }
			expected++
		}
	}
	if expected <= 1 { return true }
	mut seen := [max_n]bool{}
	mut queue := [max_n]int{}
	mut head := 0
	mut tail := 1
	seen[start] = true
	queue[0] = start
	for head < tail {
		u := queue[head]
		head++
		for v in 0 .. g.n {
			if (mask >> v) & 1 != 0 && g.adjacent[u][v] && !seen[v] {
				seen[v] = true
				queue[tail] = v
				tail++
			}
		}
	}
	return tail == expected
}

fn parse(input &i64, length usize) ?Graph {
	if unsafe { input == nil } || length < 4 || length > max_input { return none }
	n_raw := unsafe { input[0] }
	c_raw := unsafe { input[1] }
	if n_raw < 3 || n_raw > max_n || c_raw < 0 || c_raw > n_raw - 2 { return none }
	mut g := Graph{n: int(n_raw), c: int(c_raw)}
	u_raw := unsafe { input[2] }
	v_raw := unsafe { input[3] }
	if u_raw < 0 || u_raw >= n_raw || v_raw < 0 || v_raw >= n_raw || u_raw == v_raw { return none }
	g.outer_u = int(u_raw)
	g.outer_v = int(v_raw)
	mut offset := usize(4)
	mut degree_sum := 0
	for u in 0 .. g.n {
		if offset >= length { return none }
		d_raw := unsafe { input[offset] }
		offset++
		if d_raw < 1 || d_raw >= n_raw || offset + usize(d_raw) > length { return none }
		d := int(d_raw)
		g.degree[u] = d
		degree_sum += d
		mut row_seen := [max_n]bool{}
		for i in 0 .. d {
			raw := unsafe { input[offset] }
			offset++
			if raw < 0 || raw >= n_raw || raw == i64(u) { return none }
			v := int(raw)
			if row_seen[v] { return none }
			row_seen[v] = true
			g.rotation[u][i] = v
			g.adjacent[u][v] = true
		}
	}
	if degree_sum % 2 != 0 || offset + usize(g.c) != length { return none }
	g.m = degree_sum / 2
	if g.m < g.n - 1 || g.m > max_m || !g.adjacent[g.outer_u][g.outer_v] { return none }
	mut edge_count := 0
	for u in 0 .. g.n {
		for v in 0 .. g.n {
			if g.adjacent[u][v] != g.adjacent[v][u] { return none }
			if u < v && g.adjacent[u][v] {
				g.edge_u[edge_count] = u
				g.edge_v[edge_count] = v
				edge_count++
			}
		}
	}
	if edge_count != g.m { return none }
	full := (1 << g.n) - 1
	for i in 0 .. g.c {
		raw := unsafe { input[offset + usize(i)] }
		if raw <= 0 || raw >= i64(full) { return none }
		mask := int(raw)
		mut bits := 0
		for v in 0 .. g.n { bits += (mask >> v) & 1 }
		if bits < 2 { return none }
		for j in 0 .. i {
			if g.mask[j] == mask { return none }
			common := g.mask[j] & mask
			if common != 0 && common != g.mask[j] && common != mask { return none }
		}
		g.mask[i] = mask
		if !connected(g, mask) { return none }
	}
	if !connected(g, full) { return none }
	for u in 0 .. max_n { for v in 0 .. max_n { g.face_of[u][v] = -1 } }
	g.f = 0
	for e in 0 .. g.m {
		for side in 0 .. 2 {
			su := if side == 0 { g.edge_u[e] } else { g.edge_v[e] }
			sv := if side == 0 { g.edge_v[e] } else { g.edge_u[e] }
			if g.face_of[su][sv] >= 0 { continue }
			if g.f >= max_f { return none }
			mut local := [max_n][max_n]bool{}
			mut u := su
			mut v := sv
			mut steps := 0
			for {
				if local[u][v] || g.face_of[u][v] >= 0 { return none }
				local[u][v] = true
				g.face_of[u][v] = g.f
				mut at := -1
				for i in 0 .. g.degree[v] { if g.rotation[v][i] == u { at = i } }
				if at < 0 { return none }
				next := g.rotation[v][(at + 1) % g.degree[v]]
				u = v
				v = next
				if u == su && v == sv { break }
				steps++
				if steps > 2 * g.m { return none }
			}
			g.f++
		}
	}
	if g.f != g.m - g.n + 2 { return none }
	for u in 0 .. g.n { for v in 0 .. g.n { if g.adjacent[u][v] && g.face_of[u][v] < 0 { return none } } }
	g.outer_face = g.face_of[g.outer_u][g.outer_v]
	return g
}

fn solve(g Graph) i64 {
	for ci in 0 .. g.c {
		mask := g.mask[ci]
		mut parent := [max_f]int{}
		for f in 0 .. g.f { parent[f] = f }
		for e in 0 .. g.m {
			u := g.edge_u[e]
			v := g.edge_v[e]
			if (mask >> u) & 1 != 0 && (mask >> v) & 1 != 0 { continue }
			a := find_root(parent, g.face_of[u][v])
			b := find_root(parent, g.face_of[v][u])
			parent[a] = b
		}
		outside := find_root(parent, g.outer_face)
		for v in 0 .. g.n {
			if (mask >> v) & 1 != 0 { continue }
			mut incident := false
			for u in 0 .. g.n {
				if g.adjacent[v][u] {
					incident = true
					if find_root(parent, g.face_of[v][u]) != outside { return 0 }
				}
			}
			if !incident { return -1 }
		}
		for e in 0 .. g.m {
			u := g.edge_u[e]
			v := g.edge_v[e]
			if (mask >> u) & 1 != 0 && (mask >> v) & 1 != 0 { continue }
			if find_root(parent, g.face_of[u][v]) != outside { return 0 }
		}
	}
	return 1
}

@[export: 'c_connected_clustered_embedding_condition']
pub fn c_connected_clustered_embedding_condition(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 4 || length > max_input { return -1 }
	mut g := parse(input, length)
	if g == none { return -1 }
	return solve(g)
}
