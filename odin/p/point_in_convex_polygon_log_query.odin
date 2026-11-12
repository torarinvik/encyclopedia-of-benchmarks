package point_in_convex_polygon_log_query

import "core:c"

MAX_VERTICES :: 32
MAX_QUERIES :: 32
MAX_INPUT :: 131
MAX_COORD :: i64(1_000_000)

Point :: struct { x, y: i64 }
sub :: proc(a, b: Point) -> Point { return Point{a.x - b.x, a.y - b.y} }
cross :: proc(a, b: Point) -> i64 { return a.x * b.y - a.y * b.x }
on_segment :: proc(a, b, p: Point) -> bool {
	e, r := sub(b, a), sub(p, a)
	return cross(e, r) == 0 && p.x >= min(a.x, b.x) && p.x <= max(a.x, b.x) && p.y >= min(a.y, b.y) && p.y <= max(a.y, b.y)
}
valid_polygon :: proc(p: [^]Point, n: int) -> bool {
	for i := 0; i < n; i += 1 {
		next := (i + 1) % n
		if p[i].x == p[next].x && p[i].y == p[next].y do return false
		edge := sub(p[next], p[i])
		for j := 0; j < n; j += 1 {
			if j != i && j != next && cross(edge, sub(p[j], p[i])) <= 0 do return false
		}
		for j := i + 1; j < n; j += 1 {
			if p[i].x == p[j].x && p[i].y == p[j].y do return false
		}
	}
	return true
}
contains_fan :: proc(fan: [^]Point, m: int, query: Point) -> i64 {
	origin := Point{0, 0}
	first, last := cross(fan[0], query), cross(fan[m - 1], query)
	if first < 0 || last > 0 do return 0
	if first == 0 do return if on_segment(origin, fan[0], query) then 1 else 0
	if last == 0 do return if on_segment(origin, fan[m - 1], query) then 1 else 0
	lo, hi := 0, m
	for hi - lo > 1 {
		mid := (lo + hi) / 2
		if cross(fan[mid], query) >= 0 do lo = mid else hi = mid
	}
	side := cross(sub(fan[lo + 1], fan[lo]), sub(query, fan[lo]))
	if side < 0 do return 0
	if side == 0 do return if on_segment(fan[lo], fan[lo + 1], query) then 1 else 0
	return 1
}
put_i64 :: proc(out: [^]u8, offset: ^int, value: i64) {
	bits := u64(value)
	for b := 0; b < 8; b += 1 { out[offset^] = u8((bits >> u64(8*b)) & 255); offset^ += 1 }
}

@(export)
point_in_convex_polygon_log_query :: proc "c" (v: [^]i64, n: c.size_t, out: [^]u8, cap: c.size_t) -> i64 {
	if v == nil || n < 2 || n > c.size_t(MAX_INPUT) || v[0] < 3 || v[0] > 32 || v[1] < 0 || v[1] > 32 do return -1
	vertices, queries := int(v[0]), int(v[1])
	if n != c.size_t(2 + 2*vertices + 2*queries) do return -1
	var polygon: [MAX_VERTICES]Point
	var fan: [MAX_VERTICES]Point
	var query_points: [MAX_QUERIES]Point
	var answers: [MAX_QUERIES]i64
	at := 2
	for i := 0; i < vertices; i += 1 {
		polygon[i] = Point{v[at], v[at+1]}; at += 2
		if polygon[i].x < -MAX_COORD || polygon[i].x > MAX_COORD || polygon[i].y < -MAX_COORD || polygon[i].y > MAX_COORD do return -1
	}
	if !valid_polygon(&polygon[0], vertices) do return -1
	for i := 0; i < queries; i += 1 {
		query_points[i] = Point{v[at], v[at+1]}; at += 2
		if query_points[i].x < -MAX_COORD || query_points[i].x > MAX_COORD || query_points[i].y < -MAX_COORD || query_points[i].y > MAX_COORD do return -1
	}
	pivot := 0
	for i := 1; i < vertices; i += 1 {
		if polygon[i].x < polygon[pivot].x || (polygon[i].x == polygon[pivot].x && polygon[i].y < polygon[pivot].y) do pivot = i
	}
	for i := 0; i < vertices-1; i += 1 do fan[i] = sub(polygon[(pivot+i+1)%vertices], polygon[pivot])
	for i := 0; i < queries; i += 1 do answers[i] = contains_fan(&fan[0], vertices-1, sub(query_points[i], polygon[pivot]))
	needed := c.size_t(8 * queries)
	if needed > cap || (needed > 0 && out == nil) do return -2
	offset := 0
	for i := 0; i < queries; i += 1 do put_i64(out, &offset, answers[i])
	return i64(needed)
}
