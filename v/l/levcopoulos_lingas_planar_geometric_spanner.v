module levcopoulos_lingas_planar_geometric_spanner

import math

const max_n = 8
const max_edges = 18
const max_faces = 16
const max_darts = 2 * (max_n - 1)
const max_stack = 64
const max_input = 55

struct SpannerState {
mut:
	x [max_n]i64
	y [max_n]i64
	edge_u [max_edges]int
	edge_v [max_edges]int
	edge_count int
	face_a [max_faces]int
	face_b [max_faces]int
	face_c [max_faces]int
	face_count int
	rotation [max_n][max_n]int
	degree [max_n]int
	tree_rotation [max_n][max_n]int
	tree_degree [max_n]int
	contour [max_darts][2]int
	contour_len int
	stack [max_stack][2]int
	stack_len int
	weight [max_n][max_n]f64
	hull [max_n]bool
	tree [max_n][max_n]bool
	kept [max_n][max_n]bool
}

fn orient(s &SpannerState, a int, b int, c int) i64 {
	return (s.x[b] - s.x[a]) * (s.y[c] - s.y[a]) - (s.y[b] - s.y[a]) * (s.x[c] - s.x[a])
}

fn incircle(s &SpannerState, a int, b int, c int, p int) i64 {
	ax := s.x[a] - s.x[p]
	ay := s.y[a] - s.y[p]
	bx := s.x[b] - s.x[p]
	by := s.y[b] - s.y[p]
	cx := s.x[c] - s.x[p]
	cy := s.y[c] - s.y[p]
	det := (ax * ax + ay * ay) * (bx * cy - by * cx) - (bx * bx + by * by) * (ax * cy - ay * cx) + (cx * cx + cy * cy) * (ax * by - ay * bx)
	return if orient(s, a, b, c) > 0 { det } else { -det }
}

fn dist2(s &SpannerState, a int, b int) i64 {
	dx := s.x[a] - s.x[b]
	dy := s.y[a] - s.y[b]
	return dx * dx + dy * dy
}

fn sorted3(a0 int, b0 int, c0 int) (int, int, int) {
	mut a := a0
	mut b := b0
	mut c := c0
	if a > b { t := a; a = b; b = t }
	if b > c { t := b; b = c; c = t }
	if a > b { t := a; a = b; b = t }
	return a, b, c
}

fn is_face(s &SpannerState, a0 int, b0 int, c0 int) bool {
	a, b, c := sorted3(a0, b0, c0)
	for i in 0 .. s.face_count {
		if s.face_a[i] == a && s.face_b[i] == b && s.face_c[i] == c { return true }
	}
	return false
}

fn angle_less(s &SpannerState, origin int, a int, b int) bool {
	ax := s.x[a] - s.x[origin]
	ay := s.y[a] - s.y[origin]
	bx := s.x[b] - s.x[origin]
	by := s.y[b] - s.y[origin]
	ah := if ay > 0 || (ay == 0 && ax >= 0) { 0 } else { 1 }
	bh := if by > 0 || (by == 0 && bx >= 0) { 0 } else { 1 }
	if ah != bh { return ah < bh }
	cross := ax * by - ay * bx
	if cross != 0 { return cross > 0 }
	return a < b
}

fn sort_rotation(mut s SpannerState, v int) {
	for i in 1 .. s.degree[v] {
		key := s.rotation[v][i]
		mut j := i
		for j > 0 && angle_less(&s, v, key, s.rotation[v][j - 1]) {
			s.rotation[v][j] = s.rotation[v][j - 1]
			j--
		}
		s.rotation[v][j] = key
	}
}

fn sort_tree_rotation(mut s SpannerState, v int) {
	for i in 1 .. s.tree_degree[v] {
		key := s.tree_rotation[v][i]
		mut j := i
		for j > 0 && angle_less(&s, v, key, s.tree_rotation[v][j - 1]) {
			s.tree_rotation[v][j] = s.tree_rotation[v][j - 1]
			j--
		}
		s.tree_rotation[v][j] = key
	}
}

fn cw_next(s &SpannerState, u int, v int) (int, int, bool) {
	for i in 0 .. s.degree[v] {
		if s.rotation[v][i] == u {
			return v, s.rotation[v][(i + s.degree[v] - 1) % s.degree[v]], true
		}
	}
	return 0, 0, false
}

fn cw_tree_next(s &SpannerState, u int, v int) (int, int, bool) {
	for i in 0 .. s.tree_degree[v] {
		if s.tree_rotation[v][i] == u {
			return v, s.tree_rotation[v][(i + s.tree_degree[v] - 1) % s.tree_degree[v]], true
		}
	}
	return 0, 0, false
}

fn contour_find(s &SpannerState, u int, v int) int {
	for i in 0 .. s.contour_len { if s.contour[i][0] == u && s.contour[i][1] == v { return i } }
	return -1
}

fn canonicalize(mut s SpannerState) {
	if s.contour_len == 0 { return }
	mut first := 0
	for i in 1 .. s.contour_len {
		if s.contour[i][0] < s.contour[first][0] || (s.contour[i][0] == s.contour[first][0] && s.contour[i][1] < s.contour[first][1]) { first = i }
	}
	mut rotated := [max_darts][2]int{}
	for i in 0 .. s.contour_len { rotated[i] = s.contour[(first + i) % s.contour_len] }
	s.contour = rotated
}

fn eligible(s &SpannerState, u int, v int) bool {
	i := contour_find(s, u, v)
	if i < 0 || s.hull[v] || s.contour_len < 3 { return false }
	next := (i + 1) % s.contour_len
	cw_u, cw_v, ok := cw_next(s, u, v)
	return ok && s.contour[next][0] == cw_u && s.contour[next][1] == cw_v && is_face(s, u, v, cw_v)
}

fn push_candidate(mut s SpannerState, u int, v int) bool {
	if !eligible(&s, u, v) { return true }
	if s.stack_len >= max_stack { return false }
	s.stack[s.stack_len][0] = u
	s.stack[s.stack_len][1] = v
	s.stack_len++
	return true
}

fn parse(mut s SpannerState, input &i64, length usize) int {
	if unsafe { input == nil } || length < 14 || length > max_input { return -1 }
	n_value := unsafe { input[0] }
	if n_value < 3 || n_value > max_n { return -1 }
	n := int(n_value)
	m_at := 1 + 2 * n
	if int(length) <= m_at { return -1 }
	m_value := unsafe { input[m_at] }
	if m_value < 3 || m_value > max_edges || int(length) != m_at + 1 + 2 * int(m_value) { return -1 }
	m := int(m_value)
	for i in 0 .. n {
		s.x[i] = unsafe { input[1 + 2 * i] }
		s.y[i] = unsafe { input[2 + 2 * i] }
		if s.x[i] < -10 || s.x[i] > 10 || s.y[i] < -10 || s.y[i] > 10 { return -1 }
		for j in 0 .. i { if s.x[i] == s.x[j] && s.y[i] == s.y[j] { return -1 } }
	}
	for a in 0 .. n { for b in a + 1 .. n { for c in b + 1 .. n { if orient(&s, a, b, c) == 0 { return -1 } } } }
	for a in 0 .. n { for b in a + 1 .. n { for c in b + 1 .. n { for d in c + 1 .. n { if incircle(&s, a, b, c, d) == 0 { return -1 } } } } }
	s.edge_count = m
	mut supplied := [max_n][max_n]bool{}
	for i in 0 .. m {
		u_value := unsafe { input[m_at + 1 + 2 * i] }
		v_value := unsafe { input[m_at + 2 + 2 * i] }
		if u_value < 0 || v_value <= u_value || v_value >= n_value { return -1 }
		u := int(u_value); v := int(v_value)
		if i > 0 && (u < s.edge_u[i - 1] || (u == s.edge_u[i - 1] && v <= s.edge_v[i - 1])) { return -1 }
		s.edge_u[i] = u; s.edge_v[i] = v
		supplied[u][v] = true; supplied[v][u] = true
	}
	mut expected := [max_n][max_n]bool{}
	for a in 0 .. n { for b in a + 1 .. n { for c in b + 1 .. n {
		mut aa := a; mut bb := b; mut cc := c
		if orient(&s, aa, bb, cc) < 0 { t := bb; bb = cc; cc = t }
		mut empty := true
		for p in 0 .. n { if p != aa && p != bb && p != cc && incircle(&s, aa, bb, cc, p) > 0 { empty = false } }
		if empty {
			if s.face_count >= max_faces { return -1 }
			fa, fb, fc := sorted3(a, b, c)
			s.face_a[s.face_count] = fa; s.face_b[s.face_count] = fb; s.face_c[s.face_count] = fc; s.face_count++
		expected[a][b] = true; expected[b][a] = true
		expected[b][c] = true; expected[c][b] = true
		expected[a][c] = true; expected[c][a] = true
		}
	} } }
	for a in 0 .. n { for b in a + 1 .. n { if supplied[a][b] != expected[a][b] { return -1 } } }
	for a in 0 .. n { for b in a + 1 .. n {
		mut positive := false; mut negative := false
		for p in 0 .. n { if p != a && p != b { side := orient(&s, a, b, p); if side > 0 { positive = true }; if side < 0 { negative = true } } }
		if !(positive && negative) { s.hull[a] = true; s.hull[b] = true }
	} }
	for i in 0 .. m {
		u := s.edge_u[i]; v := s.edge_v[i]
		s.rotation[u][s.degree[u]] = v; s.degree[u]++
		s.rotation[v][s.degree[v]] = u; s.degree[v]++
	}
	for v in 0 .. n { sort_rotation(mut s, v) }
	return n
}

fn build_mst_contour(mut s SpannerState, n int) bool {
	mut order := [max_edges]int{}
	for i in 0 .. s.edge_count { order[i] = i }
	for i in 1 .. s.edge_count {
		key := order[i]; mut j := i
		for j > 0 {
			prev := order[j - 1]
			pl := dist2(&s, s.edge_u[prev], s.edge_v[prev]); kl := dist2(&s, s.edge_u[key], s.edge_v[key])
			if pl < kl || (pl == kl && (s.edge_u[prev] < s.edge_u[key] || (s.edge_u[prev] == s.edge_u[key] && s.edge_v[prev] <= s.edge_v[key]))) { break }
			order[j] = prev; j--
		}
		order[j] = key
	}
	mut parent := [max_n]int{}
	mut size := [max_n]int{}
	for i in 0 .. n { parent[i] = i; size[i] = 1 }
	mut chosen := 0
	for rank in 0 .. s.edge_count {
		e := order[rank]; u := s.edge_u[e]; v := s.edge_v[e]
		mut a := u; mut b := v
		for parent[a] != a { parent[a] = parent[parent[a]]; a = parent[a] }
		for parent[b] != b { parent[b] = parent[parent[b]]; b = parent[b] }
		if a == b { continue }
		if size[a] < size[b] { t := a; a = b; b = t }
		parent[b] = a; size[a] += size[b]
		s.tree[u][v] = true; s.tree[v][u] = true; s.kept[u][v] = true; s.kept[v][u] = true
		s.tree_rotation[u][s.tree_degree[u]] = v; s.tree_degree[u]++
		s.tree_rotation[v][s.tree_degree[v]] = u; s.tree_degree[v]++
		chosen++
	}
	if chosen != n - 1 { return false }
	for v in 0 .. n { sort_tree_rotation(mut s, v) }
	for i in 0 .. s.edge_count { u := s.edge_u[i]; v := s.edge_v[i]; w := math.sqrt(f64(dist2(&s, u, v))); s.weight[u][v] = w; s.weight[v][u] = w }
	mut first_u := max_n; mut first_v := max_n
	for u in 0 .. n { for v in 0 .. n { if s.tree[u][v] && (u < first_u || (u == first_u && v < first_v)) { first_u = u; first_v = v } } }
	if first_u == max_n { return false }
	s.contour[0][0] = first_u; s.contour[0][1] = first_v; s.contour_len = 1
	expected := 2 * (n - 1)
	for s.contour_len < expected {
		last := s.contour_len - 1
		next_u, next_v, ok := cw_tree_next(&s, s.contour[last][0], s.contour[last][1])
		if !ok { return false }
		if next_u == first_u && next_v == first_v { break }
		for i in 0 .. s.contour_len { if s.contour[i][0] == next_u && s.contour[i][1] == next_v { return false } }
		s.contour[s.contour_len][0] = next_u; s.contour[s.contour_len][1] = next_v; s.contour_len++
	}
	if s.contour_len != expected { return false }
	last := s.contour_len - 1
	close_u, close_v, ok := cw_tree_next(&s, s.contour[last][0], s.contour[last][1])
	return ok && close_u == first_u && close_v == first_v
}

fn run_algorithm(mut s SpannerState, n int) (int, int, bool) {
	for i in 0 .. s.contour_len { if !push_candidate(mut s, s.contour[i][0], s.contour[i][1]) { return 0, 0, false } }
	mut absorbed := 0; mut steps := 0
	for s.stack_len > 0 && steps < 2 * max_edges {
		s.stack_len--; v := s.stack[s.stack_len][0]; w := s.stack[s.stack_len][1]
		if !eligible(&s, v, w) { continue }
		at := contour_find(&s, v, w); if at < 0 { return 0, 0, false }
		next_at := (at + 1) % s.contour_len; u := s.contour[next_at][1]
		path_weight := s.weight[v][w] + s.weight[w][u]
		chord_length := math.sqrt(f64(dist2(&s, v, u)))
		if path_weight > 2.0 * chord_length { s.kept[v][u] = true; s.kept[u][v] = true } else { s.weight[v][u] = path_weight }
		if next_at == 0 {
			for i in 0 .. s.contour_len - 1 { s.contour[i] = s.contour[i + 1] }
			s.contour_len--; s.contour[s.contour_len - 1][0] = v; s.contour[s.contour_len - 1][1] = u
		} else {
			s.contour[at][0] = v; s.contour[at][1] = u
			for i in next_at .. s.contour_len - 1 { s.contour[i] = s.contour[i + 1] }
			s.contour_len--
		}
		canonicalize(mut s); absorbed++; steps++
		chord_at := contour_find(&s, v, u); if chord_at < 0 { return 0, 0, false }
		if !push_candidate(mut s, v, u) { return 0, 0, false }
		left_at := (chord_at + s.contour_len - 1) % s.contour_len
		if !push_candidate(mut s, s.contour[left_at][0], s.contour[left_at][1]) { return 0, 0, false }
	}
	if steps >= 2 * max_edges && s.stack_len > 0 { return 0, 0, false }
	mut shortcuts := 0
	for u in 0 .. n { for v in u + 1 .. n { if s.kept[u][v] && !s.tree[u][v] { shortcuts++ } } }
	return absorbed, shortcuts, true
}

@[export: 'levcopoulos_lingas_planar_geometric_spanner']
pub fn levcopoulos_lingas_planar_geometric_spanner(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 14 || length > max_input { return -1 }
	mut s := SpannerState{}
	n := parse(mut s, input, length)
	if n < 0 || !build_mst_contour(mut s, n) { return -1 }
	absorbed, shortcuts, ok := run_algorithm(mut s, n)
	if !ok { return -1 }
	mut words := [3 + 2 * max_edges]i64{}
	words[0] = i64(absorbed); words[1] = i64(shortcuts)
	mut count := 3
	for u in 0 .. n { for v in u + 1 .. n { if s.kept[u][v] { words[count] = i64(u); words[count + 1] = i64(v); words[2]++; count += 2 } } }
	bytes := count * 8
	if unsafe { output == nil } || capacity < usize(bytes) { return -2 }
	for i in 0 .. count {
		bits := u64(words[i])
		for b in 0 .. 8 { unsafe { output[8 * i + b] = u8((bits >> (8 * b)) & 255) } }
	}
	return i64(bytes)
}
