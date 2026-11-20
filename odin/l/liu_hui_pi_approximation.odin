package liu_hui_pi_approximation

import "core:c"
import "core:math"

@(export, link_name="liu_hui_pi_approximation")
liu_hui_pi_approximation :: proc(values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 1 do return -1
	doublings := values[0]
	if doublings < 0 || doublings > 16 do return -1

	sides: i64 = 6
	side: f64 = 1.0
	apothem: f64 = math.sqrt_f64(0.75)
	for i: i64 = 0; i < doublings; i += 1 {
		half_side := side / 2.0
		height := 1.0 - apothem
		side = math.sqrt_f64(half_side*half_side + height*height)
		sides *= 2
		next_half_side := side / 2.0
		apothem = math.sqrt_f64(1.0 - next_half_side*next_half_side)
	}

	area := f64(sides) * side * apothem / 2.0
	return i64(area*1_000_000.0 + 0.5)
}

main :: proc() {}
