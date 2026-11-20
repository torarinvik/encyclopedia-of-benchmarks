module liu_hui_pi_approximation

import math

@[export: 'liu_hui_pi_approximation']
pub fn liu_hui_pi_approximation(values &i64, length usize) i64 {
	if unsafe { values == nil } || length != 1 { return -1 }
	unsafe {
		doublings := values[0]
	return liu_hui_pi_approximation_impl(doublings)
	}
}

fn liu_hui_pi_approximation_impl(doublings i64) i64 {
	if doublings < 0 || doublings > 16 { return -1 }
	mut sides := i64(6)
	mut side := 1.0
	mut apothem := math.sqrt(0.75)
	for _ in 0 .. doublings {
		half_side := side / 2.0
		height := 1.0 - apothem
		side = math.sqrt(half_side * half_side + height * height)
		sides *= 2
		next_half_side := side / 2.0
		apothem = math.sqrt(1.0 - next_half_side * next_half_side)
	}
	area := f64(sides) * side * apothem / 2.0
	return i64(area * 1_000_000.0 + 0.5)
}
