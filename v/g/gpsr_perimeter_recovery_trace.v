module gpsr_perimeter_recovery_trace

const max_n = 8
const max_m = 18
const max_path = 37
const max_input = 57
const max_output = 896
const max_output_words = 112

struct Point {
	x i64
	y i64
}

struct Edge {
	u int
	v int
}

fn gpsr_cross(ax i64, ay i64, bx i64, by i64) i64 {
	return ax * by - ay * bx
}

fn gpsr_orient(points [max_n]Point, a int, b int, c int) i64 {
	return gpsr_cross(points[b].x - points[a].x, points[b].y - points[a].y,
		points[c].x - points[a].x, points[c].y - points[a].y)
}

fn gpsr_half(x i64, y i64) int {
	if y > 0 || (y == 0 && x >= 0) { return 0 }
	return 1
}

fn gpsr_angle_less(ax i64, ay i64, ai int, bx i64, by i64, bi int) bool {
	ah, bh := gpsr_half(ax, ay), gpsr_half(bx, by)
	if ah != bh { return ah < bh }
	turn := gpsr_cross(ax, ay, bx, by)
	if turn != 0 { return turn > 0 }
	return ai < bi
}

fn gpsr_segments_cross(points [max_n]Point, a int, b int, c int, d int) bool {
	return gpsr_orient(points, a, b, c) * gpsr_orient(points, a, b, d) < 0 &&
		gpsr_orient(points, c, d, a) * gpsr_orient(points, c, d, b) < 0
}

fn gpsr_gcd(a0 i64, b0 i64) i64 {
	mut a, mut b := a0, b0
	for b != 0 {
		r := a % b
		a, b = b, r
	}
	return a
}

fn gpsr_proper_crossing(p Point, q Point, a Point, b Point, numerator &i64, denominator &i64) bool {
	rx, ry := q.x - p.x, q.y - p.y
	sx, sy := b.x - a.x, b.y - a.y
	mut den := gpsr_cross(rx, ry, sx, sy)
	if den == 0 { return false }
	ox, oy := a.x - p.x, a.y - p.y
	mut tn, mut un := gpsr_cross(ox, oy, sx, sy), gpsr_cross(ox, oy, rx, ry)
	if den < 0 { den, tn, un = -den, -tn, -un }
	if !(tn > 0 && tn < den && un > 0 && un < den) { return false }
	divisor := gpsr_gcd(tn, den)
	unsafe {
		numerator[0] = tn / divisor
		denominator[0] = den / divisor
	}
	return true
}

fn gpsr_edge_id(u0 int, v0 int, m int, edges [max_m]Edge) int {
	lo, hi := u0, v0
	if lo > hi { lo, hi = hi, lo }
	for i in 0 .. m {
		if edges[i].u == lo && edges[i].v == hi { return i }
	}
	return -1
}

fn gpsr_next_ccw(node int, incoming int, degree [max_n]int, rotation [max_n][max_n]int) int {
	for i in 0 .. degree[node] {
		if rotation[node][i] == incoming { return rotation[node][(i + 1) % degree[node]] }
	}
	return -1
}

fn gpsr_first_ccw(node int, target int, points [max_n]Point, degree [max_n]int, adjacency [max_n][max_n]int) int {
	rx, ry := points[target].x - points[node].x, points[target].y - points[node].y
	mut best := -1
	mut best_x, mut best_y := i64(0), i64(0)
	for i in 0 .. degree[node] {
		v := adjacency[node][i]
		dx, dy := points[v].x - points[node].x, points[v].y - points[node].y
		vx, vy := rx * dx + ry * dy, gpsr_cross(rx, ry, dx, dy)
		if best < 0 || gpsr_angle_less(vx, vy, v, best_x, best_y, best) {
			best, best_x, best_y = v, vx, vy
		}
	}
	return best
}

fn gpsr_put64(output &u8, position int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[position + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'gpsr_perimeter_recovery_trace']
pub fn gpsr_perimeter_recovery_trace(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_input { return -1 }
		n64, m64, source64, target64 := input[0], input[1], input[2], input[3]
		if n64 < 3 || n64 > max_n { return -1 }
		mut max_edges := 3 * n64 - 6
		if max_edges > max_m { max_edges = max_m }
		if m64 < n64 - 1 || m64 > max_edges ||
			source64 < 0 || target64 < 0 || source64 >= n64 || target64 >= n64 || source64 == target64 { return -1 }
		n, m, source, target := int(n64), int(m64), int(source64), int(target64)
		if length != usize(4 + 2 * n + 2 * m) { return -1 }

		mut points := [max_n]Point{}
		for i in 0 .. n {
			points[i] = Point{input[4 + i], input[4 + n + i]}
			if points[i].x < -16 || points[i].x > 16 || points[i].y < -16 || points[i].y > 16 { return -1 }
			for j in 0 .. i {
				if points[i].x == points[j].x && points[i].y == points[j].y { return -1 }
			}
		}
		for i in 0 .. n {
			for j in i + 1 .. n {
				for k in j + 1 .. n {
					if gpsr_orient(points, i, j, k) == 0 { return -1 }
				}
			}
		}

		mut edges := [max_m]Edge{}
		mut adjacency := [max_n][max_n]int{}
		mut degree := [max_n]int{}
		edge_start := 4 + 2 * n
		for i in 0 .. m {
			u64, v64 := input[edge_start + 2 * i], input[edge_start + 2 * i + 1]
			if u64 < 0 || v64 >= n64 || u64 >= v64 { return -1 }
			u, v := int(u64), int(v64)
			if i > 0 && (edges[i - 1].u > u || (edges[i - 1].u == u && edges[i - 1].v >= v)) { return -1 }
			edges[i] = Edge{u, v}
			adjacency[u][degree[u]], adjacency[v][degree[v]] = v, u
			degree[u]++
			degree[v]++
		}

		mut reached := [max_n]bool{}
		mut queue := [max_n]int{}
		mut head, mut tail := 0, 1
		reached[source] = true
		queue[0] = source
		for head < tail {
			u := queue[head]
			head++
			for i in 0 .. degree[u] {
				v := adjacency[u][i]
				if !reached[v] {
					reached[v] = true
					queue[tail] = v
					tail++
				}
			}
		}
		for i in 0 .. n { if !reached[i] { return -1 } }

		for i in 0 .. m {
			for j in i + 1 .. m {
				a, b, c, d := edges[i].u, edges[i].v, edges[j].u, edges[j].v
				if a != c && a != d && b != c && b != d && gpsr_segments_cross(points, a, b, c, d) { return -1 }
			}
		}

		sx, sy := points[source].x - points[target].x, points[source].y - points[target].y
		source_distance := sx * sx + sy * sy
		for i in 0 .. degree[source] {
			v := adjacency[source][i]
			dx, dy := points[v].x - points[target].x, points[v].y - points[target].y
			if dx * dx + dy * dy < source_distance { return -1 }
		}
		if output == nil || capacity < max_output { return -2 }

		mut rotation := [max_n][max_n]int{}
		for u in 0 .. n {
			for i in 0 .. degree[u] { rotation[u][i] = adjacency[u][i] }
			for i in 1 .. degree[u] {
				v := rotation[u][i]
				dx, dy := points[v].x - points[u].x, points[v].y - points[u].y
				mut j := i
				for j > 0 {
					w := rotation[u][j - 1]
					if !gpsr_angle_less(dx, dy, v, points[w].x - points[u].x, points[w].y - points[u].y, w) { break }
					rotation[u][j] = w
					j--
				}
				rotation[u][j] = v
			}
		}

		mut path := [max_path]int{}
		mut events := [max_m][4]i64{}
		mut path_count, mut crossing_count := 1, 0
		mut current, mut previous := source, -1
		mut e0u, mut e0v := -1, -1
		mut lf_num, mut lf_den := i64(0), i64(1)
		mut status := i64(0)
		path[0] = source
		for {
			dx, dy := points[current].x - points[target].x, points[current].y - points[target].y
			if current == target { status = 2; break }
			if dx * dx + dy * dy < source_distance { status = 1; break }
			if path_count - 1 >= 2 * m { status = 0; break }
			mut candidate := -1
			if previous < 0 {
				candidate = gpsr_first_ccw(current, target, points, degree, adjacency)
			} else {
				candidate = gpsr_next_ccw(current, previous, degree, rotation)
			}
			if candidate < 0 { status = 0; break }
			mut changed_face, mut invalid_state := false, false
			for {
				mut t_num, mut t_den := i64(0), i64(1)
				if !gpsr_proper_crossing(points[source], points[target], points[current], points[candidate], &t_num, &t_den) ||
					t_num * lf_den <= lf_num * t_den { break }
				id := gpsr_edge_id(current, candidate, m, edges)
				if id < 0 || crossing_count >= max_m { status = 0; invalid_state = true; break }
				events[crossing_count] = [4]i64{i64(path_count - 1), i64(id), t_num, t_den}
				crossing_count++
				lf_num, lf_den = t_num, t_den
				changed_face = true
				candidate = gpsr_next_ccw(current, candidate, degree, rotation)
				if candidate < 0 { status = 0; invalid_state = true; break }
			}
			if invalid_state { break }
			if changed_face || e0u < 0 { e0u, e0v = current, candidate }
			else if e0u == current && e0v == candidate { status = 0; break }
			previous, current = current, candidate
			if path_count >= max_path { status = 0; break }
			path[path_count] = current
			path_count++
		}

		mut words := [max_output_words]i64{}
		mut word_count := 0
		words[word_count] = status; word_count++
		words[word_count] = i64(path_count - 1); word_count++
		for i in 0 .. path_count { words[word_count] = i64(path[i]); word_count++ }
		words[word_count] = i64(crossing_count); word_count++
		for i in 0 .. crossing_count {
			for j in 0 .. 4 { words[word_count] = events[i][j]; word_count++ }
		}
		for i in 0 .. word_count { gpsr_put64(output, 8 * i, words[i]) }
		return i64(8 * word_count)
	}
}
