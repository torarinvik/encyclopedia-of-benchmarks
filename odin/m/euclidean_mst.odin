package euclidean_mst

import "core:c"

MAX_POINTS :: 8
MAX_EDGES :: MAX_POINTS * (MAX_POINTS - 1) / 2
MAX_INPUT_LENGTH :: 18
MAX_OUTPUT_WORDS :: 2 * MAX_POINTS - 1

Point :: struct { x, y: i64 }
Edge :: struct { u, v: int, weight: i64 }

orientation :: proc "contextless" (a, b, c: Point) -> i64 {
	return (b.x-a.x)*(c.y-a.y) - (b.y-a.y)*(c.x-a.x)
}
incircle :: proc "contextless" (a, b, c, d: Point) -> i64 {
	ax, ay := a.x-d.x, a.y-d.y
	bx, by := b.x-d.x, b.y-d.y
	cx, cy := c.x-d.x, c.y-d.y
	return (ax*ax+ay*ay)*(bx*cy-by*cx) - (bx*bx+by*by)*(ax*cy-ay*cx) + (cx*cx+cy*cy)*(ax*by-ay*bx)
}
general_position :: proc "contextless" (points: [MAX_POINTS]Point, n: int) -> bool {
	for a := 0; a < n; a += 1 {
		for b := a+1; b < n; b += 1 {
			if points[a].x == points[b].x && points[a].y == points[b].y do return false
		}
	}
	for a := 0; a < n; a += 1 {
		for b := a+1; b < n; b += 1 {
			for c := b+1; c < n; c += 1 {
				if orientation(points[a], points[b], points[c]) == 0 do return false
				for d := 0; d < n; d += 1 {
					if d != a && d != b && d != c && incircle(points[a], points[b], points[c], points[d]) == 0 do return false
				}
			}
		}
	}
	return true
}
find_root :: proc "contextless" (parent: ^[MAX_POINTS]int, vertex: int) -> int {
	current := vertex
	for parent[current] != current {
		parent[current] = parent[parent[current]]
		current = parent[current]
	}
	return current
}
store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8((bits >> u64(byte*8)) & 255) }
}

@(export)
euclidean_mst :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
	raw_n := input[0]
	if raw_n < 1 || raw_n > MAX_POINTS do return -1
	n := int(raw_n)
	if int(length) != 1 + 2*n do return -1
	points: [MAX_POINTS]Point
	for i := 0; i < n; i += 1 {
		points[i] = Point{x = input[1+2*i], y = input[2+2*i]}
		if points[i].x < -10 || points[i].x > 10 || points[i].y < -10 || points[i].y > 10 do return -1
	}
	if !general_position(points, n) do return -1
	output_words := 2*n - 1
	output_bytes := 8*output_words
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2

	candidate: [MAX_POINTS][MAX_POINTS]bool
	if n == 2 { candidate[0][1] = true; candidate[1][0] = true }
	for a := 0; a < n; a += 1 {
		for b := a+1; b < n; b += 1 {
			for c := b+1; c < n; c += 1 {
				turn := orientation(points[a], points[b], points[c])
				empty := true
				for d := 0; d < n; d += 1 {
					if d == a || d == b || d == c do continue
					determinant := incircle(points[a], points[b], points[c], points[d])
					if (determinant > 0) == (turn > 0) { empty = false; break }
				}
				if empty {
					candidate[a][b] = true; candidate[b][a] = true
					candidate[a][c] = true; candidate[c][a] = true
					candidate[b][c] = true; candidate[c][b] = true
				}
			}
		}
	}
	edges: [MAX_EDGES]Edge
	edge_count := 0
	for u := 0; u < n; u += 1 {
		for v := u+1; v < n; v += 1 {
			if !candidate[u][v] do continue
			dx, dy := points[u].x-points[v].x, points[u].y-points[v].y
			edge := Edge{u = u, v = v, weight = dx*dx+dy*dy}
			at := edge_count
			edge_count += 1
			for at > 0 {
				previous := edges[at-1]
				if previous.weight < edge.weight || (previous.weight == edge.weight &&
					(previous.u < edge.u || (previous.u == edge.u && previous.v <= edge.v))) do break
				edges[at] = previous
				at -= 1
			}
			edges[at] = edge
		}
	}
	parent: [MAX_POINTS]int
	sizes: [MAX_POINTS]int
	for i := 0; i < n; i += 1 { parent[i] = i; sizes[i] = 1 }
	words: [MAX_OUTPUT_WORDS]i64
	words[0] = i64(n-1)
	selected := 0
	for i := 0; i < edge_count && selected < n-1; i += 1 {
		left := find_root(&parent, edges[i].u)
		right := find_root(&parent, edges[i].v)
		if left == right do continue
		if sizes[left] < sizes[right] { left, right = right, left }
		parent[right] = left
		sizes[left] += sizes[right]
		words[1+2*selected] = i64(edges[i].u)
		words[2+2*selected] = i64(edges[i].v)
		selected += 1
	}
	if selected != n-1 do return -1
	for word := 0; word < output_words; word += 1 { store_i64_le(output, word*8, words[word]) }
	return i64(output_bytes)
}
