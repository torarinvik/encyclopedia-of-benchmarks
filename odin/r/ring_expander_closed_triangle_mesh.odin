package ring_expander_closed_triangle_mesh

import "core:c"

MAX_N :: 12
MAX_T :: 20
MAX_C :: 60
MAX_INPUT :: 64

put_word :: proc(output: [^]u8, at: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[at+byte] = u8(bits&255); bits >>= 8 }
}

next_corner :: proc(corner: int) -> int { return 3*(corner/3)+(corner%3+1)%3 }
prev_corner :: proc(corner: int) -> int { return 3*(corner/3)+(corner%3+2)%3 }
corner_vertex :: proc(faces: [MAX_C]i64, corner: int) -> int {
	return int(faces[3*(corner/3)+corner%3])
}

run_ring :: proc(n, t, seed: int, faces: [MAX_C]i64,
	trace: ^[MAX_C]i64, trace_count: ^int, vertex_mask, triangle_mask: ^u64) -> bool {
	opposite: [MAX_C]int
	link: [MAX_N][MAX_N][MAX_N]bool
	used: [MAX_N]bool
	edge_count: [MAX_N][MAX_N]u8
	edge_first: [MAX_N][MAX_N]i32
	edge_second: [MAX_N][MAX_N]i32
	for a := 0; a < MAX_N; a += 1 { for b := 0; b < MAX_N; b += 1 { edge_first[a][b] = -1; edge_second[a][b] = -1 } }
	for ti := 0; ti < t; ti += 1 {
		a, b, c := int(faces[3*ti]), int(faces[3*ti+1]), int(faces[3*ti+2])
		used[a], used[b], used[c] = true, true, true
		link[a][b][c], link[a][c][b] = true, true
		link[b][c][a], link[b][a][c] = true, true
		link[c][a][b], link[c][b][a] = true, true
		for j := 0; j < 3; j += 1 {
			first, second := int(faces[3*ti+(j+1)%3]), int(faces[3*ti+(j+2)%3])
			low, high := first, second
			if low > high { low, high = high, low }
			count := edge_count[low][high]
			if count == 0 { edge_first[low][high] = i32(3*ti+j) } else if count == 1 { edge_second[low][high] = i32(3*ti+j) } else { return false }
			edge_count[low][high] = count + 1
		}
	}
	for v := 0; v < n; v += 1 { if !used[v] { return false } }

	for low := 0; low < n; low += 1 {
		for high := low + 1; high < n; high += 1 {
			if edge_count[low][high] == 0 { continue }
			if edge_count[low][high] != 2 { return false }
			a, b := int(edge_first[low][high]), int(edge_second[low][high])
			at, aj, bt, bj := a/3, a%3, b/3, b%3
			a0, a1 := int(faces[3*at+(aj+1)%3]), int(faces[3*at+(aj+2)%3])
			b0, b1 := int(faces[3*bt+(bj+1)%3]), int(faces[3*bt+(bj+2)%3])
			if a0 != b1 || a1 != b0 { return false }
			opposite[a], opposite[b] = b, a
		}
	}

	for v := 0; v < n; v += 1 {
		start := -1
		for w := 0; w < n; w += 1 {
			degree := 0
			for x := 0; x < n; x += 1 { if link[v][w][x] { degree += 1 } }
			if degree > 0 && start < 0 { start = w }
			if degree > 0 && degree != 2 { return false }
		}
		if start < 0 { return false }
		seen: [MAX_N]bool
		queue: [MAX_N]int
		head, tail := 0, 0
		seen[start], queue[tail] = true, start
		tail += 1
		for head < tail {
			w := queue[head]; head += 1
			for x := 0; x < n; x += 1 { if link[v][w][x] && !seen[x] { seen[x], queue[tail] = true, x; tail += 1 } }
		}
		for w := 0; w < n; w += 1 {
			has_edge := false
			for x := 0; x < n; x += 1 { has_edge = has_edge || link[v][w][x] }
			if has_edge && !seen[w] { return false }
		}
	}

	reached: [MAX_T]bool
	queue: [MAX_T]int
	head, tail := 0, 0
	reached[0], queue[tail] = true, 0
	tail += 1
	for head < tail {
		ti := queue[head]; head += 1
		for j := 0; j < 3; j += 1 {
			other := opposite[3*ti+j]/3
			if !reached[other] { reached[other], queue[tail] = true, other; tail += 1 }
		}
	}
	for ti := 0; ti < t; ti += 1 { if !reached[ti] { return false } }

	seen_corners: [MAX_C]bool
	trace_count^ = 0
	vertex_mask^ = 0
	triangle_mask^ = 0
	vertex_mask^ |= u64(1) << u32(corner_vertex(faces, next_corner(seed)))
	vertex_mask^ |= u64(1) << u32(corner_vertex(faces, prev_corner(seed)))
	stop, current := opposite[seed], seed
	for current != stop {
		if current < 0 || current >= 3*t || seen_corners[current] || trace_count^ >= 3*t { return false }
		seen_corners[current] = true
		trace[trace_count^] = i64(current)
		trace_count^ += 1
		ti, v := current/3, corner_vertex(faces, current)
		if ((vertex_mask^ >> v) & 1) == 0 {
			vertex_mask^ |= u64(1) << u32(v)
			triangle_mask^ |= u64(1) << u32(ti)
		} else if ((triangle_mask^ >> ti) & 1) == 0 { current = opposite[current] }
		current = opposite[prev_corner(current)]
	}
	return true
}

@(export)
ring_expander_closed_triangle_mesh :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 15 || length > MAX_INPUT do return -1
	n64, t64, seed64 := input[0], input[1], input[2]
	if n64 < 4 || n64 > MAX_N || t64 < 4 || t64 > MAX_T do return -1
	n, t := int(n64), int(t64)
	if length != c.size_t(3+3*t) || seed64 < 0 || seed64 >= 3*t64 do return -1
	seed := int(seed64)
	faces: [MAX_C]i64
	for i := 0; i < 3*t; i += 1 { value := input[3+i]; if value < 0 || value >= n64 do return -1; faces[i] = value }
	for ti := 0; ti < t; ti += 1 {
		if faces[3*ti] == faces[3*ti+1] || faces[3*ti+1] == faces[3*ti+2] || faces[3*ti+2] == faces[3*ti] do return -1
	}
	trace: [MAX_C]i64
	trace_count := 0
	vertices, triangles: u64 = 0, 0
	if !run_ring(n, t, seed, faces, &trace, &trace_count, &vertices, &triangles) do return -1
	words := 1+trace_count+2
	bytes := 8*words
	if output == nil || capacity < c.size_t(bytes) do return -2
	put_word(output, 0, i64(trace_count))
	for i := 0; i < trace_count; i += 1 { put_word(output, 8*(i+1), trace[i]) }
	put_word(output, 8*(trace_count+1), i64(vertices))
	put_word(output, 8*(trace_count+2), i64(triangles))
	return i64(bytes)
}
