package bisection_method

import "core:c"

MAX_COORD_MILLI :: i64(100000)
MAX_TOLERANCE_MICRO :: i64(1000000)
ROOT_SCALE :: f64(1000000.0)
MAX_ITERATIONS :: i64(64)

evaluate :: proc(equation: i64, x: f64) -> f64 {
	if equation == 0 do return x*x*x + 2.0*x - 10.0
	return x*x*x - 4.0*x - 9.0
}

@(export)
bisection_method :: proc "contextless" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 4 do return -1
	equation := input[0]
	left_milli := input[1]
	right_milli := input[2]
	tolerance_micro := input[3]
	if equation < 0 || equation > 1 || left_milli < -MAX_COORD_MILLI || left_milli > MAX_COORD_MILLI ||
		right_milli < -MAX_COORD_MILLI || right_milli > MAX_COORD_MILLI || left_milli >= right_milli ||
		tolerance_micro < 1 || tolerance_micro > MAX_TOLERANCE_MICRO do return -1
	left := f64(left_milli) / 1000.0
	right := f64(right_milli) / 1000.0
	f_left := evaluate(equation, left)
	f_right := evaluate(equation, right)
	if f_left == 0 do return i64(left*ROOT_SCALE + 0.5)
	if f_right == 0 do return i64(right*ROOT_SCALE + 0.5)
	if (f_left < 0) == (f_right < 0) do return -2
	tolerance := f64(tolerance_micro) / ROOT_SCALE
	for iteration := i64(0); iteration < MAX_ITERATIONS; iteration += 1 {
		middle := left + (right-left)*0.5
		f_middle := evaluate(equation, middle)
		if f_middle == 0 do return i64(middle*ROOT_SCALE + 0.5)
		if (f_left < 0) != (f_middle < 0) {
			right = middle
		} else {
			left = middle
			f_left = f_middle
		}
		if right-left <= tolerance do return i64((left+(right-left)*0.5)*ROOT_SCALE + 0.5)
	}
	return -2
}
