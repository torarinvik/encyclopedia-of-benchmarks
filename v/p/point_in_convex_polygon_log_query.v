module point_in_convex_polygon_log_query

const max_vertices = 32
const max_queries = 32
const max_input = 131
const max_coord = i64(1000000)

struct Point { x i64; y i64 }
fn sub(a Point, b Point) Point { return Point{ x: a.x - b.x, y: a.y - b.y } }
fn cross(a Point, b Point) i64 { return a.x * b.y - a.y * b.x }
fn on_segment(a Point, b Point, p Point) bool {
	e := sub(b, a); r := sub(p, a)
	minx := if a.x < b.x { a.x } else { b.x }; maxx := if a.x > b.x { a.x } else { b.x }
	miny := if a.y < b.y { a.y } else { b.y }; maxy := if a.y > b.y { a.y } else { b.y }
	return cross(e, r) == 0 && p.x >= minx && p.x <= maxx && p.y >= miny && p.y <= maxy
}
fn valid_polygon(p &Point, n int) bool {
	unsafe {
		for i in 0 .. n {
			next := (i + 1) % n
			if p[i].x == p[next].x && p[i].y == p[next].y { return false }
			edge := sub(p[next], p[i])
			for j in 0 .. n { if j != i && j != next && cross(edge, sub(p[j], p[i])) <= 0 { return false } }
			for j in i + 1 .. n { if p[i].x == p[j].x && p[i].y == p[j].y { return false } }
		}
	}
	return true
}
fn contains_fan(fan &Point, m int, query Point) i64 {
	origin := Point{ x: 0, y: 0 }
	first := cross(fan[0], query); last := cross(fan[m - 1], query)
	if first < 0 || last > 0 { return 0 }
	if first == 0 { return if on_segment(origin, fan[0], query) { 1 } else { 0 } }
	if last == 0 { return if on_segment(origin, fan[m - 1], query) { 1 } else { 0 } }
	mut lo := 0; mut hi := m
	for hi - lo > 1 {
		mid := (lo + hi) / 2
		if cross(fan[mid], query) >= 0 { lo = mid } else { hi = mid }
	}
	side := cross(sub(fan[lo + 1], fan[lo]), sub(query, fan[lo]))
	if side < 0 { return 0 }
	if side == 0 { return if on_segment(fan[lo], fan[lo + 1], query) { 1 } else { 0 } }
	return 1
}
fn put_i64(mut output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for b in 0 .. 8 { output[offset + b] = u8((bits >> (8 * b)) & 255) }
	}
}

@[export: 'point_in_convex_polygon_log_query']
pub fn point_in_convex_polygon_log_query(values &i64, n usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if values == nil || n < 2 || n > max_input || values[0] < 3 || values[0] > 32 || values[1] < 0 || values[1] > 32 { return -1 }
		vertices := int(values[0]); queries := int(values[1])
		if n != usize(2 + 2 * vertices + 2 * queries) { return -1 }
		mut polygon := [max_vertices]Point{init: Point{}}
		mut fan := [max_vertices]Point{init: Point{}}
		mut query_points := [max_queries]Point{init: Point{}}
		mut answers := [max_queries]i64{}
		mut at := 2
		for i in 0 .. vertices {
			polygon[i] = Point{ x: values[at], y: values[at + 1] }; at += 2
			if polygon[i].x < -max_coord || polygon[i].x > max_coord || polygon[i].y < -max_coord || polygon[i].y > max_coord { return -1 }
		}
		if !valid_polygon(&polygon[0], vertices) { return -1 }
		for i in 0 .. queries {
			query_points[i] = Point{ x: values[at], y: values[at + 1] }; at += 2
			if query_points[i].x < -max_coord || query_points[i].x > max_coord || query_points[i].y < -max_coord || query_points[i].y > max_coord { return -1 }
		}
		mut pivot := 0
		for i in 1 .. vertices { if polygon[i].x < polygon[pivot].x || (polygon[i].x == polygon[pivot].x && polygon[i].y < polygon[pivot].y) { pivot = i } }
		for i in 0 .. vertices - 1 { fan[i] = sub(polygon[(pivot + i + 1) % vertices], polygon[pivot]) }
		for i in 0 .. queries { answers[i] = contains_fan(&fan[0], vertices - 1, sub(query_points[i], polygon[pivot])) }
		needed := 8 * queries
		if usize(needed) > capacity || (needed > 0 && output == nil) { return -2 }
		for i in 0 .. queries { put_i64(mut output, 8 * i, answers[i]) }
		return i64(needed)
	}
}
