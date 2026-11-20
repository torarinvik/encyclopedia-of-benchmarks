module symmetric_drawing_cyclic_wedge

const max_n = 8
const max_m = 18
const max_f = 12
const max_input = 55
const max_output = 128

struct Graph {
	n int
	k int
	b int
	m int
	f int
	center int
	outer_id int
	outer [max_n]int
	degree [max_n]int
	rotation [max_n][max_n]int
	permutation [max_n]int
	adjacent [max_n][max_n]bool
	edge_u [max_m]int
	edge_v [max_m]int
	face_len [max_f]int
	face [max_f][max_n]int
	dart_face [max_n][max_n]int
}

fn connected_without(g &Graph, removed_a int, removed_b int) bool {
	mut start := -1
	mut expected := 0
	for v in 0 .. g.n {
		if v == removed_a || v == removed_b { continue }
		if start < 0 { start = v }
		expected++
	}
	if expected <= 1 { return true }
	mut seen := [max_n]bool{}
	mut stack := [max_n]int{}
	mut top := 1
	mut count := 0
	seen[start] = true
	stack[0] = start
	for top > 0 {
		top--
		u := stack[top]
		count++
		for v in 0 .. g.n {
			if v != removed_a && v != removed_b && g.adjacent[u][v] && !seen[v] {
				seen[v] = true
				stack[top] = v
				top++
			}
		}
	}
	return count == expected
}

fn face_walk(g &Graph, first int, second int, mut cycle []int) int {
	mut seen := [][]bool{len: max_n, init: []bool{len: max_n}}
	mut u := first
	mut v := second
	mut length := 0
	for _ in 0 .. 2 * g.m {
		if !g.adjacent[u][v] || seen[u][v] { return -1 }
		seen[u][v] = true
		cycle[length] = u
		length++
		mut at := -1
		for i in 0 .. g.degree[v] { if g.rotation[v][i] == u { at = i } }
		if at < 0 { return -1 }
		next := g.rotation[v][(at + 1) % g.degree[v]]
		u = v
		v = next
		if u == first && v == second { return length }
	}
	return -1
}

fn same_cycle(a []int, b []int, length int) bool {
	for shift in 0 .. length {
		mut equal := true
		for i in 0 .. length { if a[i] != b[(i + shift) % length] { equal = false } }
		if equal { return true }
	}
	return false
}

fn parse(input &i64, length usize) ?Graph {
	if unsafe { input == nil } || length < 3 || length > max_input { return none }
	n_raw := unsafe { input[0] }
	k_raw := unsafe { input[1] }
	b_raw := unsafe { input[2] }
	if n_raw < 4 || n_raw > max_n || k_raw < 3 || k_raw > max_n ||
		(n_raw - 1) % k_raw != 0 || b_raw < k_raw || b_raw > n_raw || b_raw % k_raw != 0 { return none }
	n, k, b := int(n_raw), int(k_raw), int(b_raw)
	mut g := Graph{n: n, k: k, b: b}
	mut offset := usize(3)
	if offset + usize(b) > length { return none }
	mut outer_seen := [max_n]bool{}
	for i in 0 .. b {
		raw := unsafe { input[offset] }
		offset++
		if raw < 0 || raw >= n_raw || outer_seen[int(raw)] { return none }
		g.outer[i] = int(raw)
		outer_seen[int(raw)] = true
	}
	mut degree_sum := 0
	for u in 0 .. n {
		if offset >= length { return none }
		degree_raw := unsafe { input[offset] }
		offset++
		if degree_raw < 3 || degree_raw >= n_raw || offset + usize(degree_raw) > length { return none }
		d := int(degree_raw)
		g.degree[u] = d
		degree_sum += d
		mut row_seen := [max_n]bool{}
		for i in 0 .. d {
			raw := unsafe { input[offset] }
			offset++
			if raw < 0 || raw >= n_raw || raw == i64(u) || row_seen[int(raw)] { return none }
			v := int(raw)
			row_seen[v] = true
			g.rotation[u][i] = v
			g.adjacent[u][v] = true
		}
	}
	if offset + usize(n) != length || degree_sum % 2 != 0 { return none }
	mut perm_seen := [max_n]bool{}
	for u in 0 .. n {
		raw := unsafe { input[offset + usize(u)] }
		if raw < 0 || raw >= n_raw || perm_seen[int(raw)] { return none }
		g.permutation[u] = int(raw)
		perm_seen[int(raw)] = true
	}
	g.m = degree_sum / 2
	if g.m < n || g.m > 3 * n - 6 || g.m > max_m { return none }
	mut edge_count := 0
	for u in 0 .. n {
		for v in 0 .. n {
			if g.adjacent[u][v] != g.adjacent[v][u] { return none }
			if u < v && g.adjacent[u][v] {
				g.edge_u[edge_count] = u
				g.edge_v[edge_count] = v
				edge_count++
			}
		}
	}
	if edge_count != g.m || !connected_without(g, -1, -1) { return none }
	for u in 0 .. n {
		if !connected_without(g, u, -1) { return none }
		for v in u + 1 .. n { if !connected_without(g, u, v) { return none } }
	}
	for u in 0 .. max_n { for v in 0 .. max_n { g.dart_face[u][v] = -1 } }
	for e in 0 .. g.m {
		for direction in 0 .. 2 {
			mut u := g.edge_u[e]
			mut v := g.edge_v[e]
			if direction == 1 { u, v = v, u }
			if g.dart_face[u][v] >= 0 { continue }
			if g.f >= max_f { return none }
			mut cycle := []int{len: 2 * max_m}
			face_len := face_walk(g, u, v, mut cycle)
			if face_len < 3 || face_len > n { return none }
			mut face_seen := [max_n]bool{}
			for i in 0 .. face_len {
				a := cycle[i]
				b := cycle[(i + 1) % face_len]
				if face_seen[a] || g.dart_face[a][b] >= 0 { return none }
				face_seen[a] = true
			}
			for i in 0 .. face_len {
				a := cycle[i]
				b := cycle[(i + 1) % face_len]
				g.face[g.f][i] = a
				g.dart_face[a][b] = g.f
			}
			g.face_len[g.f] = face_len
			g.f++
		}
	}
	if g.f != g.m - g.n + 2 { return none }
	g.outer_id = -1
	for f in 0 .. g.f {
		if g.face_len[f] == b && same_cycle(g.outer[..b], g.face[f][..b], b) { g.outer_id = f }
	}
	if g.outer_id < 0 { return none }
	mut fixed_count := 0
	for v in 0 .. n { if g.permutation[v] == v { g.center = v; fixed_count++ } }
	if fixed_count != 1 || outer_seen[g.center] { return none }
	for v in 0 .. n {
		if v == g.center { continue }
		mut current := g.permutation[v]
		mut orbit_len := 1
		for current != v && orbit_len <= k { current = g.permutation[current]; orbit_len++ }
		if current != v || orbit_len != k { return none }
	}
	mut power := [max_n]int{}
	for v in 0 .. n { power[v] = v }
	for step in 1 .. k + 1 {
		mut next := [max_n]int{}
		mut identity := true
		for v in 0 .. n { next[v] = g.permutation[power[v]]; if next[v] != v { identity = false } }
		if identity != (step == k) { return none }
		power = next
	}
	for u in 0 .. n {
		image := g.permutation[u]
		for v in 0 .. n { if g.adjacent[u][v] != g.adjacent[image][g.permutation[v]] { return none } }
		mut row_ok := false
		for shift in 0 .. g.degree[image] {
			mut equal := true
			for i in 0 .. g.degree[u] { if g.permutation[g.rotation[u][i]] != g.rotation[image][(i + shift) % g.degree[image]] { equal = false } }
			if equal { row_ok = true }
		}
		if !row_ok { return none }
	}
	shift := b / k
	for i in 0 .. b { if g.permutation[g.outer[i]] != g.outer[(i + shift) % b] { return none } }
	return g
}

fn solve(g &Graph, mut words []i64) int {
	mut distance := [max_n]int{}
	for v in 0 .. max_n { distance[v] = -1 }
	mut queue := [max_n]int{}
	mut head := 0
	mut tail := 1
	distance[g.center] = 0
	queue[0] = g.center
	for head < tail {
		u := queue[head]
		head++
		for v in 0 .. g.n { if g.adjacent[u][v] && distance[v] < 0 { distance[v] = distance[u] + 1; queue[tail] = v; tail++ } }
	}
	mut endpoint := -1
	for i in 0 .. g.b {
		v := g.outer[i]
		if endpoint < 0 || distance[v] < distance[endpoint] || (distance[v] == distance[endpoint] && v < endpoint) { endpoint = v }
	}
	if endpoint < 0 || distance[endpoint] <= 0 { return -1 }
	mut to_end := [max_n]int{}
	for v in 0 .. max_n { to_end[v] = -1 }
	head = 0; tail = 1; to_end[endpoint] = 0; queue[0] = endpoint
	for head < tail {
		u := queue[head]; head++
		for v in 0 .. g.n { if g.adjacent[u][v] && to_end[v] < 0 { to_end[v] = to_end[u] + 1; queue[tail] = v; tail++ } }
	}
	mut p1 := [max_n]int{}
	mut p2 := [max_n]int{}
	mut p0 := [max_n]int{}
	mut p1_len := 1
	p1[0] = g.center
	for p1[p1_len - 1] != endpoint && p1_len < max_n {
		u := p1[p1_len - 1]
		mut choice := -1
		for v in 0 .. g.n { if g.adjacent[u][v] && to_end[v] == to_end[u] - 1 && (choice < 0 || v < choice) { choice = v } }
		if choice < 0 { return -1 }
		p1[p1_len] = choice; p1_len++
	}
	if p1[p1_len - 1] != endpoint || p1_len - 1 != distance[endpoint] { return -1 }
	for i in 0 .. p1_len { p2[i] = g.permutation[p1[i]] }
	endpoint2 := p2[p1_len - 1]
	if endpoint2 == endpoint { return -1 }
	for i in 1 .. p1_len { for j in 1 .. p1_len { if p1[i] == p2[j] { return -1 } } }
	for i in 1 .. p1_len - 1 { for j in 0 .. g.b { if p1[i] == g.outer[j] || p2[i] == g.outer[j] { return -1 } } }
	mut start := -1
	for i in 0 .. g.b { if g.outer[i] == endpoint { start = i } }
	if start < 0 { return -1 }
	p0_len := g.b / g.k + 1
	for i in 0 .. p0_len { p0[i] = g.outer[(start + i) % g.b] }
	if p0[p0_len - 1] != endpoint2 { return -1 }
	mut cycle := []int{len: 0, cap: 3 * max_n}
	for i in 0 .. p1_len { cycle << p1[i] }
	for i in 1 .. p0_len { cycle << p0[i] }
	for i in 0 .. p1_len - 1 { cycle << p2[p1_len - 2 - i] }
	if cycle[0] != g.center || cycle.last() != g.center { return -1 }
	mut cycle_vertex := [max_n]bool{}
	mut cut := [max_n][max_n]bool{}
	for i in 0 .. cycle.len - 1 {
		u := cycle[i]; v := cycle[i + 1]
		if !g.adjacent[u][v] || cycle_vertex[u] { return -1 }
		cycle_vertex[u] = true; cut[u][v] = true; cut[v][u] = true
	}
	seed := g.dart_face[p0[1]][p0[0]]
	if seed < 0 || seed == g.outer_id { return -1 }
	mut dual := [max_f][max_f]bool{}
	mut inside := [max_f]bool{}
	for e in 0 .. g.m {
		u := g.edge_u[e]; v := g.edge_v[e]
		if cut[u][v] { continue }
		a := g.dart_face[u][v]; b := g.dart_face[v][u]
		dual[a][b] = true; dual[b][a] = true
	}
	head = 0; tail = 1; queue[0] = seed; inside[seed] = true
	for head < tail {
		f := queue[head]; head++
		for other in 0 .. g.f { if dual[f][other] && !inside[other] { inside[other] = true; queue[tail] = other; tail++ } }
	}
	if inside[g.outer_id] { return -1 }
	mut vertices := cycle_vertex
	for f in 0 .. g.f { if inside[f] { for i in 0 .. g.face_len[f] { vertices[g.face[f][i]] = true } } }
	mut vertex_mask := i64(0); mut edge_mask := i64(0)
	for v in 0 .. g.n { if vertices[v] { vertex_mask |= i64(1) << v } }
	for e in 0 .. g.m { if vertices[g.edge_u[e]] && vertices[g.edge_v[e]] { edge_mask |= i64(1) << e } }
	mut count := 0
	words[count] = i64(p1_len); count++
	for i in 0 .. p1_len { words[count] = i64(p1[i]); count++ }
	words[count] = i64(p1_len); count++
	for i in 0 .. p1_len { words[count] = i64(p2[i]); count++ }
	words[count] = i64(p0_len); count++
	for i in 0 .. p0_len { words[count] = i64(p0[i]); count++ }
	words[count] = vertex_mask; words[count + 1] = edge_mask
	return count + 2
}

fn write_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for i in 0 .. 8 { unsafe { output[offset + i] = u8((bits >> (8 * i)) & 255) } }
}

@[export: 'symmetric_drawing_cyclic_wedge']
pub fn symmetric_drawing_cyclic_wedge(input &i64, input_length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || input_length < 3 || input_length > max_input { return -1 }
	mut g := parse(input, input_length)
	if g == none { return -1 }
	mut words := []i64{len: 29}
	count := solve(g, mut words)
	if count < 0 || count * 8 > max_output { return -1 }
	bytes := usize(count * 8)
	if unsafe { output == nil } || output_capacity < bytes { return -2 }
	mut temporary := [max_output]u8{}
	for i in 0 .. count { write_i64_le(mut temporary, i * 8, words[i]) }
	unsafe { for i in 0 .. bytes { output[i] = temporary[i] } }
	return i64(bytes)
}
