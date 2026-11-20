package c_connected_clustered_embedding_condition

import "core:c"

N :: 8
M :: 18
F :: 12
INPUT_MAX :: 55

Graph :: struct {
	n, c, m, f, outer_u, outer_v, outer_face: int,
	degree, mask: [N]int,
	edge_u, edge_v: [M]int,
	rotation, face_of: [N][N]int,
	adjacent: [N][N]bool,
}

find_root :: proc "contextless" (parent: ^[F]int, x0: int) -> int {
	x := x0
	for parent[x] != x {
		parent[x] = parent[parent[x]]
		x = parent[x]
	}
	return x
}

connected :: proc "contextless" (g: ^Graph, mask: int) -> bool {
	start, expected := -1, 0
	for v := 0; v < g.n; v += 1 {
		if (mask >> v) & 1 != 0 {
			if start < 0 { start = v }
			expected += 1
		}
	}
	if expected <= 1 { return true }
	seen: [N]bool
	queue: [N]int
	head, tail := 0, 1
	seen[start] = true
	queue[0] = start
	for head < tail {
		u := queue[head]
		head += 1
		for v := 0; v < g.n; v += 1 {
			if (mask >> v) & 1 != 0 && g.adjacent[u][v] && !seen[v] {
				seen[v] = true
				queue[tail] = v
				tail += 1
			}
		}
	}
	return tail == expected
}

parse :: proc "contextless" (input: [^]i64, length: int, g: ^Graph) -> bool {
	if input == nil || length < 4 || length > INPUT_MAX { return false }
	if input[0] < 3 || input[0] > N || input[1] < 0 || input[1] > input[0] - 2 { return false }
	g.n, g.c = int(input[0]), int(input[1])
	if input[2] < 0 || input[2] >= i64(g.n) || input[3] < 0 || input[3] >= i64(g.n) || input[2] == input[3] { return false }
	g.outer_u, g.outer_v = int(input[2]), int(input[3])
	offset, degree_sum := 4, 0
	for u := 0; u < g.n; u += 1 {
		if offset >= length { return false }
		d64 := input[offset]
		offset += 1
		if d64 < 1 || d64 >= i64(g.n) || offset + int(d64) > length { return false }
		d := int(d64)
		g.degree[u] = d
		degree_sum += d
		row_seen: [N]bool
		for i := 0; i < d; i += 1 {
			raw := input[offset]
			offset += 1
			if raw < 0 || raw >= i64(g.n) || raw == i64(u) || row_seen[int(raw)] { return false }
			v := int(raw)
			row_seen[v] = true
			g.rotation[u][i] = v
			g.adjacent[u][v] = true
		}
	}
	if degree_sum % 2 != 0 || offset + g.c != length { return false }
	g.m = degree_sum / 2
	if g.m < g.n - 1 || g.m > M || !g.adjacent[g.outer_u][g.outer_v] { return false }
	edge_count := 0
	for u := 0; u < g.n; u += 1 {
		for v := 0; v < g.n; v += 1 {
			if g.adjacent[u][v] != g.adjacent[v][u] { return false }
			if u < v && g.adjacent[u][v] {
				g.edge_u[edge_count] = u
				g.edge_v[edge_count] = v
				edge_count += 1
			}
		}
	}
	if edge_count != g.m { return false }
	full := (1 << g.n) - 1
	for i := 0; i < g.c; i += 1 {
		raw := input[offset+i]
		if raw <= 0 || raw >= i64(full) { return false }
		mask := int(raw)
		bits := 0
		for v := 0; v < g.n; v += 1 { bits += (mask >> v) & 1 }
		if bits < 2 { return false }
		for j := 0; j < i; j += 1 {
			if g.mask[j] == mask { return false }
			common := g.mask[j] & mask
			if common != 0 && common != g.mask[j] && common != mask { return false }
		}
		g.mask[i] = mask
		if !connected(g, mask) { return false }
	}
	if !connected(g, full) { return false }
	for u := 0; u < N; u += 1 { for v := 0; v < N; v += 1 { g.face_of[u][v] = -1 } }
	g.f = 0
	for e := 0; e < g.m; e += 1 {
		for side := 0; side < 2; side += 1 {
			su := g.edge_u[e]
			sv := g.edge_v[e]
			if side != 0 { su, sv = sv, su }
			if g.face_of[su][sv] >= 0 { continue }
			if g.f >= F { return false }
			local: [N][N]bool
			u, v, steps := su, sv, 0
			for {
				if local[u][v] || g.face_of[u][v] >= 0 { return false }
				local[u][v] = true
				g.face_of[u][v] = g.f
				at := -1
				for i := 0; i < g.degree[v]; i += 1 { if g.rotation[v][i] == u { at = i } }
				if at < 0 { return false }
				next := g.rotation[v][(at+1)%g.degree[v]]
				u, v = v, next
				if u == su && v == sv { break }
				steps += 1
				if steps > 2*g.m { return false }
			}
			g.f += 1
		}
	}
	if g.f != g.m-g.n+2 { return false }
	for u := 0; u < g.n; u += 1 { for v := 0; v < g.n; v += 1 { if g.adjacent[u][v] && g.face_of[u][v] < 0 { return false } } }
	g.outer_face = g.face_of[g.outer_u][g.outer_v]
	return g.outer_face >= 0
}

@(export)
c_connected_clustered_embedding_condition :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > INPUT_MAX { return -1 }
	g: Graph
	if !parse(input, int(length), &g) { return -1 }
	for ci := 0; ci < g.c; ci += 1 {
		parent: [F]int
		for f := 0; f < g.f; f += 1 { parent[f] = f }
	mask := g.mask[ci]
		for e := 0; e < g.m; e += 1 {
			u, v := g.edge_u[e], g.edge_v[e]
			if (mask>>u)&1 != 0 && (mask>>v)&1 != 0 { continue }
			parent[find_root(&parent[0], g.face_of[u][v])] = find_root(&parent[0], g.face_of[v][u])
		}
		outside := find_root(&parent[0], g.outer_face)
		for v := 0; v < g.n; v += 1 { if (mask>>v)&1 == 0 {
			incident := false
			for u := 0; u < g.n; u += 1 { if g.adjacent[v][u] {
				incident = true
				if find_root(&parent[0], g.face_of[v][u]) != outside { return 0 }
			} }
			if !incident { return -1 }
		} }
		for e := 0; e < g.m; e += 1 {
			u, v := g.edge_u[e], g.edge_v[e]
			if (mask>>u)&1 != 0 && (mask>>v)&1 != 0 { continue }
			if find_root(&parent[0], g.face_of[u][v]) != outside { return 0 }
		}
	}
	return 1
}
