package external_point_tangents_convex_polygon

import "core:c"

MAX_VERTICES :: 32
MAX_QUERIES :: 16
MAX_INPUT :: 99
MAX_COORDINATE :: i64(1000)

Point :: struct { x, y: i64 }
sub :: proc(a, b: Point) -> Point { return Point{a.x - b.x, a.y - b.y} }
cross :: proc(a, b: Point) -> i64 { return a.x * b.y - a.y * b.x }

valid_polygon :: proc(p: [^]Point, n: int) -> bool {
	for i := 0; i < n; i += 1 {
		next := (i + 1) % n
		if p[i].x == p[next].x && p[i].y == p[next].y do return false
		edge := sub(p[next], p[i])
		for j := 0; j < n; j += 1 {
			if j != i && j != next && cross(edge, sub(p[j], p[i])) <= 0 do return false
		}
	}
	return true
}
valid_query :: proc(p: [^]Point, n: int, q: Point) -> bool {
	outside := false
	for i := 0; i < n; i += 1 {
		side := cross(sub(p[(i + 1) % n], p[i]), sub(q, p[i]))
		if side == 0 do return false
		if side < 0 do outside = true
	}
	return outside
}
build_chain :: proc(chain: [^]int, n, start, stop: int) -> int {
	length := 0
	at := start
	for {
		chain[length] = at
		length += 1
		if at == stop do return length
		at = (at + 1) % n
		if length > n do return 0
	}
}
build_layers :: proc(p: [^]Point, n: int, lower, upper: [^]int) -> (int, int, bool) {
	min_x, max_x := 0, 0
	for i := 1; i < n; i += 1 {
		if p[i].x < p[min_x].x do min_x = i
		if p[i].x > p[max_x].x do max_x = i
	}
	left_bottom, left_top := min_x, min_x
	right_bottom, right_top := max_x, max_x
	for i := 0; i < n; i += 1 {
		if p[i].x == p[min_x].x {
			if p[i].y < p[left_bottom].y do left_bottom = i
			if p[i].y > p[left_top].y do left_top = i
		}
		if p[i].x == p[max_x].x {
			if p[i].y < p[right_bottom].y do right_bottom = i
			if p[i].y > p[right_top].y do right_top = i
		}
	}
	lower_len := build_chain(lower, n, left_bottom, right_bottom)
	upper_len := build_chain(upper, n, right_top, left_top)
	return lower_len, upper_len, lower_len != 0 && upper_len != 0
}
split_ascending :: proc(p: [^]Point, chain: [^]int, length: int, qx: i64) -> int {
	lo, hi := 0, length
	for lo < hi {
		mid := lo + (hi - lo) / 2
		if p[chain[mid]].x < qx do lo = mid + 1 else hi = mid
	}
	return if lo == 0 then 0 else lo - 1
}
split_descending :: proc(p: [^]Point, chain: [^]int, length: int, qx: i64) -> int {
	lo, hi := 0, length
	for lo < hi {
		mid := lo + (hi - lo) / 2
		if p[chain[mid]].x > qx do lo = mid + 1 else hi = mid
	}
	return if lo == 0 then 0 else lo - 1
}
tangent_search :: proc(p: [^]Point, n: int, chain: [^]int, first, last: int, q: Point, sign: i64) -> int {
	lo, hi := first, last
	result := lo
	for lo <= hi {
		mid := lo + (hi - lo) / 2
		index := chain[mid]
		here := sub(p[index], q)
		to_next := sign * cross(here, sub(p[(index + 1) % n], q))
		to_prev := sign * cross(here, sub(p[(index + n - 1) % n], q))
		if to_next >= 0 && to_prev >= 0 do return mid
		if to_next >= 0 { result = mid; hi = mid - 1 } else { lo = mid + 1 }
	}
	return result
}
supports :: proc(p: [^]Point, n, index: int, q: Point, sign: i64) -> bool {
	here := sub(p[index], q)
	return sign * cross(here, sub(p[(index + n - 1) % n], q)) > 0 &&
		sign * cross(here, sub(p[(index + 1) % n], q)) > 0
}
find_tangents :: proc(p: [^]Point, n: int, lower: [^]int, lower_len: int,
		upper: [^]int, upper_len: int, q: Point) -> (int, int, bool) {
	lower_split := split_ascending(p, lower, lower_len, q.x)
	upper_split := split_descending(p, upper, upper_len, q.x)
	left_a := lower[tangent_search(p, n, lower, 0, lower_split, q, -1)]
	left_b := upper[tangent_search(p, n, upper, 0, upper_split, q, -1)]
	right_a := lower[tangent_search(p, n, lower, lower_split, lower_len - 1, q, 1)]
	right_b := upper[tangent_search(p, n, upper, upper_split, upper_len - 1, q, 1)]
	left := -1
	right := -1
	if supports(p, n, left_a, q, -1) do left = left_a else if supports(p, n, left_b, q, -1) do left = left_b
	if supports(p, n, right_a, q, 1) do right = right_a else if supports(p, n, right_b, q, 1) do right = right_b
	if left < 0 || right < 0 || left == right do return -1, -1, false
	if left < right do return left, right, true
	return right, left, true
}
put_i64 :: proc(out: [^]u8, offset: ^int, value: i64) {
	bits := u64(value)
	for b := 0; b < 8; b += 1 { out[offset^] = u8((bits >> u64(8*b)) & 255); offset^ += 1 }
}

@(export)
external_point_tangents_convex_polygon :: proc "c" (v: [^]i64, n: c.size_t, out: [^]u8, cap: c.size_t) -> i64 {
	if v == nil || n < 2 || n > c.size_t(MAX_INPUT) || v[0] < 3 || v[0] > MAX_VERTICES ||
		v[1] < 0 || v[1] > MAX_QUERIES do return -1
	vertices, queries := int(v[0]), int(v[1])
	if n != c.size_t(2 + 2*vertices + 2*queries) do return -1
	var polygon: [MAX_VERTICES]Point
	var query_points: [MAX_QUERIES]Point
	var answers: [2*MAX_QUERIES]i64
	at := 2
	for i := 0; i < vertices; i += 1 {
		polygon[i] = Point{v[at], v[at+1]}; at += 2
		if polygon[i].x < -MAX_COORDINATE || polygon[i].x > MAX_COORDINATE ||
			polygon[i].y < -MAX_COORDINATE || polygon[i].y > MAX_COORDINATE do return -1
	}
	if !valid_polygon(&polygon[0], vertices) do return -1
	var lower: [MAX_VERTICES]int
	var upper: [MAX_VERTICES]int
	lower_len, upper_len, layers_ok := build_layers(&polygon[0], vertices, &lower[0], &upper[0])
	if !layers_ok do return -1
	for i := 0; i < queries; i += 1 {
		query_points[i] = Point{v[at], v[at+1]}; at += 2
		if query_points[i].x < -MAX_COORDINATE || query_points[i].x > MAX_COORDINATE ||
			query_points[i].y < -MAX_COORDINATE || query_points[i].y > MAX_COORDINATE ||
			!valid_query(&polygon[0], vertices, query_points[i]) do return -1
		first, second, ok := find_tangents(&polygon[0], vertices, &lower[0], lower_len,
			&upper[0], upper_len, query_points[i])
		if !ok do return -1
		answers[2*i], answers[2*i+1] = i64(first), i64(second)
	}
	needed := c.size_t(16 * queries)
	if needed > cap || out == nil do return -2
	offset := 0
	for i := 0; i < 2*queries; i += 1 do put_i64(out, &offset, answers[i])
	return i64(needed)
}
