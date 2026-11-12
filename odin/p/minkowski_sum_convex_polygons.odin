package minkowski_sum_convex_polygons

import "core:c"

MAX_VERTICES :: 32
MAX_INPUT :: 131
MAX_COORD :: i64(1_000_000)

Point :: struct { x, y: i64 }

cross :: proc(a, b: Point) -> i64 { return a.x * b.y - a.y * b.x }
edge :: proc(p: [^]Point, n, i: int) -> Point {
	next := p[(i + 1) % n]
	return Point{next.x - p[i].x, next.y - p[i].y}
}
half :: proc(v: Point) -> int {
	if v.y > 0 || (v.y == 0 && v.x >= 0) do return 0
	return 1
}
angle_compare :: proc(a, b: Point) -> int {
	ha, hb := half(a), half(b)
	if ha != hb do return if ha < hb then -1 else 1
	turn := cross(a, b)
	if turn > 0 do return -1
	if turn < 0 do return 1
	return 0
}
valid_polygon :: proc(p: [^]Point, n: int) -> bool {
	wraps := 0
	for i := 0; i < n; i += 1 {
		a, b := edge(p, n, i), edge(p, n, (i + 1) % n)
		if (a.x == 0 && a.y == 0) || cross(a, b) <= 0 do return false
		if angle_compare(b, a) < 0 do wraps += 1
	}
	return wraps == 1
}
rotate_lowest :: proc(p: [^]Point, n: int) {
	first := 0
	for i := 1; i < n; i += 1 {
		if p[i].y < p[first].y || (p[i].y == p[first].y && p[i].x < p[first].x) do first = i
	}
	tmp: [MAX_VERTICES]Point
	for i := 0; i < n; i += 1 do tmp[i] = p[(first + i) % n]
	for i := 0; i < n; i += 1 do p[i] = tmp[i]
}
put_i64 :: proc(out: [^]u8, offset: ^int, value: i64) {
	bits := u64(value)
	for b := 0; b < 8; b += 1 { out[offset^] = u8((bits >> u64(8*b)) & 255); offset^ += 1 }
}

@(export)
minkowski_sum_convex_polygons :: proc "c" (v: [^]i64, n: c.size_t,
	out: [^]u8, cap: c.size_t) -> i64 {
	if v == nil || n < 14 || n > c.size_t(MAX_INPUT) || v[0] < 3 || v[0] > i64(MAX_VERTICES) || v[1] < 3 || v[1] > i64(MAX_VERTICES) do return -1
	pn, qn := int(v[0]), int(v[1])
	if n != c.size_t(2 + 2*pn + 2*qn) do return -1
	var p, q: [MAX_VERTICES]Point
	var sums: [2*MAX_VERTICES]Point
	at := 2
	for i := 0; i < pn; i += 1 {
		p[i] = Point{v[at], v[at + 1]}; at += 2
		if p[i].x < -MAX_COORD || p[i].x > MAX_COORD || p[i].y < -MAX_COORD || p[i].y > MAX_COORD do return -1
	}
	for i := 0; i < qn; i += 1 {
		q[i] = Point{v[at], v[at + 1]}; at += 2
		if q[i].x < -MAX_COORD || q[i].x > MAX_COORD || q[i].y < -MAX_COORD || q[i].y > MAX_COORD do return -1
	}
	if !valid_polygon(&p[0], pn) || !valid_polygon(&q[0], qn) do return -1
	rotate_lowest(&p[0], pn); rotate_lowest(&q[0], qn)
	i, j, count := 0, 0, 0
	for i < pn || j < qn {
		sums[count] = Point{p[i % pn].x + q[j % qn].x, p[i % pn].y + q[j % qn].y}; count += 1
		if i == pn { j += 1; continue }
		if j == qn { i += 1; continue }
		order := angle_compare(edge(&p[0], pn, i), edge(&q[0], qn, j))
		if order <= 0 { i += 1 }
		if order >= 0 { j += 1 }
	}
	needed := c.size_t((1 + 2*count) * 8)
	if needed > cap || out == nil do return -2
	offset := 0
	put_i64(out, &offset, i64(count))
	for k := 0; k < count; k += 1 { put_i64(out, &offset, sums[k].x); put_i64(out, &offset, sums[k].y) }
	return i64(needed)
}
