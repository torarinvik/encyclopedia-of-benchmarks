package symmetric_drawing_cyclic_wedge

import "core:c"

N :: 8
M :: 18
F :: 12
INPUT_MAX :: 55
OUTPUT_MAX :: 128

Graph :: struct {
	n, k, b, m, f, center, outer_id: int,
	outer: [N]int,
	degree: [N]int,
	rotation: [N][N]int,
	permutation: [N]int,
	adjacent: [N][N]bool,
	edge_u: [M]int,
	edge_v: [M]int,
	face_len: [F]int,
	face: [F][N]int,
	dart_face: [N][N]int,
}

connected_without :: proc "contextless" (g: ^Graph, removed_a, removed_b: int) -> bool {
	start := -1
	expected := 0
	for v := 0; v < g.n; v += 1 {
		if v == removed_a || v == removed_b { continue }
		if start < 0 { start = v }
		expected += 1
	}
	if expected <= 1 { return true }
	seen: [N]bool
	stack: [N]int
	top, count := 1, 0
	seen[start] = true
	stack[0] = start
	for top > 0 {
		top -= 1
		u := stack[top]
		count += 1
		for v := 0; v < g.n; v += 1 {
			if v != removed_a && v != removed_b && g.adjacent[u][v] && !seen[v] {
				seen[v] = true
				stack[top] = v
				top += 1
			}
		}
	}
	return count == expected
}

face_walk :: proc "contextless" (g: ^Graph, first, second: int, cycle: ^[2 * M]int) -> int {
	seen: [N][N]bool
	u, v, length := first, second, 0
	for step := 0; step < 2*g.m; step += 1 {
		if !g.adjacent[u][v] || seen[u][v] { return -1 }
		seen[u][v] = true
		cycle[length] = u
		length += 1
		at := -1
		for i := 0; i < g.degree[v]; i += 1 { if g.rotation[v][i] == u { at = i } }
		if at < 0 { return -1 }
		next := g.rotation[v][(at + 1) % g.degree[v]]
		u, v = v, next
		if u == first && v == second { return length }
	}
	return -1
}

cyclic_equal :: proc "contextless" (a, b: ^[N]int, length: int) -> bool {
	for shift := 0; shift < length; shift += 1 {
		equal := true
		for i := 0; i < length; i += 1 { if a[i] != b[(i + shift) % length] { equal = false } }
		if equal { return true }
	}
	return false
}

parse :: proc "contextless" (input: [^]i64, length: int, g: ^Graph) -> bool {
	if input == nil || length < 3 || length > INPUT_MAX { return false }
	if input[0] < 4 || input[0] > N || input[1] < 3 || input[1] > N ||
		(input[0] - 1) % input[1] != 0 || input[2] < input[1] || input[2] > input[0] || input[2] % input[1] != 0 { return false }
	g.n, g.k, g.b = int(input[0]), int(input[1]), int(input[2])
	offset := 3
	if offset + g.b > length { return false }
	outer_seen: [N]bool
	for i := 0; i < g.b; i += 1 {
		raw := input[offset]
		offset += 1
		if raw < 0 || raw >= i64(g.n) || outer_seen[int(raw)] { return false }
		g.outer[i] = int(raw)
		outer_seen[int(raw)] = true
	}
	degree_sum := 0
	for u := 0; u < g.n; u += 1 {
		if offset >= length { return false }
		degree_raw := input[offset]
		offset += 1
		if degree_raw < 3 || degree_raw >= i64(g.n) || offset + int(degree_raw) > length { return false }
		d := int(degree_raw)
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
	if offset + g.n != length || degree_sum % 2 != 0 { return false }
	perm_seen: [N]bool
	for u := 0; u < g.n; u += 1 {
		raw := input[offset]
		offset += 1
		if raw < 0 || raw >= i64(g.n) || perm_seen[int(raw)] { return false }
		g.permutation[u] = int(raw)
		perm_seen[int(raw)] = true
	}
	g.m = degree_sum / 2
	if g.m < g.n || g.m > 3*g.n-6 || g.m > M { return false }
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
	if edge_count != g.m || !connected_without(g, -1, -1) { return false }
	for u := 0; u < g.n; u += 1 {
		if !connected_without(g, u, -1) { return false }
		for v := u+1; v < g.n; v += 1 { if !connected_without(g, u, v) { return false } }
	}
	for u := 0; u < N; u += 1 { for v := 0; v < N; v += 1 { g.dart_face[u][v] = -1 } }
	for e := 0; e < g.m; e += 1 {
		for direction := 0; direction < 2; direction += 1 {
			u, v := g.edge_u[e], g.edge_v[e]
			if direction == 1 { u, v = v, u }
			if g.dart_face[u][v] >= 0 { continue }
			if g.f >= F { return false }
			cycle: [2 * M]int
			face_length := face_walk(g, u, v, &cycle)
			if face_length < 3 || face_length > g.n { return false }
			face_seen: [N]bool
			for i := 0; i < face_length; i += 1 {
				a, b := cycle[i], cycle[(i+1)%face_length]
				if face_seen[a] || g.dart_face[a][b] >= 0 { return false }
				face_seen[a] = true
			}
			for i := 0; i < face_length; i += 1 {
				a, b := cycle[i], cycle[(i+1)%face_length]
				g.face[g.f][i] = a
				g.dart_face[a][b] = g.f
			}
			g.face_len[g.f] = face_length
			g.f += 1
		}
	}
	if g.f != g.m-g.n+2 { return false }
	g.outer_id = -1
	for f := 0; f < g.f; f += 1 {
		if g.face_len[f] == g.b && cyclic_equal(&g.outer, &g.face[f], g.b) { g.outer_id = f }
	}
	if g.outer_id < 0 { return false }
	fixed_count := 0
	for v := 0; v < g.n; v += 1 { if g.permutation[v] == v { g.center = v; fixed_count += 1 } }
	if fixed_count != 1 || outer_seen[g.center] { return false }
	for v := 0; v < g.n; v += 1 {
		if v == g.center { continue }
		current, orbit_length := g.permutation[v], 1
		for current != v && orbit_length <= g.k { current = g.permutation[current]; orbit_length += 1 }
		if current != v || orbit_length != g.k { return false }
	}
	power: [N]int
	for v := 0; v < g.n; v += 1 { power[v] = v }
	for step := 1; step <= g.k; step += 1 {
		next: [N]int
		identity := true
		for v := 0; v < g.n; v += 1 { next[v] = g.permutation[power[v]]; if next[v] != v { identity = false } }
		if identity != (step == g.k) { return false }
		power = next
	}
	for u := 0; u < g.n; u += 1 {
		image := g.permutation[u]
		for v := 0; v < g.n; v += 1 { if g.adjacent[u][v] != g.adjacent[image][g.permutation[v]] { return false } }
		row_ok := false
		for shift := 0; shift < g.degree[image]; shift += 1 {
			equal := true
			for i := 0; i < g.degree[u]; i += 1 {
				if g.permutation[g.rotation[u][i]] != g.rotation[image][(i+shift)%g.degree[image]] { equal = false }
			}
			if equal { row_ok = true }
		}
		if !row_ok { return false }
	}
	shift := g.b / g.k
	for i := 0; i < g.b; i += 1 { if g.permutation[g.outer[i]] != g.outer[(i+shift)%g.b] { return false } }
	return true
}

solve :: proc "contextless" (g: ^Graph, words: ^[29]i64) -> int {
	distance: [N]int
	for v := 0; v < N; v += 1 { distance[v] = -1 }
	queue: [N]int
	head, tail := 0, 1
	distance[g.center] = 0
	queue[0] = g.center
	for head < tail {
		u := queue[head]
		head += 1
		for v := 0; v < g.n; v += 1 { if g.adjacent[u][v] && distance[v] < 0 { distance[v] = distance[u]+1; queue[tail] = v; tail += 1 } }
	}
	endpoint := -1
	for i := 0; i < g.b; i += 1 {
		v := g.outer[i]
		if endpoint < 0 || distance[v] < distance[endpoint] || (distance[v] == distance[endpoint] && v < endpoint) { endpoint = v }
	}
	if endpoint < 0 || distance[endpoint] <= 0 { return -1 }
	to_end: [N]int
	for v := 0; v < N; v += 1 { to_end[v] = -1 }
	head, tail = 0, 1
	to_end[endpoint] = 0
	queue[0] = endpoint
	for head < tail {
		u := queue[head]
		head += 1
		for v := 0; v < g.n; v += 1 { if g.adjacent[u][v] && to_end[v] < 0 { to_end[v] = to_end[u]+1; queue[tail] = v; tail += 1 } }
	}
	p1, p2, p0: [N]int
	p1_len := 1
	p1[0] = g.center
	for p1[p1_len-1] != endpoint && p1_len < N {
		u, choice := p1[p1_len-1], -1
		for v := 0; v < g.n; v += 1 { if g.adjacent[u][v] && to_end[v] == to_end[u]-1 && (choice < 0 || v < choice) { choice = v } }
		if choice < 0 { return -1 }
		p1[p1_len] = choice
		p1_len += 1
	}
	if p1[p1_len-1] != endpoint || p1_len-1 != distance[endpoint] { return -1 }
	for i := 0; i < p1_len; i += 1 { p2[i] = g.permutation[p1[i]] }
	endpoint2 := p2[p1_len-1]
	if endpoint2 == endpoint { return -1 }
	for i := 1; i < p1_len; i += 1 { for j := 1; j < p1_len; j += 1 { if p1[i] == p2[j] { return -1 } } }
	for i := 1; i+1 < p1_len; i += 1 { for j := 0; j < g.b; j += 1 { if p1[i] == g.outer[j] || p2[i] == g.outer[j] { return -1 } } }
	start := -1
	for i := 0; i < g.b; i += 1 { if g.outer[i] == endpoint { start = i } }
	if start < 0 { return -1 }
	p0_len := g.b/g.k+1
	for i := 0; i < p0_len; i += 1 { p0[i] = g.outer[(start+i)%g.b] }
	if p0[p0_len-1] != endpoint2 { return -1 }
	cycle: [3*N]int
	cycle_len := 0
	for i := 0; i < p1_len; i += 1 { cycle[cycle_len] = p1[i]; cycle_len += 1 }
	for i := 1; i < p0_len; i += 1 { cycle[cycle_len] = p0[i]; cycle_len += 1 }
	for i := p1_len-1; i > 0; i -= 1 { cycle[cycle_len] = p2[i-1]; cycle_len += 1 }
	if cycle[0] != g.center || cycle[cycle_len-1] != g.center { return -1 }
	cycle_vertex: [N]bool
	cut: [N][N]bool
	for i := 0; i+1 < cycle_len; i += 1 {
		u, v := cycle[i], cycle[i+1]
		if !g.adjacent[u][v] || cycle_vertex[u] { return -1 }
		cycle_vertex[u] = true
		cut[u][v], cut[v][u] = true, true
	}
	seed := g.dart_face[p0[1]][p0[0]]
	if seed < 0 || seed == g.outer_id { return -1 }
	dual: [F][F]bool
	inside: [F]bool
	for e := 0; e < g.m; e += 1 {
		u, v := g.edge_u[e], g.edge_v[e]
		if cut[u][v] { continue }
		a, b := g.dart_face[u][v], g.dart_face[v][u]
		dual[a][b], dual[b][a] = true, true
	}
	head, tail = 0, 1
	queue[0] = seed
	inside[seed] = true
	for head < tail {
		face := queue[head]
		head += 1
		for other := 0; other < g.f; other += 1 { if dual[face][other] && !inside[other] { inside[other] = true; queue[tail] = other; tail += 1 } }
	}
	if inside[g.outer_id] { return -1 }
	vertices := cycle_vertex
	for f := 0; f < g.f; f += 1 { if inside[f] { for i := 0; i < g.face_len[f]; i += 1 { vertices[g.face[f][i]] = true } } }
	vertex_mask, edge_mask := i64(0), i64(0)
	for v := 0; v < g.n; v += 1 { if vertices[v] { vertex_mask |= 1 << v } }
	for e := 0; e < g.m; e += 1 { if vertices[g.edge_u[e]] && vertices[g.edge_v[e]] { edge_mask |= 1 << e } }
	count := 0
	words[count] = i64(p1_len); count += 1
	for i := 0; i < p1_len; i += 1 { words[count] = i64(p1[i]); count += 1 }
	words[count] = i64(p1_len); count += 1
	for i := 0; i < p1_len; i += 1 { words[count] = i64(p2[i]); count += 1 }
	words[count] = i64(p0_len); count += 1
	for i := 0; i < p0_len; i += 1 { words[count] = i64(p0[i]); count += 1 }
	words[count], words[count+1] = vertex_mask, edge_mask
	return count + 2
}

write_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for i := 0; i < 8; i += 1 { output[offset+i] = u8(bits >> (8*i)) }
}

@(export)
symmetric_drawing_cyclic_wedge :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 3 || input_length > INPUT_MAX { return -1 }
	g: Graph
	if !parse(input, int(input_length), &g) { return -1 }
	words: [29]i64
	count := solve(&g, &words)
	if count < 0 || count*8 > OUTPUT_MAX { return -1 }
	bytes := c.size_t(count*8)
	if output == nil || output_capacity < bytes { return -2 }
	temporary: [OUTPUT_MAX]u8
	for i := 0; i < count; i += 1 { write_i64_le(&temporary[0], i*8, words[i]) }
	for i := c.size_t(0); i < bytes; i += 1 { output[i] = temporary[i] }
	return i64(bytes)
}
