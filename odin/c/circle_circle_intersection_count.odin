package circle_circle_intersection_count

import "core:c"

MAX_COORDINATE :: i64(1000)
MAX_RADIUS :: i64(1000)

classify :: proc(x1, y1, r1, x2, y2, r2: i64) -> i64 {
	dx := x2 - x1
	dy := y2 - y1
	if dx == 0 && dy == 0 {
		if r1 == r2 do return 3
		return 0
	}
	a := -2 * dx
	b := -2 * dy
	c := dx * dx + dy * dy + r1 * r1 - r2 * r2
	discriminant := r1 * r1 * (a * a + b * b) - c * c
	if discriminant < 0 do return 0
	if discriminant == 0 do return 1
	return 2
}

@(export)
circle_circle_intersection_count :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 6 do return -1
	x1, y1, r1 := input[0], input[1], input[2]
	x2, y2, r2 := input[3], input[4], input[5]
	if x1 < -MAX_COORDINATE || x1 > MAX_COORDINATE ||
		y1 < -MAX_COORDINATE || y1 > MAX_COORDINATE ||
		x2 < -MAX_COORDINATE || x2 > MAX_COORDINATE ||
		y2 < -MAX_COORDINATE || y2 > MAX_COORDINATE ||
		r1 < 1 || r1 > MAX_RADIUS || r2 < 1 || r2 > MAX_RADIUS do return -1
	return classify(x1, y1, r1, x2, y2, r2)
}
