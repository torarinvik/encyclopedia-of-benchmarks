package problem85

import "core:math"

MAX_TARGET :: i64(2_000_000_000)

triangle :: proc(side: i64) -> i64 {
	return side * (side + 1) / 2
}

absolute_difference :: proc(left, right: i64) -> i64 {
	difference := left - right
	if difference < 0 do return -difference
	return difference
}

@(export)
problem85 :: proc "c" (target: i64) -> i64 {
	if target < 0 || target > MAX_TARGET do return -1
	bound := i64(math.ceil(math.sqrt(f64(target * 2)) * 1.1))
	best_product: i64 = 0
	area: i64 = 0
	triangle_a: i64 = 0
	for a := i64(1); a < bound; a += 1 {
		triangle_a += a
		estimate := (-1.0 + math.sqrt(1.0 + 8.0 * f64(target) / f64(triangle_a))) / 2.0
		b_floor := i64(math.floor(estimate))
		b_ceil := i64(math.ceil(estimate))
		first_product := triangle_a * triangle(b_floor)
		second_product := triangle_a * triangle(b_ceil)
		if absolute_difference(target, first_product) < absolute_difference(target, best_product) {
			best_product = first_product
			area = a * b_floor
		}
		if absolute_difference(target, second_product) < absolute_difference(target, best_product) {
			best_product = second_product
			area = a * b_ceil
		}
	}
	return area
}
