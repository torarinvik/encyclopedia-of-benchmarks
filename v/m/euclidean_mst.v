module euclidean_mst

const max_points = 8
const max_edges = max_points * (max_points - 1) / 2
const max_input_length = 18
const max_output_words = 2 * max_points - 1

struct Point { x i64; y i64 }
struct Edge { u int; v int; weight i64 }

fn orientation(a Point, b Point, c Point) i64 {
	return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}
fn incircle(a Point, b Point, c Point, d Point) i64 {
	ax, ay, bx, by, cx, cy := a.x - d.x, a.y - d.y, b.x - d.x, b.y - d.y, c.x - d.x, c.y - d.y
	return (ax*ax + ay*ay)*(bx*cy - by*cx) - (bx*bx + by*by)*(ax*cy - ay*cx) +
		(cx*cx + cy*cy)*(ax*by - ay*bx)
}
fn general_position(points [max_points]Point, n int) bool {
	for a in 0 .. n { for b in a + 1 .. n {
		if points[a].x == points[b].x && points[a].y == points[b].y { return false }
	} }
	for a in 0 .. n { for b in a + 1 .. n { for c in b + 1 .. n {
		if orientation(points[a], points[b], points[c]) == 0 { return false }
		for d in 0 .. n {
			if d != a && d != b && d != c && incircle(points[a], points[b], points[c], points[d]) == 0 { return false }
		}
	} } }
	return true
}
fn find_root(mut parent [max_points]int, vertex int) int {
	mut v := vertex
	for parent[v] != v { parent[v] = parent[parent[v]]; v = parent[v] }
	return v
}
fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) } }
}

@[export: 'euclidean_mst']
pub fn euclidean_mst(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_input_length { return -1 }
		raw_n := input[0]
		if raw_n < 1 || raw_n > max_points || int(length) != 1 + 2 * int(raw_n) { return -1 }
		n := int(raw_n)
		mut points := [max_points]Point{}
		for i in 0 .. n {
			points[i] = Point{x: input[1 + 2*i], y: input[2 + 2*i]}
			if points[i].x < -10 || points[i].x > 10 || points[i].y < -10 || points[i].y > 10 { return -1 }
		}
		if !general_position(points, n) { return -1 }
		output_words := 2 * n - 1
		output_bytes := 8 * output_words
		if output == nil || output_capacity < usize(output_bytes) { return -2 }
		mut candidate := [max_points][max_points]bool{}
		if n == 2 { candidate[0][1] = true; candidate[1][0] = true }
		for a in 0 .. n { for b in a + 1 .. n { for c in b + 1 .. n {
			turn := orientation(points[a], points[b], points[c])
			mut empty := true
			for d in 0 .. n {
				if d == a || d == b || d == c { continue }
				determinant := incircle(points[a], points[b], points[c], points[d])
				if (determinant > 0) == (turn > 0) { empty = false; break }
			}
			if empty {
				candidate[a][b] = true; candidate[b][a] = true
				candidate[a][c] = true; candidate[c][a] = true
				candidate[b][c] = true; candidate[c][b] = true
			}
		} } }
		mut edges := [max_edges]Edge{}
		mut edge_count := 0
		for u in 0 .. n { for v in u + 1 .. n {
			if !candidate[u][v] { continue }
			dx, dy := points[u].x - points[v].x, points[u].y - points[v].y
			edge := Edge{u: u, v: v, weight: dx*dx + dy*dy}
			mut at := edge_count
			edge_count++
			for at > 0 {
				previous := edges[at - 1]
				if previous.weight < edge.weight || (previous.weight == edge.weight &&
					(previous.u < edge.u || (previous.u == edge.u && previous.v <= edge.v))) { break }
				edges[at] = previous
				at--
			}
			edges[at] = edge
		} }
		mut parent := [max_points]int{}
		mut sizes := [max_points]int{}
		for i in 0 .. n { parent[i] = i; sizes[i] = 1 }
		mut words := [max_output_words]i64{}
		words[0] = i64(n - 1)
		mut selected := 0
		for i in 0 .. edge_count {
			if selected == n - 1 { break }
			mut left := find_root(mut parent, edges[i].u)
			mut right := find_root(mut parent, edges[i].v)
			if left == right { continue }
			if sizes[left] < sizes[right] { left, right = right, left }
			parent[right] = left
			sizes[left] += sizes[right]
			words[1 + 2*selected] = i64(edges[i].u)
			words[2 + 2*selected] = i64(edges[i].v)
			selected++
		}
		if selected != n - 1 { return -1 }
		for word in 0 .. output_words { store_i64_le(mut output, 8*word, words[word]) }
		return i64(output_bytes)
	}
}
