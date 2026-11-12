package common_tangents_two_circles

import "core:c"

MAX_COORDINATE :: i64(100000)
MAX_RADIUS :: i64(100000)

count_tangents :: proc(x1, y1, r1, x2, y2, r2: i64) -> i64 {
	dx := x2 - x1
	dy := y2 - y1
	distance_squared := dx * dx + dy * dy
	signs := [2]i64{-1, 1}
	candidates := i64(0)
	for i := 0; i < 2; i += 1 {
		for j := 0; j < 2; j += 1 {
			difference := signs[j] * r2 - signs[i] * r1
			if distance_squared >= difference * difference do candidates += 1
		}
	}
	if r1 == 0 && r2 == 0 do return 1
	if r1 == 0 || r2 == 0 {
		radius := r1 + r2
		if distance_squared == radius * radius do return 1
		return candidates / 2
	}
	radius_sum := r1 + r2
	radius_difference := r1 - r2
	if distance_squared == radius_sum * radius_sum || distance_squared == radius_difference * radius_difference {
		candidates -= 1
	}
	return candidates
}

@(export)
common_tangents_two_circles :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 6 do return -1
	x1, y1, r1 := input[0], input[1], input[2]
	x2, y2, r2 := input[3], input[4], input[5]
	if x1 < -MAX_COORDINATE || x1 > MAX_COORDINATE ||
		y1 < -MAX_COORDINATE || y1 > MAX_COORDINATE ||
		x2 < -MAX_COORDINATE || x2 > MAX_COORDINATE ||
		y2 < -MAX_COORDINATE || y2 > MAX_COORDINATE ||
		r1 < 0 || r1 > MAX_RADIUS || r2 < 0 || r2 > MAX_RADIUS ||
		(x1 == x2 && y1 == y2) do return -1
	return count_tangents(x1, y1, r1, x2, y2, r2)
}
