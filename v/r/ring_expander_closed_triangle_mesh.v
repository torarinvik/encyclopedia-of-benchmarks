module ring_expander_closed_triangle_mesh

const max_n = 12
const max_t = 20
const max_c = 60
const max_input = 64

fn put_word(output &u8, at int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[at + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

fn next_corner(corner int) int { return 3 * (corner / 3) + (corner % 3 + 1) % 3 }
fn prev_corner(corner int) int { return 3 * (corner / 3) + (corner % 3 + 2) % 3 }
fn corner_vertex(faces [max_c]i64, corner int) int {
	return int(faces[3 * (corner / 3) + corner % 3])
}

fn run_ring(n int, t int, seed int, faces [max_c]i64, mut trace [max_c]i64,
	mut trace_count int, mut vertex_mask u64, mut triangle_mask u64) bool {
	mut opposite := [max_c]int{init: -1}
	mut link := [max_n][max_n][max_n]bool{}
	mut used := [max_n]bool{}
	mut edge_count := [max_n][max_n]u8{}
	mut edge_first := [max_n][max_n]i32{init: -1}
	mut edge_second := [max_n][max_n]i32{init: -1}
	for ti in 0 .. t {
		a, b, c := int(faces[3 * ti]), int(faces[3 * ti + 1]), int(faces[3 * ti + 2])
		used[a], used[b], used[c] = true, true, true
		link[a][b][c], link[a][c][b] = true, true
		link[b][c][a], link[b][a][c] = true, true
		link[c][a][b], link[c][b][a] = true, true
		for j in 0 .. 3 {
			first, second := int(faces[3 * ti + (j + 1) % 3]), int(faces[3 * ti + (j + 2) % 3])
			low, high := first, second
			if low > high { low, high = high, low }
			count := edge_count[low][high]
			if count == 0 { edge_first[low][high] = i32(3 * ti + j) } else if count == 1 { edge_second[low][high] = i32(3 * ti + j) } else { return false }
			edge_count[low][high] = count + 1
		}
	}
	for vtx in 0 .. n { if !used[vtx] { return false } }

	for low in 0 .. n {
		for high in low + 1 .. n {
			if edge_count[low][high] == 0 { continue }
			if edge_count[low][high] != 2 { return false }
			a, b := int(edge_first[low][high]), int(edge_second[low][high])
			at, aj, bt, bj := a / 3, a % 3, b / 3, b % 3
			a0, a1 := int(faces[3 * at + (aj + 1) % 3]), int(faces[3 * at + (aj + 2) % 3])
			b0, b1 := int(faces[3 * bt + (bj + 1) % 3]), int(faces[3 * bt + (bj + 2) % 3])
			if a0 != b1 || a1 != b0 { return false }
			opposite[a], opposite[b] = b, a
		}
	}

	for vtx in 0 .. n {
		mut start := -1
		for w in 0 .. n {
			mut degree := 0
			for x in 0 .. n { if link[vtx][w][x] { degree++ } }
			if degree > 0 && start < 0 { start = w }
			if degree > 0 && degree != 2 { return false }
		}
		if start < 0 { return false }
		mut seen := [max_n]bool{}
		mut queue := [max_n]int{}
		mut head := 0
		mut tail := 0
		seen[start] = true
		queue[tail] = start
		tail++
		for head < tail {
			w := queue[head]
			head++
			for x in 0 .. n { if link[vtx][w][x] && !seen[x] { seen[x] = true; queue[tail] = x; tail++ } }
		}
		for w in 0 .. n {
			mut has_edge := false
			for x in 0 .. n { has_edge = has_edge || link[vtx][w][x] }
			if has_edge && !seen[w] { return false }
		}
	}

	mut reached := [max_t]bool{}
	mut queue := [max_t]int{}
	mut head := 0
	mut tail := 0
	reached[0] = true
	queue[tail] = 0
	tail++
	for head < tail {
		ti := queue[head]
		head++
		for j in 0 .. 3 {
			other := opposite[3 * ti + j] / 3
			if !reached[other] { reached[other] = true; queue[tail] = other; tail++ }
		}
	}
	for ti in 0 .. t { if !reached[ti] { return false } }

	mut seen_corners := [max_c]bool{}
	trace_count = 0
	vertex_mask = 0
	triangle_mask = 0
	vertex_mask |= u64(1) << corner_vertex(faces, next_corner(seed))
	vertex_mask |= u64(1) << corner_vertex(faces, prev_corner(seed))
	stop := opposite[seed]
	mut current := seed
	for current != stop {
		if current < 0 || current >= 3 * t || seen_corners[current] || trace_count >= 3 * t { return false }
		seen_corners[current] = true
		trace[trace_count] = i64(current)
		trace_count++
		ti, vtx := current / 3, corner_vertex(faces, current)
		if ((vertex_mask >> vtx) & 1) == 0 {
			vertex_mask |= u64(1) << vtx
			triangle_mask |= u64(1) << ti
		} else if ((triangle_mask >> ti) & 1) == 0 { current = opposite[current] }
		current = opposite[prev_corner(current)]
	}
	return true
}

@[export: 'ring_expander_closed_triangle_mesh']
pub fn ring_expander_closed_triangle_mesh(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 15 || length > max_input { return -1 }
		n64, t64, seed64 := input[0], input[1], input[2]
		if n64 < 4 || n64 > max_n || t64 < 4 || t64 > max_t || length != usize(3 + 3 * t64) || seed64 < 0 || seed64 >= 3 * t64 { return -1 }
		n, t, seed := int(n64), int(t64), int(seed64)
		mut faces := [max_c]i64{}
		for i in 0 .. 3 * t {
			value := input[3 + i]
			if value < 0 || value >= n64 { return -1 }
			faces[i] = value
		}
		for ti in 0 .. t {
			if faces[3 * ti] == faces[3 * ti + 1] || faces[3 * ti + 1] == faces[3 * ti + 2] || faces[3 * ti + 2] == faces[3 * ti] { return -1 }
		}
		mut trace := [max_c]i64{}
		mut trace_count := 0
		mut vertices := u64(0)
		mut triangles := u64(0)
		if !run_ring(n, t, seed, faces, mut trace, mut trace_count, mut vertices, mut triangles) { return -1 }
		bytes := 8 * (1 + trace_count + 2)
		if output == nil || capacity < usize(bytes) { return -2 }
		put_word(output, 0, i64(trace_count))
		for i in 0 .. trace_count { put_word(output, 8 * (i + 1), trace[i]) }
		put_word(output, 8 * (trace_count + 1), i64(vertices))
		put_word(output, 8 * (trace_count + 2), i64(triangles))
		return i64(bytes)
	}
}
