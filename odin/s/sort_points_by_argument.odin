package sort_points_by_argument

import "core:c"

MAX_N :: 64
INPUT_MAX :: 129
Point :: struct { x, y: i64 }

point_half :: proc(p: Point) -> int {
	if p.y < 0 { return 0 }
	if p.y == 0 && p.x >= 0 { return 1 }
	return 2
}
point_less :: proc(a, b: Point) -> bool {
	ha, hb := point_half(a), point_half(b)
	if ha != hb { return ha < hb }
	cross := a.x*b.y - a.y*b.x
	if cross != 0 { return cross > 0 }
	ra, rb := a.x*a.x+a.y*a.y, b.x*b.x+b.y*b.y
	if ra != rb { return ra < rb }
	if a.x != b.x { return a.x < b.x }
	return a.y < b.y
}
store_le :: proc(output: [^]u8, at: c.size_t, value: i64) {
	bits := u64(value)
	for byte := c.size_t(0); byte < 8; byte += 1 { output[at+byte] = u8((bits >> (8*byte)) & 255) }
}

@(export)
sort_points_by_argument :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > INPUT_MAX { return -1 }
	nr := input[0]
	if nr < 1 || nr > MAX_N || length != c.size_t(1+2*nr) { return -1 }
	n := int(nr)
	points: [MAX_N]Point
	for i := 0; i < n; i += 1 {
		points[i] = Point{input[1+2*i], input[2+2*i]}
		p := points[i]
		if p.x < -1_000_000_000 || p.x > 1_000_000_000 || p.y < -1_000_000_000 || p.y > 1_000_000_000 { return -1 }
	}
	required := c.size_t(16*n)
	if output == nil || capacity < required { return -2 }
	for i := 1; i < n; i += 1 {
		item := points[i]
		j := i
		for j > 0 && point_less(item, points[j-1]) { points[j] = points[j-1]; j -= 1 }
		points[j] = item
	}
	for i := 0; i < n; i += 1 { store_le(output, c.size_t(16*i), points[i].x); store_le(output, c.size_t(16*i+8), points[i].y) }
	return i64(required)
}
