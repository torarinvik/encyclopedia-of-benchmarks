package convex_polygon_minimax_length_triangulation

import "core:c"

MIN_VERTICES :: 3
MAX_VERTICES :: 12
MAX_PARSEABLE_LENGTH :: 26
COORD_LIMIT :: i64(1000)

Point :: struct { x, y: i64 }

cross :: proc(a, b, c: Point) -> i64 {
	return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}

squared_length :: proc(points: [^]Point, left, right: int) -> i64 {
	dx := points[left].x - points[right].x
	dy := points[left].y - points[right].y
	return dx * dx + dy * dy
}

@(export)
convex_polygon_minimax_length_triangulation :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_PARSEABLE_LENGTH do return -1
	if input[0] < MIN_VERTICES || input[0] > MAX_VERTICES do return -1
	n := int(input[0])
	if length != c.size_t(1 + 2 * n) do return -1
	var points: [MAX_VERTICES]Point
	for i := 0; i < n; i += 1 {
		points[i] = Point{input[1 + 2 * i], input[2 + 2 * i]}
		if points[i].x < -COORD_LIMIT || points[i].x > COORD_LIMIT ||
			points[i].y < -COORD_LIMIT || points[i].y > COORD_LIMIT do return -1
	}
	area2: i64 = 0
	for i := 0; i < n; i += 1 {
		next := (i + 1) % n
		area2 += points[i].x * points[next].y - points[i].y * points[next].x
	}
	if area2 == 0 do return -1
	orientation := if area2 > 0 then i64(1) else i64(-1)
	for edge := 0; edge < n; edge += 1 {
		next := (edge + 1) % n
		for vertex := 0; vertex < n; vertex += 1 {
			if vertex != edge && vertex != next && orientation * cross(points[edge], points[next], points[vertex]) <= 0 do return -1
		}
	}

	var best: [MAX_VERTICES * MAX_VERTICES]i64
	for left := 0; left < n - 1; left += 1 {
		best[left * MAX_VERTICES + left + 1] = squared_length(&points[0], left, left + 1)
	}
	for span := 2; span < n; span += 1 {
		for left := 0; left + span < n; left += 1 {
			right := left + span
			boundary := squared_length(&points[0], left, right)
			optimum: i64 = 8_000_001
			for middle := left + 1; middle < right; middle += 1 {
				candidate := best[left * MAX_VERTICES + middle]
				if best[middle * MAX_VERTICES + right] > candidate do candidate = best[middle * MAX_VERTICES + right]
				if boundary > candidate do candidate = boundary
				if candidate < optimum do optimum = candidate
			}
			best[left * MAX_VERTICES + right] = optimum
		}
	}
	return best[n - 1]
}
