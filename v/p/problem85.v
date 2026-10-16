module problem85

import math

const max_target = i64(2_000_000_000)

fn triangle(side i64) i64 {
	return side * (side + 1) / 2
}

fn absolute_difference(left i64, right i64) i64 {
	difference := left - right
	return if difference < 0 { -difference } else { difference }
}

@[export: 'problem85']
pub fn problem85(target i64) i64 {
	if target < 0 || target > max_target {
		return -1
	}
	bound := i64(math.ceil(math.sqrt(f64(target * 2)) * 1.1))
	mut best_product := i64(0)
	mut area := i64(0)
	mut triangle_a := i64(0)
	mut a := i64(1)
	for a < bound {
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
		a++
	}
	return area
}
