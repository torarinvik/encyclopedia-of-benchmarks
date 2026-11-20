package pell_fundamental_solution

import "core:c"

@(export)
pell_fundamental_solution :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 1 do return -1
	d := values[0]
	if d < 2 || d > 31 do return -1

	root: i64 = 1
	for (root + 1) * (root + 1) <= d {
		root += 1
	}
	if root * root == d do return -1

	m: i64 = 0
	denominator: i64 = 1
	a := root
	h_two_back: i64 = 0
	h_previous: i64 = 1
	q_two_back: i64 = 1
	q_previous: i64 = 0

	for {
		x := a * h_previous + h_two_back
		y := a * q_previous + q_two_back
		if x * x - d * y * y == 1 do return x * 4_294_967_296 + y

		h_two_back = h_previous
		h_previous = x
		q_two_back = q_previous
		q_previous = y

		m = denominator * a - m
		denominator = (d - m * m) / denominator
		a = (root + m) / denominator
	}
}
